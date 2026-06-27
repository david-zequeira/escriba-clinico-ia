"""STT en streaming con Gladia v2 Live (Francia, UE).

Implementa `RealtimeSTTProvider` sobre la API Live de Gladia:
1. `POST /v2/live` con la config del audio → devuelve una `url` WebSocket.
2. Se conecta a esa `url`; el audio (PCM 16-bit, 16 kHz, mono) se envía como
   frames binarios y Gladia devuelve mensajes `transcript` (parciales y finales).
3. Al terminar se envía `{"type":"stop_recording"}`.

Requiere `STT_API_KEY` (misma clave Gladia que el STT batch). El audio fluye en
tránsito y no se persiste (minimización §7). Anti-alucinación: no se inventa
interlocutor; en mono no hay diarización fiable → `desconocido`.
"""
from __future__ import annotations

import json
from collections.abc import AsyncIterator

import httpx
import websockets
from websockets.asyncio.client import ClientConnection

from app.core.config import settings
from app.domain.enums import ConsultationType
from app.domain.ports import RealtimeSTTProvider, RealtimeTranscriptionSession
from app.domain.streaming import (
    FinalTranscript,
    PartialTranscript,
    TranscriptionClosed,
    TranscriptionEvent,
    TranscriptionStreamError,
)

_API_BASE = "https://api.gladia.io"

# Debe coincidir con la captura del cliente (record: pcm16bits, 16 kHz, mono).
_SAMPLE_RATE = 16000
_BIT_DEPTH = 16
_CHANNELS = 1

# Gladia indexa canales 0/1; en ingreso el médico suele hablar primero.
_SPEAKER_LABELS = ("medico", "paciente")


class GladiaRealtimeSession(RealtimeTranscriptionSession):
    """Sesión Live de Gladia: empuja audio al WS y traduce sus mensajes a eventos."""

    def __init__(
        self,
        ws: ClientConnection,
        consultation_type: ConsultationType,
    ) -> None:
        self._ws = ws
        self._type = consultation_type
        self._paused = False
        self._closed = False

    async def events(self) -> AsyncIterator[TranscriptionEvent]:
        try:
            async for raw in self._ws:
                # Solo nos interesan los mensajes de texto (JSON); ignora binarios.
                if isinstance(raw, (bytes, bytearray)):
                    continue
                event = self._map_message(raw)
                if event is not None:
                    yield event
        except websockets.ConnectionClosed:
            pass
        except Exception as exc:  # noqa: BLE001 - reportar como error de transcripción
            yield TranscriptionStreamError(message=f"Gladia live: {exc}")
        if not self._closed:
            yield TranscriptionClosed()

    def _map_message(self, raw: str) -> TranscriptionEvent | None:
        try:
            msg = json.loads(raw)
        except (ValueError, TypeError):
            return None
        if not isinstance(msg, dict) or msg.get("type") != "transcript":
            return None  # speech_start/end, acks y resúmenes no se reenvían

        data = msg.get("data") or {}
        utterance = data.get("utterance") or {}
        text = (utterance.get("text") or "").strip()
        if not text:
            return None

        speaker = _map_speaker_live(utterance.get("channel"))
        start = utterance.get("start")
        start_ms = int(start * 1000) if start is not None else None

        if data.get("is_final"):
            end = utterance.get("end")
            end_ms = int(end * 1000) if end is not None else None
            return FinalTranscript(
                speaker=speaker, text=text, start_ms=start_ms, end_ms=end_ms
            )
        return PartialTranscript(speaker=speaker, text=text, start_ms=start_ms)

    async def push_audio(self, chunk: bytes) -> None:
        if self._paused or self._closed:
            return
        try:
            await self._ws.send(chunk)
        except websockets.ConnectionClosed:
            self._closed = True

    async def pause(self) -> None:
        # Gladia Live no tiene pausa nativa: dejamos de enviar audio (sin audio,
        # no hay transcripción) y reanudamos al volver.
        self._paused = True

    async def resume(self) -> None:
        self._paused = False

    async def close(self) -> None:
        if self._closed:
            return
        self._closed = True
        try:
            await self._ws.send(json.dumps({"type": "stop_recording"}))
        except Exception:  # noqa: BLE001 - el cierre no debe propagar
            pass
        try:
            await self._ws.close(code=1000)
        except Exception:  # noqa: BLE001
            pass


class GladiaRealtimeSTTProvider(RealtimeSTTProvider):
    name = "gladia-realtime"

    def __init__(self) -> None:
        if not settings.STT_API_KEY:
            raise ValueError("STT_API_KEY es obligatoria para Gladia Real-Time")

    async def open(
        self,
        *,
        language: str = "es",
        consultation_type: ConsultationType = ConsultationType.admission_interview,
    ) -> RealtimeTranscriptionSession:
        ws_url = await self._init_session(language)
        ws = await websockets.connect(ws_url)
        return GladiaRealtimeSession(ws, consultation_type)

    async def _init_session(self, language: str) -> str:
        body = {
            "encoding": "wav/pcm",
            "sample_rate": _SAMPLE_RATE,
            "bit_depth": _BIT_DEPTH,
            "channels": _CHANNELS,
            "language_config": {
                "languages": [_gladia_language(language)],
                "code_switching": False,
            },
            "messages_config": {"receive_partial_transcripts": True},
        }
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{_API_BASE}/v2/live",
                headers={
                    "x-gladia-key": settings.STT_API_KEY,
                    "Content-Type": "application/json",
                },
                json=body,
            )
            response.raise_for_status()
            return response.json()["url"]


def _gladia_language(language: str) -> str:
    """Gladia usa códigos ISO de dos letras (es, fr, en...)."""
    return language.split("-")[0].lower()


def _map_speaker_live(channel: int | None) -> str:
    """En streaming mono Gladia no diariza: todo llega por el canal 0, que NO
    identifica al interlocutor. Se marca `desconocido` (anti-alucinación §7); la
    atribución médico/paciente la hace después el LLM (`assign_speakers`). El
    `channel` se conserva en la firma para un futuro soporte multicanal.
    """
    _ = channel
    return "desconocido"
