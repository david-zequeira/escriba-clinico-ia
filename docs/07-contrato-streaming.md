# 07 — Contrato de streaming de transcripción (F2)

Documento vivo. Define el **contrato WebSocket** que el frontend (app Flutter Vionix)
espera del backend para la **Fase F2 — Captura en vivo** (ver
[`06-roadmap-frontend.md`](06-roadmap-frontend.md), §9). Sigue el principio
**front-first con contrato**: el frontend ya está implementado contra una **fuente
*fake*** y este documento es lo que falta para conectar el backend real (Gio).

> Estado backend: **pendiente**. Hoy `STTProvider` solo expone `transcribe()` (batch).
> F2 necesita además un `transcribe_stream()` y un endpoint WebSocket.

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

> Estado: v0.1 — contrato inicial para el Slice 1 de F2 (streaming + waveform).
