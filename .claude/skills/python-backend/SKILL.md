---
name: python-backend
description: >-
  Patrones de backend Python para el API de Escriba Clínico IA. Úsala al tocar el backend:
  FastAPI, Pydantic v2, async/await, rutas, el pipeline de orquestación, los servicios STT/LLM,
  persistencia, jobs en background, auditoría, seguridad OIDC o tests. Cubre la abstracción de
  proveedores (STTProvider/LLMProvider), salida estructurada del LLM con esquemas Pydantic,
  manejo de errores, configuración por entorno y testing con pytest. Aplica el cumplimiento del
  repo (UE, humano en el bucle, minimización de audio, sin PHI en logs).
---

# Backend Python — FastAPI, Pydantic v2, async

Guía para trabajar el backend (`backend/app/`) con calidad y respetando el contrato del repo.
El estilo ya está fijado en `../../CLAUDE.md` §6: tipado estático siempre, Pydantic v2,
`async`/`await` para I/O, **nada de lógica de negocio en las rutas**, y **nunca** acoplar el
pipeline a un proveedor concreto.

> Python 3.12 · FastAPI · Pydantic v2 · async. Estructura: `api/routes` · `core` · `pipeline`
> · `services/{stt,llm,fhir}` · `models`.

---

## 1. Capas y responsabilidades

| Capa | Hace | NO hace |
|------|------|---------|
| `api/routes/` | Validar entrada, auth, traducir a/desde el dominio, códigos HTTP | Lógica de negocio, llamar proveedores directamente |
| `core/` | Seguridad (OIDC/JWT), auditoría transversal | Conocer casos de uso concretos |
| `pipeline/` | Orquestar el flujo audio→STT→LLM→borrador | Importar implementaciones concretas de proveedor |
| `services/` | Integraciones externas detrás de interfaz | Saber quién las llama |
| `models/` | Esquemas Pydantic del dominio | I/O |

Regla: una ruta llama al pipeline/servicio; el pipeline llama a `get_stt_provider()` /
`get_llm_provider()`. Nunca al revés, nunca un import concreto en el pipeline.

---

## 2. Abstracción de proveedores (el patrón clave)

Ya implementado para STT/LLM. **Replícalo para cualquier integración externa nueva**
(otro STT, otro LLM, un exportador, un cliente FHIR del HIS).

```python
# Añadir un proveedor:
# 1) clase que implementa la interfaz (STTProvider / LLMProvider)
# 2) registrarla en services/<x>/__init__.py mapeada por su nombre de config
# 3) seleccionarla por .env (STT_PROVIDER / LLM_PROVIDER) — sin tocar orchestrator.py
def get_llm_provider() -> LLMProvider:
    return {"mistral": MistralLLM, "azure_eu": AzureOpenAIEuLLM}[settings.LLM_PROVIDER]()
```

Cumplimiento al elegir proveedor (`../../CLAUDE.md` §7.4): preferir proveedores **UE**
(Mistral, Speechmatics, OVHcloud/Scaleway); verificar región y DPA antes de procesar datos
reales; evitar matriz estadounidense (CLOUD Act) salvo decisión explícita del equipo.

---

## 3. Salida estructurada del LLM (esquema-dirigida)

Para soportar varios casos de uso (ver skill `reusable-ai-architecture`), generaliza el LLM de
`structure_note()` a un `structure()` que acepte **cualquier** modelo Pydantic como esquema:

```python
class LLMProvider(ABC):
    @abstractmethod
    async def structure(self, transcript: Transcript, *, schema: type[BaseModel], prompt: str) -> BaseModel:
        """Devuelve una instancia validada de `schema`. Usa JSON mode / structured output."""
```

Al implementar el proveedor real:
- Pasa `schema.model_json_schema()` al *structured output* del proveedor (JSON mode).
- **Valida** la respuesta con `schema.model_validate(...)`; si no valida, reintenta o marca error.
- **Anti-alucinación** (§7.7): la plantilla de prompt prohíbe inventar datos no mencionados y
  marca lo dudoso con `needs_confirmation=True`. Esta instrucción es de plataforma, no opcional.

---

## 4. Pydantic v2 — buenas prácticas

- `from __future__ import annotations` + tipos modernos (`list[...]`, `X | None`).
- Validación de entrada y salida; nada de dicts crudos cruzando capas.
- `pydantic-settings` para config (ya en `config.py`); **secretos solo por entorno**, nunca en
  el repo.
- Evita `datetime.utcnow()` (deprecado): usa `datetime.now(tz=UTC)` en código nuevo.
- Modelos de dominio (`ClinicalNote`, `Transcript`) separados de DTOs de transporte si divergen.

---

## 5. Async, jobs y timeouts

El pipeline (STT + LLM) puede tardar **minutos**. Opciones según madurez:

- **MVP simple**: endpoint `async` que ejecuta el pipeline y responde (con `receiveTimeout`
  amplio en el cliente). Aceptable para el piloto.
- **Robusto**: encolar con **Celery + Redis** (ya previsto en `requirements.txt` comentado),
  devolver `consultation_id` y exponer estado (`capturing→transcribing→structuring→
  awaiting_review`) por polling o WebSocket. Esto encaja con la máquina de estados ya definida.
- Usa `httpx.AsyncClient` para llamadas salientes; define timeouts explícitos; maneja
  cancelación.

---

## 6. Manejo de errores

- Lanza `HTTPException` con el código correcto; **no expongas trazas internas** (§6).
- Errores de proveedor (STT/LLM caído, timeout) → 502/504 con mensaje neutro; loguea el detalle
  técnico **sin PHI**.
- Un `exception_handler` global homogeneiza el formato de error del API.

---

## 7. Seguridad y auditoría

- **OIDC/JWT**: dependencia de FastAPI que valida el token (`Authorization: Bearer`) y extrae
  claims (`sub`, rol médico, `practitioner_id`). Las rutas protegidas la declaran como `Depends`.
- **Auditoría append-only** (`core/audit.py`): registra quién/qué/cuándo y el **diff
  borrador↔validado** al validar. Inmutable (§7.6).
- **Sin PHI en logs/URLs**: nada de datos clínicos en query params, logs en texto plano ni
  servicios de terceros fuera de la UE. Pseudonimiza cuando puedas (§7.8).
- **Minimización de audio**: el `del audio_bytes` tras transcribir no se quita. No persistir
  audio por defecto (§7.3).

---

## 8. Persistencia (cuando se implemente)

Diseño propuesto en `docs/04-arquitectura.md` §7: `consultations`, `clinical_notes` (versionado,
`note_json` JSONB), `audit_events` (append-only). Stack: SQLAlchemy 2.0 async + asyncpg +
PostgreSQL **en región UE**. Migraciones con Alembic. El diff IA↔validado se calcula al validar
y se guarda en `audit_events.detail`.

---

## 9. Testing (pytest)

```bash
cd backend
source .venv/bin/activate
pip install -r requirements.txt
pytest                       # añadir pytest, pytest-asyncio, httpx al requirements de dev
uvicorn app.main:app --reload
```

Qué probar y cómo:
- **Pipeline** con STT/LLM **mockeados** (proveedores fake que devuelven `Transcript`/modelo de
  salida fijo): verifica orquestación, descarte de audio y estado resultante.
- **Rutas** con `httpx.AsyncClient` + `ASGITransport`: contrato del API, auth, códigos de error.
- **Modelos** Pydantic: validación, serialización, alineación de nombres con el frontend.
- Inyecta proveedores fake vía la config/registry (no parchees imports concretos).
- Cobre el caso anti-alucinación: salida con `needs_confirmation` cuando el dato es dudoso.

---

## 10. Checklist al tocar el backend

- [ ] ¿La ruta solo orquesta y valida, sin lógica de negocio?
- [ ] ¿El pipeline usa interfaces (`get_*_provider`), nunca un proveedor concreto?
- [ ] ¿Tipado completo y modelos Pydantic v2 en entradas/salidas?
- [ ] ¿`async`/`await` y timeouts en todo el I/O? ¿Jobs si la tarea es larga?
- [ ] ¿Errores sin trazas internas ni PHI? ¿Auditoría registrada?
- [ ] ¿Proveedor elegido es UE y con DPA verificado? ¿Secretos solo por entorno?
- [ ] ¿`del audio_bytes` intacto? ¿Sin persistir audio por defecto?
- [ ] ¿Tests de pipeline (mock STT/LLM) y de rutas en verde?
