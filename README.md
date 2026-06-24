# Health Care IA

Agente de documentación clínica: escucha la consulta médico-paciente, genera un
borrador de historia clínica y lo integra en el HIS del hospital. Diseñado para
cumplimiento RGPD/MDR desde el inicio (clase I: apoyo administrativo, no decisión clínica).

## Arquitectura
```
Flutter (cliente)  ->  FastAPI (backend / orquestación)
                          |-- STT  (Speechmatics, español médico)   [intercambiable]
                          |-- LLM  (Mistral, UE)                     [intercambiable]
                          |-- BD   (PostgreSQL, UE)
                          |-- FHIR (conector con el HIS)
```
Todo el backend y los servicios residen dentro de la jurisdicción de la UE.

## Carpetas
- `backend/`  — API FastAPI con interfaces abstractas de STT y LLM
- `frontend/` — app Flutter multiplataforma

## Flujo
1. El médico graba la consulta (con consentimiento del paciente).
2. El backend transcribe (STT) y estructura (LLM) -> borrador.
3. El audio se descarta (minimización RGPD).
4. El médico revisa y valida el borrador.
5. La nota validada se vuelca al HIS vía FHIR.

## Decisiones clave
- Frontend: Flutter (un código, todas las plataformas).
- Backend: Python + FastAPI (ecosistema IA + async + WebSocket).
- STT: Speechmatics (español + médico + UE). Cambiable por la interfaz `STTProvider`.
- LLM: Mistral (postura RGPD más limpia, sin CLOUD Act). Cambiable por `LLMProvider`.
- Integración: HL7 FHIR R4.

## Aviso
Los archivos de servicios externos son STUBS (resultados simulados) para que el
flujo funcione de extremo a extremo. Sustituir por los SDK reales y verificar
región UE + DPA de cada proveedor antes de procesar datos de pacientes reales.
