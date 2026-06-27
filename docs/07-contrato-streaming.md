# 07 — Contrato de streaming de transcripción (F2)

Documento vivo. Define el **contrato WebSocket** que el frontend (app Flutter Vionix)
espera del backend para la **Fase F2 — Captura en vivo** (ver
[`06-roadmap-frontend.md`](06-roadmap-frontend.md), §9). Sigue el principio
**front-first con contrato**: el frontend ya está implementado contra una **fuente
*fake*** y este documento es lo que falta para conectar el backend real (Gio).

> Estado backend: **implementado con mock, borrador desde el stream funcionando**.
> El endpoint WebSocket (`app/api/routes/streaming.py`) transcribe en vivo sobre
> `RealtimeSTTProvider` (hoy `MockRealtimeSTTProvider`) y, al cerrarse la sesión,
> **genera el borrador a partir de la propia transcripción** (sin re-subir audio,
> §6). El frontend ya consume `WebSocketTranscriptionSource`. Falta el proveedor
> real de streaming (Gladia Real-Time / Speechmatics RT) y enviar el audio binario
> del micrófono por el canal para alimentarlo.

---

## 1. Endpoint

```
WebSocket  ws(s)://<API_BASE_URL>/consultations/{consultation_id}/stream
```

- Esquema derivado de `API_BASE_URL`: `http→ws`, `https→wss`.
- Autenticación: la misma sesión que el resto de la API (cuando exista OIDC, F3).
- El backend transcribe **al vuelo** y **descarta el audio** (minimización, CLAUDE.md §7).

---

## 2. Mensajes cliente → servidor

| Tipo | Formato | Significado |
|------|---------|-------------|
| audio | *frame binario* | Chunk PCM 16-bit, 16 kHz, mono (igual config que la captura actual). |
| control | `{"type": "pause"}` | Pausa la sesión: el servidor deja de emitir segmentos. |
| control | `{"type": "resume"}` | Reanuda tras una pausa. |
| control | `{"type": "stop"}` | Cierre ordenado de la sesión. |

> En el Slice 1 el frontend gestiona pausar/reanudar localmente y consume una fuente
> *fake*; el envío de audio binario se cableará al integrar el backend real.

---

## 3. Mensajes servidor → cliente (frames de texto, JSON)

Modelo de *utterance* único: en cada momento hay como mucho **un** segmento
`partial` en curso; cuando el interlocutor termina llega un `final` que lo consolida.

```jsonc
// Resultado parcial (interino): el texto aún puede cambiar.
{ "type": "partial", "speaker": "medico", "text": "Buenos días, cuént…", "start_ms": 1200 }

// Segmento consolidado: ya no cambia.
{ "type": "final", "speaker": "paciente", "text": "Me duele el pecho.", "start_ms": 1200, "end_ms": 3400 }

// Error recuperable o fatal de la transcripción.
{ "type": "error", "message": "STT no disponible" }

// Cierre ordenado del canal (fin de la consulta).
{ "type": "closed" }
```

### Campos

| Campo | Tipo | Notas |
|-------|------|-------|
| `type` | `"partial" \| "final" \| "error" \| "closed"` | Discrimina el evento. |
| `speaker` | `"medico" \| "paciente" \| "desconocido"` | Diarización. Valor desconocido ⇒ `desconocido`. |
| `text` | `string` | Texto del segmento (parcial = prefijo creciente). |
| `start_ms` | `int?` | Offset desde el inicio de la consulta. |
| `end_ms` | `int?` | Solo en `final`. |
| `message` | `string` | Solo en `error`. |

---

## 4. Mapeo en el frontend (referencia)

- Transporte y JSON: `WebSocketTranscriptionSource`
  (`features/consultation/data/datasources/transcription_stream_source.dart`).
- Frames → entidades de dominio (`TranscriptionEvent`):
  `TranscriptionStreamRepositoryImpl`.
- Para conectar el backend real basta cambiar `transcriptionStreamSourceProvider`
  de `FakeTranscriptionStreamSource()` a `WebSocketTranscriptionSource()`
  (cambio aislado, el resto no se entera).

---

## 5. Anti-alucinación y Clase I

- El backend **no** debe inventar texto: si el STT no entiende, emite menos o marca
  el segmento como `desconocido`, nunca rellena.
- El frontend muestra los `partial` de forma **tenue** para que el médico distinga lo
  provisional de lo consolidado. Sigue siendo trazabilidad, **no** decisión clínica.

---

## 6. Generación del borrador desde el stream (al finalizar)

Cuando el médico pulsa **Finalizar**, el frontend cierra el canal (cierre del socket;
opcionalmente `{"type":"stop"}`). **No se re-sube el audio**: el backend ya tiene la
transcripción de la sesión.

- El backend acumula los segmentos `final` de la sesión y, **al cerrarse el canal**,
  lanza la estructuración del borrador con el `LLMProvider` (sin volver a llamar al
  STT) — `DraftFromTranscriptUseCase`. Se ejecuta **desacoplado** del handler WS
  (tarea independiente) para que la desconexión del cliente no lo cancele a medias.
- La consulta debe existir (el frontend la crea con `POST /consultations` **antes**
  de abrir el canal y usa ese `id` en la URL del WS).
- El frontend recoge el resultado por el flujo HTTP normal: hace *polling* de
  `GET /consultations/{id}/status` hasta `completed` (o `failed`) y luego
  `GET /consultations/{id}` para el borrador → pantalla de revisión.
- Si no hubo transcripción, la consulta pasa a `failed` (el cliente no se queda
  esperando).

> Pieza front: `ConsultationController.awaitDraftFromStream()` tras
> `LiveTranscriptionController.finishCapture()`.

---

## 7. Anti-alucinación y Clase I (recordatorio)

- El borrador es solo eso: lo valida el médico (humano en el bucle) antes de nada.
- El audio fluye en tránsito y se descarta; con borrador-desde-stream el audio **ni
  siquiera sale del dispositivo** al finalizar (mejor minimización aún).

> Estado: v0.3 — endpoint WS + mock + **borrador desde el stream** (sin re-subida).
> Pendiente: proveedor real (Gladia Real-Time) y envío del audio del micrófono por
> el canal para alimentarlo.
