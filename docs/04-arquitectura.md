# 04 — Arquitectura técnica

## 1. Vista general

```
┌─────────────────────────────────────────────────────────────────┐
│                     Flutter (cliente)                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────────────┐ │
│  │  Auth    │  │  Audio   │  │ Revisión │  │  ApiClient      │ │
│  │  OIDC    │  │ Recorder │  │  Screen  │  │  (Dio)          │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────────┬────────┘ │
│       └─────────────┴─────────────┴─────────────────┘         │
└───────────────────────────────┬─────────────────────────────────┘
                                │ HTTPS (UE)
┌───────────────────────────────▼─────────────────────────────────┐
│                   FastAPI (orquestación)                         │
│  ┌────────────┐  ┌─────────────┐  ┌──────────────────────────┐  │
│  │ Security   │  │  Routes     │  │  Pipeline Orchestrator   │  │
│  │ OIDC/JWT   │──│ consultations│──│  audio→STT→LLM→draft   │  │
│  └────────────┘  └─────────────┘  └────────────┬─────────────┘  │
│  ┌────────────┐  ┌─────────────┐              │                 │
│  │ Audit      │  │  FHIR       │◄─────────────┘                 │
│  │ (append)   │  │  Mapper     │                                │
│  └─────┬──────┘  └──────┬──────┘                                │
└────────┼────────────────┼────────────────────────────────────────┘
         │                │
    ┌────▼────┐     ┌─────▼─────┐     ┌────────────┐
    │PostgreSQL│     │ HIS       │     │ Proveedores│
    │   (UE)   │     │ (FHIR R4) │     │ externos UE│
    └──────────┘     └───────────┘     ├────────────┤
                                       │Speechmatics│
                                       │  (STT)     │
                                       │  Mistral   │
                                       │  (LLM)     │
                                       └────────────┘
```

## 2. Flujo de datos (MVP)

### 2.1 Creación de consulta

```
Audio (bytes) ──► POST /consultations
                      │
                      ├─► log_event(upload_audio)
                      ├─► STTProvider.transcribe()
                      ├─► del audio_bytes  (minimización)
                      ├─► LLMProvider.structure_note()
                      ├─► log_event(draft_generated)
                      └─► ConsultationResult { id, transcript, draft }
```

### 2.2 Validación

```
ClinicalNote (editada) ──► POST /consultations/{id}/validate
                                │
                                ├─► note_to_fhir()
                                ├─► HIS.write(bundle)     [pendiente MVP]
                                ├─► audit(diff draft→final)
                                └─► { status: validated }
```

## 3. Backend — capas

| Capa | Responsabilidad | Ubicación |
|------|-----------------|-----------|
| API | HTTP, validación entrada, auth | `app/api/routes/` |
| Core | Seguridad, auditoría transversal | `app/core/` |
| Pipeline | Orquestación sin lógica de proveedor | `app/pipeline/` |
| Services | Integraciones externas detrás de interfaces | `app/services/` |
| Models | Esquemas Pydantic (dominio API) | `app/models/` |

### 3.1 Patrón de proveedores

```python
# El pipeline NUNCA importa implementaciones concretas
stt = get_stt_provider()   # → SpeechmaticsSTT según STT_PROVIDER
llm = get_llm_provider()   # → MistralLLM según LLM_PROVIDER
```

Añadir un proveedor nuevo:

1. Crear clase que implemente `STTProvider` o `LLMProvider`
2. Registrar en `__init__.py` de `stt/` o `llm/`
3. Añadir valor en `.env` — sin tocar `orchestrator.py`

### 3.2 Modelos de dominio clave

**Transcript** — segmentos con `speaker` (`medico` | `paciente` | `desconocido`)

**ClinicalNote** — cinco secciones (`ClinicalSection`), cada una con:
- `content`: texto de la sección
- `needs_confirmation`: flag anti-alucinación

**ConsultationStatus** — máquina de estados:
`capturing → transcribing → structuring → awaiting_review → validated | error`

> Hoy el orquestador salta directamente a `awaiting_review`; los estados intermedios se usarán con persistencia y jobs async.

## 4. Frontend — estado actual vs. objetivo

### Actual (plano)

```
lib/
├── core/           # config, api_client
├── models/         # clinical_note (manual)
├── features/
│   ├── audio/      # ConsultationRecorder (aislado)
│   └── consultation/  # controller + review_screen
└── main.dart
```

### Objetivo MVP (feature-first + capas)

```
lib/
├── core/
│   ├── config/
│   ├── network/
│   └── router/
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   ├── consultation/
│   │   ├── domain/       # entities (freezed), use cases
│   │   ├── data/         # repositories, DTOs
│   │   └── presentation/ # screens, widgets, controllers
│   └── audio/
└── main.dart
```

La refactorización a Clean Architecture completa (F11) puede posponerse si no bloquea el piloto; sí es obligatorio el flujo funcional.

## 5. API REST (contrato actual)

### `POST /consultations`

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `audio` | file (multipart) | Audio de la consulta |
| `specialty` | string (form) | Especialidad, default `general` |

**Response:** `ConsultationResult`

```json
{
  "consultation_id": "uuid",
  "status": "awaiting_review",
  "transcript": { "language": "es", "segments": [...] },
  "draft": { "motivo_consulta": {...}, ... }
}
```

### `POST /consultations/{consultation_id}/validate`

| Parámetro | Ubicación | Descripción |
|-----------|-----------|-------------|
| `patient_id` | query | ID paciente en el HIS |
| body | JSON | `ClinicalNote` revisada |

**Response:**

```json
{
  "status": "validated",
  "fhir": { "resourceType": "Composition", ... }
}
```

### Autenticación

Header: `Authorization: Bearer <JWT OIDC>`

Claims esperados (a definir con IdP): `sub`, `name`, rol médico, `practitioner_id` o mapeo a Practitioner FHIR.

## 6. Integración FHIR (objetivo MVP)

### Recursos previstos

| Recurso FHIR | Uso |
|--------------|-----|
| `Composition` | Documento principal de la nota |
| `Encounter` | Vincular a la consulta |
| `Condition` | Diagnóstico (si el HIS lo espera separado) |
| `DocumentReference` | Referencia al documento en el HIS |

### Estado actual

`note_to_fhir()` devuelve un dict simplificado tipo `Composition` sin validación FHIR ni escritura al servidor.

### Próximos pasos

1. Obtener perfil FHIR del hospital piloto (Implementation Guide)
2. Usar `fhir.resources` para construcción tipada
3. Cliente HTTP hacia endpoint FHIR del HIS con auth del hospital
4. Manejar idempotencia (reintentos sin duplicar notas)

## 7. Base de datos (diseño propuesto, no implementado)

```sql
-- consultas
consultations (
  id UUID PK,
  practitioner_id VARCHAR,
  patient_id VARCHAR NULL,
  status VARCHAR,
  specialty VARCHAR,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)

-- borradores y versiones
clinical_notes (
  id UUID PK,
  consultation_id UUID FK,
  version INT,
  is_ai_draft BOOLEAN,
  note_json JSONB,
  created_at TIMESTAMPTZ
)

-- auditoría append-only
audit_events (
  id BIGSERIAL PK,
  actor_id VARCHAR,
  action VARCHAR,
  consultation_id UUID,
  detail JSONB,
  created_at TIMESTAMPTZ
)
```

El diff borrador IA vs. nota validada se calcula al validar y se guarda en `audit_events.detail`.

## 8. Seguridad

| Aspecto | MVP | Post-MVP |
|---------|-----|----------|
| Transporte | TLS 1.2+ | mTLS interno |
| Auth | OIDC JWT | Refresh tokens |
| Autorización | Rol médico | RBAC por servicio |
| Datos en reposo | Cifrado BD | Cifrado campo a campo |
| Secretos | Vault / env cifrado | Rotación automática |
| Logs | Sin PHI | Agregación centralizada UE |

## 9. Despliegue

### Local (objetivo inmediato)

```yaml
# docker-compose.yml (pendiente)
services:
  api:
    build: ./backend
    ports: ["8000:8000"]
    env_file: .env
  db:
    image: postgres:16
    volumes: [pgdata:/var/lib/postgresql/data]
```

### Producción piloto (UE)

- Contenedor API detrás de reverse proxy (HTTPS)
- PostgreSQL gestionado en misma región
- Sin exposición pública de BD
- WAF básico en endpoint API

## 10. Puntos de extensión futuros

| Extensión | Mecanismo |
|-----------|-----------|
| Otro STT | Nueva clase + `STT_PROVIDER` |
| Otro LLM | Nueva clase + `LLM_PROVIDER` |
| Streaming | `transcribe_stream()` + WebSocket route |
| Multi-idioma | Parámetro `language` ya en interfaces |
| Otra especialidad | Prompt templates por `specialty` |
