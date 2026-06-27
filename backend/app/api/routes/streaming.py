"""Endpoint WebSocket de transcripción en vivo (F2).

Hace de puente: recibe audio (frames binarios) y mensajes de control del cliente
Flutter, los pasa al proveedor STT en streaming, y reenvía los eventos
(partial/final/error/closed) como JSON del contrato (`docs/07-contrato-streaming.md`).

Cumplimiento (CLAUDE.md §7):
- El audio fluye en tránsito y se descarta; no se persiste (minimización).
- No se loguea el texto transcrito (sin PHI en logs).
- Sigue siendo un borrador: la nota y la revisión del médico no cambian (Clase I).
"""
from __future__ import annotations

import asyncio
import contextlib
import json
import logging
from collections import Counter
from uuid import UUID

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.domain.ports import RealtimeTranscriptionSession
from app.domain.streaming import FinalTranscript
from app.domain.value_objects import Transcript, TranscriptSegment
from app.infrastructure.providers.stt.realtime_factory import get_realtime_stt_provider
from app.workers.tasks import run_draft_from_transcript_job

# IMPORTANTE: este logger NUNCA emite el texto transcrito (PHI). Solo metadatos:
# tipos de evento, conteos, bytes de audio y acciones de control (§7.8).
logger = logging.getLogger("app.streaming")

router = APIRouter(tags=["streaming"])


@router.websocket("/consultations/{consultation_id}/stream")
async def stream_transcription(websocket: WebSocket, consultation_id: str) -> None:
    # TODO(F3): autenticar la sesión (OIDC) antes de aceptar, como el resto de la API.
    await websocket.accept()
    provider = get_realtime_stt_provider()
    session = await provider.open()
    logger.info(
        "WS abierto consultation=%s provider=%s", consultation_id, provider.name
    )

    events_sent: Counter[str] = Counter()
    audio = {"chunks": 0, "bytes": 0}
    # Transcripción consolidada de la sesión: con ella se genera el borrador al
    # cerrar, sin volver a llamar al STT (F2 slice 2). No se loguea el texto (§7).
    finals: list[TranscriptSegment] = []

    async def pump_events() -> None:
        """Eventos del STT → cliente. Loguea el tipo, nunca el texto."""
        with contextlib.suppress(WebSocketDisconnect, RuntimeError):
            async for event in session.events():
                if isinstance(event, FinalTranscript):
                    finals.append(
                        TranscriptSegment(
                            speaker=event.speaker,
                            text=event.text,
                            start_ms=event.start_ms,
                            end_ms=event.end_ms,
                        )
                    )
                frame = event.to_frame()
                events_sent[str(frame["type"])] += 1
                logger.debug("→ evento %s", frame["type"])
                await websocket.send_json(frame)

    async def pump_client() -> None:
        """Mensajes del cliente: control (texto JSON) o audio (binario)."""
        with contextlib.suppress(WebSocketDisconnect):
            while True:
                message = await websocket.receive()
                if message["type"] == "websocket.disconnect":
                    return
                if message.get("text") is not None:
                    await _handle_control(session, message["text"])
                elif message.get("bytes") is not None:
                    chunk = message["bytes"]
                    audio["chunks"] += 1
                    audio["bytes"] += len(chunk)
                    logger.debug("← audio chunk %d bytes", len(chunk))
                    await session.push_audio(chunk)

    events_task = asyncio.create_task(pump_events())
    client_task = asyncio.create_task(pump_client())
    try:
        # Termina en cuanto cierre cualquiera de los dos lados.
        await asyncio.wait(
            {events_task, client_task}, return_when=asyncio.FIRST_COMPLETED
        )
    finally:
        # PRIMERO: programa la generación del borrador como tarea independiente,
        # de forma síncrona y antes de cualquier `await`. Si se hiciera con
        # `await` aquí, la desconexión del cliente cancelaría este handler y con
        # él la generación a medias. Desacoplada (como la cola batch), sobrevive
        # al cierre del WS.
        _schedule_draft_from_stream(consultation_id, finals)
        for task in (events_task, client_task):
            task.cancel()
            with contextlib.suppress(asyncio.CancelledError):
                await task
        await session.close()
        with contextlib.suppress(RuntimeError):
            await websocket.close()
        logger.info(
            "WS cerrado consultation=%s eventos=%s audio_chunks=%d audio_bytes=%d",
            consultation_id,
            dict(events_sent),
            audio["chunks"],
            audio["bytes"],
        )


# Referencias fuertes a las tareas de borrador en vuelo (evita que el GC las
# recoja antes de terminar), igual que AsyncioJobQueue.
_draft_tasks: set[asyncio.Task] = set()


def _schedule_draft_from_stream(
    consultation_id: str, segments: list[TranscriptSegment]
) -> None:
    """Programa (best-effort) la generación del borrador con lo transcrito.

    Solo aplica si la sesión enlazó una consulta real (id UUID existente). Para
    ids de demo/no-UUID (p. ej. tests de contrato) no hay nada que completar.
    """
    if not segments:
        return
    try:
        cid = UUID(consultation_id)
    except ValueError:
        return
    transcript = Transcript(segments=segments)
    task = asyncio.create_task(_safe_draft(cid, transcript))
    _draft_tasks.add(task)
    task.add_done_callback(_draft_tasks.discard)


async def _safe_draft(consultation_id: UUID, transcript: Transcript) -> None:
    try:
        await run_draft_from_transcript_job(consultation_id, transcript)
    except Exception:  # noqa: BLE001 - no romper nada por el borrador
        logger.exception(
            "No se pudo generar el borrador desde el stream %s", consultation_id
        )


async def _handle_control(
    session: RealtimeTranscriptionSession, raw: str
) -> None:
    """Procesa un mensaje de control del cliente: pause | resume | stop."""
    try:
        control = json.loads(raw)
    except (ValueError, TypeError):
        return
    action = control.get("type") if isinstance(control, dict) else None
    if action in ("pause", "resume", "stop"):
        logger.info("← control %s", action)
    if action == "pause":
        await session.pause()
    elif action == "resume":
        await session.resume()
    elif action == "stop":
        await session.close()
