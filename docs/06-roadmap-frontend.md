# 06 — Roadmap del producto: próximas fases (enfoque frontend)

Documento vivo. Complementa [`03-brechas-y-roadmap.md`](03-brechas-y-roadmap.md) (roadmap
general hacia el MVP) con el **plan de ejecución del lado del frontend** (app Flutter
Vionix) para **aumentar el valor del MVP** y construir un **diferencial de sector**, sin
salir de la clasificación **Clase I** (ver [`05-cumplimiento.md`](05-cumplimiento.md)).

> Recordatorio de objetivo (ver [`02-vision-mvp.md`](02-vision-mvp.md)): un **escriba** que
> genera **borradores** de nota clínica; el médico **siempre** revisa y valida; datos en la
> **UE**; humano en el bucle; sin funciones de **decisión clínica**.

---

## 0. Principios que guían estas fases

1. **El diferencial es confianza, UX, integración y soberanía** — no la decisión clínica.
2. **Cada fase entrega valor demostrable** y deja la app compilando, testeada y multiplataforma.
3. **Front-first con contrato**: cuando algo depende del backend, el frontend define primero el
   **contrato de datos** y trabaja con *mock*, para no bloquearse (alineado con la capa `data`).
4. **Definición de Hecho (DoD) por fase** — ver §8.

---

## Fase F0 — Base de frontend ✅ (hecho)

Design system `vionix_app_ui` (tokens, temas claro/oscuro, motion), arquitectura por capas
(presentation/domain/data) con repos por entidad, imports absolutos, rebuilds localizados,
batería de pruebas por feature y **hook `pre-push`** que corre analyze + tests.

> Punto de partida para todo lo siguiente.

---

## Fase F1 — Confianza y evidencia ⭐ (diferencial · front-led)

**Objetivo:** que el médico **confíe** en el borrador y lo revise más rápido.

- **Alcance frontend:**
  - **Evidence grounding**: tocar un campo de la nota → resaltar el **fragmento de la
    transcripción** que lo originó (panel de transcripción + anclas por sección).
  - Mejorar la UX de `needs_confirmation` (campos "Revisar") con foco/orden y navegación
    "ir al siguiente pendiente".
  - **Diff borrador IA ↔ versión validada** visible antes de confirmar (apoya auditoría).
  - Reforzar el badge de transparencia "asistido por IA".
- **Contrato que pedimos al backend:** por cada sección, lista de `evidence_spans`
  (`{start_ms, end_ms, text}`) que referencian la transcripción. Mientras tanto, *mock*.
- **Valor / diferencial:** explicabilidad y anti-alucinación de cara al usuario; **pocos
  competidores lo hacen bien**. Es trazabilidad, **no** decisión clínica → sigue siendo Clase I.
- **Aceptación:** desde la pantalla de revisión se puede ver, por campo, la evidencia que lo
  respalda; los campos dudosos se recorren con un control; el diff se muestra al validar.

---

## Fase F2 — Captura en vivo (streaming · front-led + WS backend)

> **Estado: Slice 1 + 2, flujo unificado.** Captura en una **sola pantalla**
> (`ConsultationCaptureScreen`): paciente + consentimiento → transcripción en vivo
> (parciales + diarización) sobre el **WebSocket real** del backend, waveform con
> **amplitud real** y **pausar/reanudar** → **Finalizar**. Al finalizar, el **backend
> genera el borrador a partir de la propia transcripción del stream** (sin re-subir
> audio) y se abre la revisión. Sustituye a las pantallas separadas de grabación y de
> live. Contrato en [`07-contrato-streaming.md`](07-contrato-streaming.md).
>
> **STT real (Gladia v2 Live):** implementado y config-gated
> (`STT_REALTIME_PROVIDER=gladia` + `STT_API_KEY`, ver
> [`07-contrato-streaming.md`](07-contrato-streaming.md) §8). El frontend ya envía el
> audio del micrófono por el canal. **Pendiente:** diarización fiable en mono y
> prueba end-to-end con clave real.

**Objetivo:** reducir la espera y dar sensación de producto "en tiempo real".

- **Alcance frontend:**
  - Pantalla de **transcripción en streaming** (segmentos parciales con diarización
    médico/paciente) sobre el `web_socket_channel` ya presente.
  - Borrador que se **va construyendo en vivo** conforme avanza la consulta.
  - Waveform con **amplitud real** del micrófono (hoy es decorativo) y control de sesión
    (pausar/reanudar) con estados claros.
- **Contrato:** WebSocket `/consultations/{id}/stream` con eventos de segmento; el
  `transcribe_stream()` del backend ya está previsto en las interfaces.
- **Valor:** percepción de inmediatez; permite corregir sobre la marcha.
- **Aceptación:** una consulta muestra texto parcial en vivo y el borrador se actualiza sin recargar.

---

## Fase F3 — Identidad y sesión real (OIDC · front + backend)

**Objetivo:** sustituir el login simulado por autenticación real del hospital.

- **Alcance frontend:**
  - Login **OIDC** real (PKCE), almacenamiento **solo de tokens** en `flutter_secure_storage`,
    **refresh** y manejo de expiración.
  - **Guardas de ruta** (redirect central en `go_router`) y cierre de sesión seguro.
  - `AuthRepositoryImpl` real detrás de la interfaz `AuthRepository` ya existente (cambio
    aislado, sin tocar UI ni controller).
- **Contrato:** issuer/clientId/discovery del IdP; claims (`sub`, rol médico, `practitioner_id`).
- **Valor:** requisito de piloto; identidad verificada para auditoría.
- **Aceptación:** un médico entra con credenciales del hospital; la sesión expira y se renueva
  correctamente; las pantallas protegidas exigen sesión.

---

## Fase F4 — Escala por especialidades y contexto del paciente

**Objetivo:** "una herramienta, muchas notas" — argumento de venta a un hospital.

- **Alcance frontend:**
  - Añadir **tipos de documento / especialidades** nuevos con el comando `/new-use-case`
    (la pantalla de revisión ya es genérica y dirigida por plantilla).
  - **Selector de especialidad** y plantillas específicas.
  - Render del **contexto del paciente** traído del HIS (FHIR *read*) para *fundamentar* la
    nota (mostrar antecedentes/alergias como contexto, **sin** que la IA los invente).
- **Contrato:** `GET` de contexto FHIR del paciente (read-only) y `consultation_type` extendido.
- **Valor:** cobertura clínica amplia con el mismo núcleo; demuestra la arquitectura reutilizable.
- **Aceptación:** alta de una especialidad nueva sin tocar el núcleo; la revisión muestra el
  contexto del paciente claramente separado del borrador generado.

---

## Fase F5 — Cumplimiento de cara al usuario (front-led)

**Objetivo:** que la app *demuestre* el cumplimiento, no solo lo respete.

- **Alcance frontend:**
  - **Consentimiento** robusto: diálogo + registro auditable antes de grabar (endurecer el actual).
  - **Auditoría visible**: quién/qué/cuándo y el diff de la nota validada.
  - **i18n (ARB)** con español por defecto y base multi-idioma.
  - **Accesibilidad WCAG AA** (contraste, foco, teclado, *text scaling*, *reduce-motion* — ya
    soportado en el motion).
  - Indicación persistente de "borrador asistido por IA y revisado por el profesional".
- **Valor:** confianza institucional y legal; reduce fricción con comités de ética/RGPD.
- **Aceptación:** flujo de consentimiento auditable; UI navegable por teclado y con contraste AA;
  textos vía i18n.

---

## Fase F6 — Calidad, métricas y release multiplataforma

**Objetivo:** dejar la app lista para distribuir y medir el piloto.

- **Alcance frontend:**
  - **Golden tests** de UI (consistencia visual en claro/oscuro y breakpoints) + más widget tests.
  - **Métricas de adopción** (tiempo de revisión, nº de ediciones) **sin juicio clínico**.
  - Generar plataformas faltantes (`flutter create --platforms=ios,android,web .`) y verificar.
  - **CI** (GitHub Actions) que ejecute analyze + test (complementa el hook `pre-push`).
- **Valor:** distribución interna al piloto y datos para validar hipótesis del MVP.
- **Aceptación:** build en las plataformas objetivo; CI verde; panel mínimo de métricas.

---

## 7. Guardarraíl (qué NO incluir)

Ninguna fase añade **decisión clínica** (diagnóstico, dosis, alertas terapéuticas). Eso
convertiría el producto en **Clase IIa / alto riesgo** y exigiría certificación. El valor se
construye en **confianza, captura, integración, escala y soberanía**.

---

## 8. Definición de Hecho (DoD) — aplica a cada fase

- [ ] `flutter analyze` sin issues y `flutter test` en verde (lo refuerza el hook `pre-push`).
- [ ] Tests por feature añadidos siguiendo la convención (`domain` + `data` + `state_management`).
- [ ] UI deriva del design system (tokens; sin hex sueltos) y funciona en claro/oscuro.
- [ ] Responsive/adaptativo verificado (compact → expanded) y **multiplataforma** intacto.
- [ ] Sin PHI en logs; solo tokens en almacenamiento seguro; humano en el bucle respetado.
- [ ] Si depende del backend, el **contrato de datos** queda documentado (y mockeado mientras).

---

## 9. Contratos con el backend (resumen para coordinar con Gio)

| Fase | Necesita del backend |
|------|----------------------|
| F1 | `evidence_spans` por sección en el borrador |
| F2 | WebSocket de transcripción en streaming con diarización |
| F3 | Configuración OIDC + claims (rol, `practitioner_id`) |
| F4 | FHIR *read* de contexto del paciente; nuevos `consultation_type` |
| F6 | Endpoints de métricas (opcional) |

---

## 10. Recomendación de arranque

Empezar por **F1 (Confianza y evidencia)**: es el **diferencial** del producto, es **front-led**
(podemos avanzar con *mock* y definir el contrato de `evidence_spans` para Gio), y eleva la
calidad percibida de inmediato. F2 (streaming) es el siguiente salto de "sensación de producto".

> Estado: v0.1 — documento inicial de fases de frontend.
