# Backend — Escriba Clínico IA

API FastAPI que convierte audio de consulta en un **borrador** de nota clínica estructurada.
El procesamiento (STT + LLM) es **asíncrono**: el audio se sube, un worker procesa en segundo plano y el cliente consulta el estado.

---

## Requisitos

- **Python 3.12+**
- No hace falta Docker ni PostgreSQL para empezar (usa SQLite por defecto).

---

## Arranque rápido

```bash
cd backend
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
python -m app
```

El servidor escucha en **http://localhost:8000**.

Comprueba que responde:

```bash
curl http://localhost:8000/health
# → {"status":"ok"}
```

---

## Swagger (documentación interactiva)

| URL | Qué es |
|-----|--------|
| http://localhost:8000/docs | Swagger UI (principal) |
| http://localhost:8000/redoc | ReDoc |
| http://localhost:8000/openapi.json | Esquema OpenAPI |

- **No requiere login** en desarrollo (`AUTH_DEV_BYPASS=true` en `.env`).
- Abrir `/` en el navegador redirige a `/docs`.
- Con `API_HOST=0.0.0.0` (por defecto en `.env.example`), otros dispositivos en la misma red pueden usar `http://<tu-ip>:8000/docs`.

---

## Probar el flujo completo en Swagger

Por defecto los providers son **mock** (sin claves API, respuesta simulada en segundos).

1. **POST `/consultations`** — Crear consulta.
   ```json
   {
     "patient_id": "12345678Z",
     "consultation_type": "admission_interview"
   }
   ```
   Tipos válidos: `admission_interview` | `treatment_orders` | `evolution`.

   Copia el `id` de la respuesta.

2. **POST `/consultations/{id}/audio`** — Subir un archivo de audio (cualquier `.wav`/`.m4a` sirve con mock).
   - Respuesta **202** y estado `queued`.

3. **GET `/consultations/{id}/status`** — Repetir hasta que `status` sea `completed` (con mock tarda poco).

4. **GET `/consultations/{id}`** — Ver `transcript` y `clinical_draft` (el esquema cambia según `consultation_type`).

5. *(Opcional)* **POST `/consultations/{id}/validate`** — Enviar la nota revisada; devuelve el bundle FHIR. El envío al HIS no está conectado en el MVP.

---

## Tests automáticos

```bash
pytest
```

Ejecutan el mismo flujo de extremo a extremo con providers mock y SQLite en memoria. No necesitan claves ni red.

---

## Configuración (`.env`)

| Variable | Valor por defecto | Notas |
|----------|-------------------|--------|
| `DATABASE_URL` | SQLite en `./var/vionix.db` | Se crea sola al arrancar |
| `STT_PROVIDER` | `mock` | `gladia` para transcripción real (UE) |
| `LLM_PROVIDER` | `mock` | `mistral` para estructuración real (UE) |
| `AUTH_DEV_BYPASS` | `true` | Usuario médico simulado; no pedir token |

### Probar con IA real (Gladia + Mistral)

En `.env`:

```bash
STT_PROVIDER=gladia
STT_API_KEY=tu_clave          # https://app.gladia.io
LLM_PROVIDER=mistral
LLM_API_KEY=tu_clave          # https://console.mistral.ai
LLM_MODEL=mistral-small-latest
```

Reinicia el servidor. En Swagger, sube audio real y espera más tiempo en el paso de `/status` (puede tardar 1–2 min).

**Validar solo el LLM (sin servidor ni audio):** con `LLM_PROVIDER=mistral` y `LLM_API_KEY` en `.env`, ejecuta el smoke-test, que estructura una conversación de ejemplo y muestra el borrador:

```bash
python -m scripts.smoke_mistral
```

Comprueba que las secciones reflejan lo dicho y que las que no tienen información quedan vacías (anti-alucinación, CLAUDE.md §7.7).

> No subas `.env` al repositorio. Las claves son personales.

### PostgreSQL (opcional)

```bash
docker compose up -d db
```

Y en `.env`:

```bash
DATABASE_URL=postgresql+asyncpg://vionix:vionix@localhost:5432/vionix
```

---

## Problemas frecuentes

| Síntoma | Solución |
|---------|----------|
| `unable to open database file` | Arranca desde `backend/` o borra y deja que se regenere: `rm -f var/vionix.db` |
| Cambios de esquema en BD local | `rm -f var/vionix.db` y reinicia |
| `/status` se queda en `queued` | Revisa logs del servidor; con providers reales, comprueba claves y red |
| Puerto 8000 ocupado | Cambia `API_PORT` en `.env` |

---

## Arquitectura (resumen)

```
api/ → application/ → domain/ ← infrastructure/
                              ↑ workers/ (cola asyncio)
```

- **api/** — Rutas HTTP y DTOs (Swagger).
- **application/** — Casos de uso (crear, subir audio, procesar, validar).
- **domain/** — Entidades, enums, modelos clínicos tipados (`AdmissionNote`, `TreatmentOrdersNote`, `EvolutionNote`).
- **infrastructure/** — BD, STT, LLM, storage, FHIR.
- **workers/** — Procesamiento async tras subir audio.

Regla: la lógica de negocio no llama a proveedores concretos; se inyectan vía factories (`STT_PROVIDER`, `LLM_PROVIDER`).

---

## Cumplimiento (recordatorio)

- Solo **borradores**; el médico valida antes de cualquier volcado al HIS.
- El audio se **descarta** tras transcribir (`DELETE_AUDIO_AFTER_TRANSCRIPTION=true`).
- Usar proveedores con residencia/DPA en **UE** para datos reales de pacientes.

Despliegue público (Fly.io): ver [DEPLOY.md](DEPLOY.md).
