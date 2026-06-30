---
name: reusable-ai-architecture
description: >-
  Arquitectura reutilizable para construir varios casos de uso sobre la MISMA base
  audio→STT→LLM→borrador→revisión humana→exportación. Úsala al diseñar un caso de uso nuevo,
  extraer código compartido, decidir qué es "plataforma" vs "producto", definir contratos
  FE↔BE, hacer el pipeline dirigido por esquema, o montar el monorepo de paquetes. Cubre
  backend FastAPI (provider abstraction, schema-driven pipeline, exporters) y frontend Flutter
  (paquetes compartidos, review kit genérico). Aplica el cumplimiento del repo (UE, humano en
  el bucle, minimización de audio).
---

# Arquitectura reutilizable: una base, muchos casos de uso

El proyecto nace como **Escriba Clínico IA**, pero el equipo prevé **varios casos de uso que
comparten la misma base**: capturar audio, transcribirlo, estructurarlo con un LLM, dejar que
un humano lo revise y exportarlo a un sistema destino. Esta skill define cómo construir esa
base **una vez** y crear cada caso nuevo como una **configuración**, no como un fork.

> Ejemplos de casos de uso futuros sobre la misma base: nota clínica (actual), resumen de
> reunión/acta, informe de inspección de campo, parte de incidencia, minuta legal, etc.
> Todos son: audio → texto → estructura → revisión → exportar.

---

## 1. El principio: Plataforma vs. Producto

Separa lo **invariante** (plataforma) de lo **específico del caso** (producto).

```
                 ┌──────────────────────────────────────────────┐
   PLATAFORMA    │  Captura audio · STT · descarte audio · LLM   │   <- se escribe UNA vez
   (invariante)  │  máquina de estados · revisión humana · audit │
                 └───────────────────┬──────────────────────────┘
                                     │ configurada por
                 ┌───────────────────▼──────────────────────────┐
   PRODUCTO      │  OutputSchema  ·  PromptTemplate              │   <- una def. por caso
   (por caso)    │  ReviewRenderer ·  Exporter (FHIR/otros)      │
                 └──────────────────────────────────────────────┘
```

Un **caso de uso** = 4 piezas enchufables:

| Pieza | Qué define | Backend | Frontend |
|-------|-----------|---------|----------|
| **OutputSchema** | Las secciones/campos del borrador | modelo Pydantic | modelo freezed |
| **PromptTemplate** | Cómo el LLM rellena ese esquema | string/plantilla | — |
| **ReviewRenderer** | Cómo se muestra/edita el borrador | — | widget dirigido por esquema |
| **Exporter** | A qué sistema y formato se vuelca | interfaz `Exporter` | — |

Todo lo demás (grabar, subir, transcribir, borrar audio, orquestar, auditar, validar) es
**plataforma compartida** y no se duplica por caso.

---

## 2. Backend: generalizar el pipeline (de 1 caso a N)

Hoy `pipeline/orchestrator.py` está acoplado al dominio clínico (`structure_note`,
`ClinicalNote`). El patrón de proveedores (`STTProvider`/`LLMProvider`) ya está bien resuelto:
**replica esa misma idea para el dominio del caso de uso.**

### 2.1 Estado objetivo

```
backend/app/
  services/stt/        STTProvider           (compartido, ya existe)
  services/llm/        LLMProvider           (compartido, ya existe)
  pipeline/            orquestación genérica  (refactor: sin tipos clínicos)
  usecases/            <-- NUEVO: un paquete por caso de uso
    base.py            UseCase (contrato), registry
    clinical_note/     schema + prompt + exporter (el caso actual)
    meeting_minutes/   schema + prompt + exporter (ejemplo futuro)
  exporters/           Exporter (FHIR, genérico...) detrás de interfaz
```

### 2.2 El contrato `UseCase`

```python
# usecases/base.py
from abc import ABC, abstractmethod
from typing import Type
from pydantic import BaseModel

class UseCase(ABC):
    """Un caso de uso = esquema de salida + prompt + exportador. La plataforma lo orquesta."""
    key: str                       # "clinical_note", "meeting_minutes", ...

    @property
    @abstractmethod
    def output_model(self) -> Type[BaseModel]: ...   # p.ej. ClinicalNote

    @abstractmethod
    def build_prompt(self, transcript_text: str, variant: str = "general") -> str: ...

    @abstractmethod
    def exporter(self) -> "Exporter": ...            # p.ej. FhirExporter

_REGISTRY: dict[str, UseCase] = {}
def register(uc: UseCase) -> None: _REGISTRY[uc.key] = uc
def get_use_case(key: str) -> UseCase: return _REGISTRY[key]
```

### 2.3 Pipeline genérico (dirigido por esquema)

```python
# pipeline/orchestrator.py  (refactor: ya no conoce "nota clínica")
async def run_pipeline(consultation_id, audio_bytes, use_case_key, variant="general"):
    uc  = get_use_case(use_case_key)
    stt = get_stt_provider()
    llm = get_llm_provider()

    transcript = await stt.transcribe(audio_bytes, language="es")
    del audio_bytes                                   # minimización RGPD (invariante)

    # El LLM devuelve JSON validado contra el esquema del caso de uso:
    draft = await llm.structure(transcript, schema=uc.output_model, prompt=uc.build_prompt(transcript.full_text, variant))
    return ConsultationResult(consultation_id=consultation_id,
                              status=ConsultationStatus.awaiting_review,
                              transcript=transcript, draft=draft)
```

Clave: `LLMProvider.structure()` se generaliza para aceptar **cualquier** modelo Pydantic como
esquema de salida (salida estructurada JSON), en vez de `structure_note()` fijo. Así un caso
nuevo no toca el pipeline. (Hoy el LLM es un stub; al implementarlo, usa *structured output* /
JSON mode del proveedor con el `model_json_schema()` del esquema.)

### 2.4 Anti-alucinación como invariante de plataforma

El flag `needs_confirmation` por sección y la instrucción "no inventes datos no mencionados"
viven en la **plataforma** (no se re-implementan por caso). Cada `build_prompt` los hereda de
una base común. Regla de cumplimiento, no opcional (`../../CLAUDE.md` §7).

---

## 3. Frontend: monorepo de paquetes compartidos

Hoy todo vive en `frontend/lib/` plano. Para reutilizar entre casos sin copiar/pegar, evoluciona
a **paquetes locales** (workspace de Dart/Flutter). La app concreta solo cablea piezas.

```
frontend/
  pubspec.yaml                # workspace (resolution: workspace, Dart 3.6+)
  app/                        # la app que se compila y despliega
    lib/ … main.dart, router, wiring de casos de uso
  packages/
    ai_capture_core/          # grabación, consentimiento, subida, máquina de estados
    ai_review_kit/            # UI de revisión GENÉRICA dirigida por esquema
    design_system/            # tokens, theme, componentes (ver flutter-ui-ux)
    usecase_clinical_note/    # schema freezed + render + textos del caso actual
    usecase_meeting_minutes/  # (ejemplo futuro)
```

- **`ai_capture_core`**: `ConsultationRecorder` (ya), estado `capturing→processing→review→done`,
  cliente de subida. No sabe de clínica.
- **`ai_review_kit`**: toma una descripción de secciones (`[{key,label,multiline,needsConfirmation}]`)
  y renderiza el formulario de revisión + el badge "asistido por IA" + el botón validar. **Un
  caso nuevo no escribe una pantalla nueva**: aporta su descripción de secciones.
- **`design_system`**: fuente única de estilo (tokens, Material 3, componentes adaptativos).

```dart
// ai_review_kit: la pantalla de revisión es genérica
class ReviewScreen extends StatelessWidget {
  final ReviewSchema schema;        // secciones del caso de uso
  final DraftModel draft;           // datos rellenados por el LLM
  final Future<void> Function(DraftModel) onValidate;
  // render uniforme + badge IA + edición + validación humana obligatoria
}
```

> El caso clínico actual (`review_screen.dart`, `clinical_note.dart`) se convierte en la
> **primera instancia** de este kit, no en código a medida.

---

## 4. Contrato FE↔BE: una sola verdad

El esquema de salida se define en backend (Pydantic) y se **espeja** en frontend (freezed).
Para que nunca se desincronicen:

- Nombres de campo idénticos (`needs_confirmation` ↔ `@JsonKey(name:'needs_confirmation')`).
- El endpoint declara el `use_case_key`; el FE conoce el `ReviewSchema` del mismo caso.
- Recomendado a futuro: exportar `model_json_schema()` del backend y generar/validar los
  modelos Dart, o compartir un contrato OpenAPI (ver roadmap de `../../CLAUDE.md`).

API generalizada (mínimo cambio sobre la actual):

```
POST /consultations         form: audio, use_case (default "clinical_note"), variant
POST /consultations/{id}/validate   body: <draft del caso>, query: target_id
```

---

## 5. Qué es invariante (NO duplicar por caso)

- Captura de audio + consentimiento + **descarte de audio** tras transcribir.
- Selección de STT/LLM por configuración (provider abstraction).
- Máquina de estados de la consulta y manejo de errores.
- Revisión humana obligatoria + badge "asistido por IA" + diff borrador↔validado + auditoría.
- Residencia UE y ausencia de PHI en logs/URLs.

## 6. Qué cambia por caso (las 4 piezas)

- `OutputSchema` (Pydantic + freezed).
- `PromptTemplate` (hereda anti-alucinación de la base).
- `ReviewRenderer` (descripción de secciones para `ai_review_kit`).
- `Exporter` (FHIR para clínica; otro destino para otros casos).

---

## 7. Cómo añadir un caso de uso (resumen — ver `/new-use-case`)

1. Backend: crea `usecases/<caso>/` con `output_model`, `build_prompt`, `exporter`; `register()`.
2. Frontend: crea `packages/usecase_<caso>/` con el modelo freezed + `ReviewSchema` + textos.
3. Cablea el `use_case_key` en el router/selección de la app.
4. Tests: pipeline con STT/LLM mockeados + widget de revisión del caso.
5. Cumplimiento: confirma destino de exportación, residencia UE del proveedor y DPA.

## 8. Errores a evitar

- ❌ Forkear la app o el pipeline por cada caso. ✔️ Configurar las 4 piezas.
- ❌ Meter lógica de un caso en la plataforma compartida. ✔️ Mantener el núcleo agnóstico.
- ❌ Acoplar el pipeline a un proveedor o a un esquema concreto. ✔️ Interfaces + registry.
- ❌ Reescribir la pantalla de revisión por caso. ✔️ `ai_review_kit` dirigido por esquema.
- ❌ Saltarse la revisión humana o persistir audio "para este caso". ✔️ Invariantes de §5.
