# CLAUDE.md

Contexto y convenciones del proyecto para asistentes de IA (Claude Code) y para el equipo.
Este archivo vive en la raíz del repositorio. Léelo antes de trabajar en el código.

---

## 1. Qué es este proyecto

**Escriba Clínico IA**: un agente que escucha la conversación entre médico y paciente,
genera un **borrador** de historia clínica estructurada y lo integra con el sistema
(HIS/EHR) del hospital. El médico siempre revisa y valida antes de guardar.

Frontend en **Flutter** (multiplataforma). Backend en **Python + FastAPI**. Todo el
procesamiento de datos de salud ocurre **dentro de la jurisdicción de la UE**.

---

## 2. Alcance (scope)

### Dentro del alcance
- Captura de audio de la consulta (con consentimiento del paciente).
- Transcripción con diarización (distinguir médico de paciente).
- Estructuración del borrador en: motivo de consulta, anamnesis, exploración, diagnóstico, plan.
- Pantalla de revisión y edición para el médico.
- Validación y volcado de la nota al HIS vía HL7 FHIR.
- Registro de auditoría y trazabilidad.

### Fuera del alcance (NO implementar sin decisión explícita del equipo)
- **Cualquier función de decisión clínica** (diagnóstico autónomo, recomendación de
  tratamiento, alertas de dosis). Esto cambiaría la clasificación regulatoria del
  producto de Clase I a Clase IIa (alto riesgo bajo el Reglamento de IA). Ver §7.
- Almacenamiento persistente de audio por defecto.
- Procesamiento de datos de pacientes fuera de la UE.
- Análisis de sentimiento de feedback de pacientes (es otro producto, no este).

---

## 3. Arquitectura

```
Flutter (cliente)  ->  FastAPI (backend / orquestación)
                          |-- STT  (Speechmatics)   [intercambiable vía STTProvider]
                          |-- LLM  (Mistral, UE)     [intercambiable vía LLMProvider]
                          |-- BD   (PostgreSQL, UE)
                          |-- FHIR (conector con el HIS)
```

Flujo: audio → STT → (borrar audio) → LLM → borrador → revisión médica → FHIR → HIS.

---

## 4. Stack y estructura

- Backend: Python 3.12, FastAPI, Pydantic v2, async.
- Frontend: Flutter 3.x, Dart, Riverpod (estado), Dio (HTTP), `record` (audio).
- Integración: HL7 FHIR R4 (`fhir.resources`).
- Infra: cloud europeo (OVHcloud / Scaleway), Docker.

```
backend/app/
  api/routes/      endpoints REST
  core/            seguridad (OIDC) y auditoría
  models/          esquemas Pydantic (la nota clínica)
  services/stt/    interfaz STTProvider + implementaciones
  services/llm/    interfaz LLMProvider + implementaciones
  services/fhir/   mapeo nota -> FHIR
  pipeline/        orquestación del flujo
frontend/lib/
  core/            config y cliente HTTP
  models/          modelo de la nota (espejo del backend)
  features/audio/  captura de audio
  features/consultation/  controlador y pantalla de revisión
```

---

## 5. Comandos

### Backend
```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env          # rellenar claves
uvicorn app.main:app --reload # docs en http://localhost:8000/docs
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8000
flutter test
flutter analyze
```

---

## 6. Convenciones de código

### General
- Mensajes de commit en español, en imperativo: "añade conector FHIR", "corrige…".
- Nombres de variables y funciones en inglés; comentarios y textos de usuario en español.
- Nada de secretos en el código ni en el repositorio. Usar variables de entorno y `.env` (en `.gitignore`).

### Backend (Python / FastAPI)
- Tipado estático en todo: anotaciones de tipos siempre.
- Modelos de datos con Pydantic v2; validar entradas y salidas.
- `async`/`await` para I/O (red, BD, llamadas a STT/LLM).
- No meter lógica de negocio en las rutas: las rutas llaman al `pipeline`/servicios.
- Respetar las interfaces abstractas: NO llamar a un proveedor concreto desde el
  pipeline; usar siempre `get_stt_provider()` / `get_llm_provider()`.
- Errores: lanzar `HTTPException` con códigos correctos; no exponer trazas internas.

### Frontend (Flutter / Dart)
- Estado con Riverpod; nada de estado global mutable suelto.
- Widgets pequeños y composables; separar UI de lógica (controladores).
- Llamadas de red solo a través de `ApiClient`.
- En almacenamiento seguro local guardar SOLO tokens, nunca datos clínicos.

### Patrón clave: abstracción de proveedores
Cualquier servicio externo (STT, LLM) se implementa detrás de su interfaz
(`STTProvider`, `LLMProvider`) y se selecciona por configuración. Para añadir un
proveedor: crear la implementación, registrarla en el `__init__.py` correspondiente.
**Nunca** acoplar el pipeline a un proveedor concreto.

---

## 7. Reglas de cumplimiento — NO NEGOCIABLES

Estas reglas condicionan el código. Si una tarea entra en conflicto con ellas,
detente y consulta con el equipo antes de continuar.

1. **Humano en el bucle**: la IA solo produce borradores. Nada se escribe en el HIS
   sin validación explícita del médico. No automatizar el guardado final.
2. **El producto es Clase I (apoyo administrativo)**: no añadir funciones que tomen o
   sugieran decisiones diagnósticas/terapéuticas. Eso lo convertiría en Clase IIa /
   alto riesgo y exigiría certificación por organismo notificado.
3. **Minimización del audio**: el audio se transcribe y se descarta. No persistirlo
   por defecto. Si alguna vez se necesita conservarlo, requiere consentimiento
   específico y decisión del equipo.
4. **Residencia UE**: ningún dato de salud sale de la UE. Verificar región y DPA de
   cada proveedor (STT, LLM, cloud) antes de procesar datos reales. Preferir
   proveedores UE (Mistral, Speechmatics, OVHcloud/Scaleway) frente a los de matriz
   estadounidense (exposición a la CLOUD Act).
5. **Transparencia (Reglamento de IA)**: toda nota generada debe indicar que fue
   creada con asistencia de IA y revisada por el médico.
6. **Trazabilidad**: registrar quién hizo qué y cuándo (auditoría inmutable), y el
   diff entre el borrador de IA y la versión validada.
7. **Anti-alucinación**: el LLM no debe inventar datos no mencionados; lo dudoso se
   marca como pendiente de confirmar. No relajar este prompt.
8. **Datos sensibles**: pseudonimizar cuando sea posible; nunca poner datos de salud
   en URLs, logs o servicios de terceros fuera de la UE.

---

## 8. Qué hacer y qué no al modificar el código

### Hacer
- Mantener las interfaces de proveedor desacopladas del núcleo.
- Añadir tests al tocar el pipeline o los servicios.
- Actualizar este archivo y los README si cambian convenciones o alcance.

### No hacer
- No introducir dependencias de proveedores fuera de la UE sin revisar §7.
- No añadir lógica clínica de decisión (ver §2 y §7).
- No guardar audio de forma persistente por defecto.
- No saltarte la pantalla de revisión del médico.
- No hardcodear claves ni endpoints; usar configuración.

---

## 9. Estado actual

El flujo funciona de extremo a extremo. Integraciones reales ya disponibles
(seleccionables por configuración; el mock sigue por defecto en dev):
STT en vivo (Gladia v2 Live, Speechmatics RT) y **LLM Mistral** con salida JSON
estructurada. **Auth OIDC en el backend**: valida el JWT del IdP (JWKS/RS256,
`iss`/`aud`/`exp`) y protege REST y WebSocket; hay Keycloak de dev en
`docker-compose` (realm `vionix`). Tareas reales pendientes: **login OIDC en el
frontend** (Authorization Code + PKCE), el conector FHIR con el HIS del hospital
piloto, y diarización médico/paciente fiable.

---

## 10. Pruebas y pre-push (NO NEGOCIABLE)

**Siempre se ejecutan las pruebas antes de `git push`** — tanto personas como
asistentes de IA. Esto está garantizado por un hook de Git versionado.

### Frontend (Flutter)
- Las pruebas viven en `frontend/test/` **espejando `lib/`**: una carpeta por feature
  (`test/features/<feature>/{domain,data,state_management}/...`).
- Convención: cada feature tiene pruebas de su **dominio** (entidades), su **repositorio**
  (con datasource/fake, sin red) y su **controller** (con repo falso vía `ProviderContainer`
  + `overrideWithValue`). No se mockea con red real ni dispositivos.
- Comandos: `flutter analyze` y `flutter test` (desde `frontend/`).

### Hook pre-push (el "lugar indicado")
- Script versionado: [`.githooks/pre-push`](./.githooks/pre-push). Corre `flutter analyze`
  + `flutter test`; si algo falla, **aborta el push**.
- Activación una sola vez por clon:
  ```bash
  git config core.hooksPath .githooks
  ```
- Resuelve Flutter desde PATH, `fvm` o `~/fvm/versions/*` automáticamente.

### Regla para asistentes de IA
Antes de proponer o ejecutar `git push`, ejecuta las pruebas y confirma que están en
verde. Si añades una feature nueva, **añade su carpeta de pruebas** siguiendo la
convención de arriba (dominio + repo + controller).

> Backend: mantiene su propia suite `pytest` (ver `backend/README.md`). Puede añadirse al
> hook o a CI cuando el equipo lo decida.

---

## 11. Internacionalización (i18n) — REGLA PERMANENTE

La app usa `gen_l10n` con **español (por defecto/fallback) e inglés**. Archivos en
`frontend/lib/l10n/` (`app_es.arb`, `app_en.arb`); acceso vía `context.l10n.<clave>`
(extensión en `frontend/lib/core/l10n_ext.dart`).

**Regla para asistentes de IA y el equipo:** **nunca** escribas texto de usuario
*hardcodeado* en los widgets. Cada cadena nueva visible:
1. Se añade como clave en **`app_en.arb` y `app_es.arb`** (ambos; con placeholders si lleva
   variables).
2. Se usa en la UI con `context.l10n.<clave>` (jamás un literal).
3. Los estilos de texto salen **siempre del theme** (`Theme.of(context).textTheme` /
   `context.tokens`), nunca colores hardcodeados, para que se vean bien en claro/oscuro.

> Persistencia de preferencias (p. ej. tema): `shared_preferences` desde el controller
> Riverpod (cargar en el constructor, guardar en cada cambio) — equivalente a `hydrated_bloc`.
>
> Pendiente de migrar a i18n (cadenas en clases sin `BuildContext`): etiquetas de
> `ConsultationType`, `DocumentTemplates`, `Speaker`, chips de estado y mensajes de error
> lanzados. Migrar cuando se toquen, pasando los textos ya traducidos desde la capa de UI.
