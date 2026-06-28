"""STT en streaming con Speechmatics Real-Time (modelo médico, endpoint UE).

Implementa `RealtimeSTTProvider` sobre la API RT de Speechmatics:
1. Conecta a `wss://eu.rt.speechmatics.com/v2` con `Authorization: Bearer <key>`
   (endpoint UE → residencia de datos, CLAUDE.md §7.4).
2. Envía `StartRecognition` (audio PCM 16-bit/16 kHz/mono, modelo médico en español,
   diarización por interlocutor) y espera `RecognitionStarted`.
3. El audio se envía como frames binarios (`AddAudio`); el servidor devuelve
   `AddPartialTranscript`/`AddTranscript` con diarización real (S1/S2…).
4. Al terminar se envía `EndOfStream`.

Ventajas para sanidad: modelo médico (alta precisión clínica), diarización en vivo
y safeguards anti-alucinación nativos, todo en infraestructura UE.
"""
from __future__ import annotations

import json
from collections.abc import AsyncIterator

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


class SpeechmaticsRealtimeSession(RealtimeTranscriptionSession):
    """Sesión RT de Speechmatics: empuja audio y traduce sus mensajes a eventos."""

    def __init__(
        self, ws: ClientConnection, consultation_type: ConsultationType
    ) -> None:
        self._ws = ws
        self._type = consultation_type
        self._paused = False
        self._closed = False
        self._audio_seq = 0
        # Diarización real de Speechmatics: ids estables S1/S2… El rol (médico/
        # paciente) se asigna por orden de aparición (el médico suele abrir). El
        # médico revisa; si se invierte, lo corrige.
        self._roles: dict[str, str] = {}

    async def events(self) -> AsyncIterator[TranscriptionEvent]:
        try:
            async for raw in self._ws:
                if isinstance(raw, (bytes, bytearray)):
                    continue
                msg = json.loads(raw)
                message = msg.get("message")
                if message == "AddPartialTranscript":
                    event = self._segment(msg, final=False)
                    if event is not None:
                        yield event
                elif message == "AddTranscript":
                    event = self._segment(msg, final=True)
                    if event is not None:
                        yield event
                elif message == "EndOfTranscript":
                    break
                elif message == "Error":
                    yield TranscriptionStreamError(
                        message=f"Speechmatics: {msg.get('reason') or msg.get('type')}"
                    )
                    break
                # RecognitionStarted | AudioAdded | Info | Warning → se ignoran.
        except websockets.ConnectionClosed:
            pass
        except Exception as exc:  # noqa: BLE001 - reportar como error de transcripción
            yield TranscriptionStreamError(message=f"Speechmatics live: {exc}")
        if not self._closed:
            yield TranscriptionClosed()

    def _segment(self, msg: dict, *, final: bool) -> TranscriptionEvent | None:
        text = (msg.get("transcript") or "").strip()
        if not text:
            return None
        metadata = msg.get("metadata") or {}
        start = metadata.get("start_time")
        start_ms = int(start * 1000) if start is not None else None
        speaker = self._role(self._first_speaker(msg))
        if final:
            end = metadata.get("end_time")
            end_ms = int(end * 1000) if end is not None else None
            return FinalTranscript(
                speaker=speaker, text=text, start_ms=start_ms, end_ms=end_ms
            )
        return PartialTranscript(speaker=speaker, text=text, start_ms=start_ms)

    def _first_speaker(self, msg: dict) -> str | None:
        for result in msg.get("results") or []:
            for alt in result.get("alternatives") or []:
                if alt.get("speaker"):
                    return alt["speaker"]
        return None

    def _role(self, speaker_id: str | None) -> str:
        if self._type != ConsultationType.admission_interview:
            return "medico"
        if not speaker_id:
            return "desconocido"
        if speaker_id not in self._roles:
            order = len(self._roles)
            self._roles[speaker_id] = (
                "medico" if order == 0 else "paciente" if order == 1 else "desconocido"
            )
        return self._roles[speaker_id]

    async def push_audio(self, chunk: bytes) -> None:
        if self._paused or self._closed:
            return
        try:
            await self._ws.send(chunk)  # frame binario = AddAudio
            self._audio_seq += 1
        except websockets.ConnectionClosed:
            self._closed = True

    async def pause(self) -> None:
        self._paused = True

    async def resume(self) -> None:
        self._paused = False

    async def close(self) -> None:
        if self._closed:
            return
        self._closed = True
        try:
            await self._ws.send(
                json.dumps({"message": "EndOfStream", "last_seq_no": self._audio_seq})
            )
        except Exception:  # noqa: BLE001
            pass
        try:
            await self._ws.close()
        except Exception:  # noqa: BLE001
            pass


class SpeechmaticsRealtimeSTTProvider(RealtimeSTTProvider):
    name = "speechmatics-realtime"

    def __init__(self) -> None:
        if not settings.SPEECHMATICS_API_KEY:
            raise ValueError(
                "SPEECHMATICS_API_KEY es obligatoria para Speechmatics Real-Time"
            )

    async def open(
        self,
        *,
        language: str = "es",
        consultation_type: ConsultationType = ConsultationType.admission_interview,
    ) -> RealtimeTranscriptionSession:
        ws = await websockets.connect(
            settings.SPEECHMATICS_RT_URL,
            additional_headers={
                "Authorization": f"Bearer {settings.SPEECHMATICS_API_KEY}"
            },
        )
        await ws.send(json.dumps(_start_recognition(language, consultation_type)))
        # Hay que esperar RecognitionStarted antes de enviar audio.
        ack = json.loads(await ws.recv())
        if ack.get("message") == "Error":
            await ws.close()
            raise RuntimeError(
                f"Speechmatics rechazó la sesión: {ack.get('reason') or ack}"
            )
        return SpeechmaticsRealtimeSession(ws, consultation_type)


def _start_recognition(language: str, consultation_type: ConsultationType) -> dict:
    config: dict = {
        "language": _sm_language(language),
        "operating_point": settings.SPEECHMATICS_OPERATING_POINT,
        "enable_partials": True,
        "max_delay": settings.SPEECHMATICS_MAX_DELAY,
    }
    if settings.SPEECHMATICS_DOMAIN:
        config["domain"] = settings.SPEECHMATICS_DOMAIN
    # Diarización solo en la entrevista (2 interlocutores); el dictado es monólogo.
    if consultation_type == ConsultationType.admission_interview:
        config["diarization"] = "speaker"
        config["speaker_diarization_config"] = {"max_speakers": 2}
    return {
        "message": "StartRecognition",
        "audio_format": {"type": "raw", "encoding": "pcm_s16le", "sample_rate": 16000},
        "transcription_config": config,
    }


def _sm_language(language: str) -> str:
    return language.split("-")[0].lower()
