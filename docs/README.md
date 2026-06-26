# Documentación — Escriba Clínico IA

Índice de la documentación de desarrollo del producto. Estos documentos se actualizan conforme avanza el proyecto.

## Documentos

| Documento | Descripción |
|-----------|-------------|
| [01-estado-actual.md](./01-estado-actual.md) | Inventario del código existente, qué funciona y qué es stub |
| [02-vision-mvp.md](./02-vision-mvp.md) | Definición del MVP: alcance, criterios de éxito y flujo objetivo |
| [03-brechas-y-roadmap.md](./03-brechas-y-roadmap.md) | Gap analysis detallado y roadmap por fases |
| [04-arquitectura.md](./04-arquitectura.md) | Arquitectura técnica, capas y contratos entre componentes |
| [05-cumplimiento.md](./05-cumplimiento.md) | Requisitos regulatorios (RGPD, MDR, IA Act) aplicables al MVP |
| [06-roadmap-frontend.md](./06-roadmap-frontend.md) | Próximas fases del producto con enfoque de ejecución frontend y diferenciadores |

## Resumen ejecutivo

**Escriba Clínico IA** es un agente de documentación clínica (Clase I MDR) que transcribe consultas médico-paciente, genera un borrador estructurado de historia clínica y lo integra en el HIS del hospital tras validación humana obligatoria.

### Estado hoy (junio 2025)

El repositorio contiene un **esqueleto funcional de extremo a extremo** con integraciones externas simuladas (stubs). La arquitectura base (interfaces de proveedor, pipeline, modelos de datos, endpoints REST) está definida, pero **no es desplegable en producción** ni usable por un médico real sin completar las integraciones y el flujo de UI.

### Para llegar al MVP

Se estiman **4 fases** de trabajo (ver [03-brechas-y-roadmap.md](./03-brechas-y-roadmap.md)):

1. **Integraciones reales** — STT (Speechmatics), LLM (Mistral), FHIR al HIS piloto
2. **Flujo completo en Flutter** — grabación, consentimiento, revisión editable, validación
3. **Infraestructura y seguridad** — OIDC, PostgreSQL, auditoría persistente, despliegue UE
4. **Piloto clínico** — pruebas con hospital piloto, ajustes de prompt y cumplimiento

### Métrica de madurez actual

| Área | Completitud estimada |
|------|---------------------|
| Modelos de datos / esquemas | ~80 % |
| Pipeline backend | ~40 % (lógica ok, integraciones stub) |
| API REST | ~50 % |
| Frontend Flutter | ~25 % |
| Seguridad / auth | ~10 % |
| Persistencia / BD | 0 % |
| FHIR / HIS | ~15 % |
| Auditoría | ~10 % |
| Tests | 0 % |
| Infra / CI-CD | ~15 % (solo Dockerfile) |

**Madurez global hacia MVP: ~25 %**
