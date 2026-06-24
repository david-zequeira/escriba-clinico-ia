# Backend — Escriba Clínico IA (FastAPI)

## Arranque local
```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # rellena tus claves
uvicorn app.main:app --reload
```
Documentación interactiva en http://localhost:8000/docs

## Estructura
- `app/services/stt/` — interfaz STT + implementación Speechmatics (cambiable)
- `app/services/llm/` — interfaz LLM + implementación Mistral (cambiable)
- `app/services/fhir/` — mapeo de la nota a FHIR R4
- `app/pipeline/orchestrator.py` — audio → STT → LLM → borrador
- `app/api/routes/` — endpoints REST
- `app/core/` — seguridad (OIDC) y auditoría

## Notas de cumplimiento
- El audio se descarta tras la transcripción (minimización RGPD).
- Toda nota indica que fue generada con IA y revisada por el médico (transparencia IA Act).
- Verificar región UE y DPA de cada proveedor (STT y LLM) antes de datos reales.
