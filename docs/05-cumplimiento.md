# 05 — Cumplimiento regulatorio (MVP)

## 1. Clasificación del producto

| Marco | Clasificación | Implicación MVP |
|-------|---------------|-----------------|
| **MDR (UE) 2017/745** | Dispositivo médico **Clase I** | Apoyo administrativo a la documentación; sin decisión clínica autónoma. Autodeclaración de conformidad; no requiere organismo notificado para Clase I. |
| **RGPD** | Tratamiento datos de salud (categoría especial Art. 9) | Base legal, DPIA, minimización, DPA con encargados |
| **Reglamento IA (UE)** | Sistema de IA de **riesgo limitado** (transparencia) | Informar que el contenido fue generado/asistido por IA |
| **LOPDGDD (España)** | Complemento RGPD | Consentimiento explícito para grabación |

### Línea roja — NO cruzar en el MVP

Funciones que moverían el producto a **Clase IIa / alto riesgo**:

- Diagnóstico autónomo o sugerencia de diagnóstico
- Recomendación de tratamiento o dosificación
- Alertas clínicas de seguridad del paciente
- Priorización de pacientes por gravedad inferida

El código actual respeta esto: el LLM solo redacta borradores y el médico valida.

---

## 2. Principios de cumplimiento en el código

Estos principios están en `CLAUDE.md` y deben mantenerse en cada PR hacia el MVP.

| # | Principio | Implementación actual | Gap MVP |
|---|-----------|----------------------|---------|
| 1 | Humano en el bucle | Pantalla revisión + endpoint `/validate` | UI editable + sin auto-save |
| 2 | Clase I (no decisión clínica) | Prompt anti-alucinación en `mistral.py` | Validar prompt en producción |
| 3 | Minimización audio | `del audio_bytes` en orchestrator | Verificar que STT no retiene; política proveedor |
| 4 | Residencia UE | Diseño Speechmatics/Mistral UE | Verificar regiones + DPA |
| 5 | Transparencia IA | `generated_by_ai` en modelo | Mostrar en UI |
| 6 | Trazabilidad | `log_event()` stub | BD append-only + diff |
| 7 | Anti-alucinación | `needs_confirmation` en schema | Prompt + UI de flags |
| 8 | No PHI en logs/URLs | Parcial | Revisar logging en integraciones |

---

## 3. Checklist RGPD para MVP

### 3.1 Documentación legal

- [ ] **DPIA / EIPD** — evaluación de impacto por tratamiento de datos de salud + IA
- [ ] **Registro de actividades de tratamiento** (RAT) actualizado
- [ ] **Información al paciente** — cláusula sobre grabación, IA y derechos
- [ ] **DPA** con Speechmatics (encargado STT)
- [ ] **DPA** con Mistral (encargado LLM)
- [ ] **DPA** con proveedor cloud UE (si aplica)

### 3.2 Medidas técnicas

- [ ] Cifrado en tránsito (TLS)
- [ ] Cifrado en reposo (BD)
- [ ] Control de acceso (OIDC, mínimo privilegio)
- [ ] Retención definida y borrado de consultas según política
- [ ] No almacenar audio tras transcripción
- [ ] Pseudonimización donde sea posible (IDs internos vs. nombre paciente)
- [ ] Auditoría de accesos

### 3.3 Consentimiento del paciente

Flujo MVP en UI:

1. Diálogo antes de grabar explicando: grabación, transcripción, IA, revisión médica
2. Botones explícitos: **Acepto** / **No acepto**
3. Si no acepta → no se graba
4. Registro en auditoría: `consent_given`, timestamp, `consultation_id`, sin datos innecesarios

Base legal habitual: **consentimiento explícito** (Art. 9.2.a RGPD) para grabación; el tratamiento posterior para documentación clínica puede apoyarse también en **misión de interés público en el ámbito de la salud pública** (Art. 9.2.h) + obligación legal del médico de documentar — **validar con asesoría jurídica del hospital**.

---

## 4. Reglamento de IA — transparencia

### Obligaciones aplicables (riesgo limitado)

- Informar al usuario (médico y, donde proceda, paciente) de que se usa IA
- Marcar contenido generado/asistido por IA en la nota final

### Implementación producto

| Ubicación | Qué mostrar |
|-----------|-------------|
| UI revisión | Banner: "Borrador generado con asistencia de IA. Revise antes de validar." |
| Nota validada | Campo/metadata `generated_by_ai: true` + texto en Composition FHIR |
| HIS (si permite) | Nota al pie en documento |

---

## 5. MDR Clase I — documentación técnica mínima

Para comercialización en UE como Clase I, preparar (puede iterarse durante piloto):

| Documento | Descripción |
|-----------|-------------|
| Declaración de conformidad UE | Autodeclaración del fabricante |
| Documentación técnica | Arquitectura, requisitos, verificación |
| Análisis de riesgos (ISO 14971 simplificado) | Riesgos de uso incorrecto, mitigaciones |
| Clasificación MDR | Justificación Clase I (Regla 11) |
| Etiquetado / IFU | Instrucciones de uso para el médico |
| Vigilancia poscomercialización | Proceso de reporte de incidentes |
| Gestión de cambios | Versionado software (ISO 62304 light) |

> El piloto con datos reales debe contar con aprobación del comité ético / DPO del hospital.

---

## 6. Proveedores externos — verificación UE

Antes de procesar datos reales:

| Proveedor | Verificar |
|-----------|-----------|
| **Speechmatics** | Región de procesamiento UE, DPA, subencargados, retención audio |
| **Mistral** | API EU endpoint, DPA, no entrenamiento con datos cliente |
| **Cloud (OVH/Scaleway)** | Región, certificaciones, DPA |
| **IdP hospital** | Ya cubierto por el hospital habitualmente |

### CLOUD Act

Evitar proveedores con matriz estadounidense sin garantías contractuales y técnicas de residencia UE. Por eso el diseño prioriza Mistral y Speechmatics frente a alternativas US.

---

## 7. Auditoría — requisitos MVP

Cada evento debe registrar:

| Campo | Ejemplo |
|-------|---------|
| `timestamp` | ISO 8601 UTC |
| `actor_id` | practitioner UUID |
| `action` | `upload_audio`, `draft_generated`, `consent_given`, `validate_note` |
| `consultation_id` | UUID |
| `detail` | JSON (diff, versión, sin PHI excesivo) |

### Diff borrador → validado

Al validar, calcular diff por sección:

```json
{
  "motivo_consulta": { "changed": true, "ai": "...", "final": "..." },
  "anamnesis": { "changed": false }
}
```

Almacenamiento **append-only** (sin UPDATE/DELETE en eventos de auditoría).

---

## 8. Riesgos de cumplimiento si se lanza sin completar

| Si se lanza sin… | Riesgo |
|------------------|--------|
| DPIA | Sanción RGPD, parada de piloto |
| DPA proveedores | Tratamiento ilícito |
| OIDC real | Acceso no autorizado a datos salud |
| Auditoría | Imposibilidad de demostrar trazabilidad |
| Consentimiento UI | Tratamiento sin base legal |
| STT/LLM fuera UE | Transferencia internacional ilegal |
| Auto-guardado en HIS | Viola "humano en el bucle" |

---

## 9. Referencias internas

- Reglas de código: [`CLAUDE.md`](../CLAUDE.md) §7
- Arquitectura de datos: [04-arquitectura.md](./04-arquitectura.md)
- Roadmap cumplimiento: [03-brechas-y-roadmap.md](./03-brechas-y-roadmap.md) (sección C*)
