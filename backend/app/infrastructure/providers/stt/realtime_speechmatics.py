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
        # Diarización real de Speechmatics: ids estables S1/S2… Guardamos el orden
        # de aparición de cada hablante. El rol (médico/paciente) solo se infiere
        # cuando hay ≥2 voces distintas; con una sola voz no se adivina (queda
        # 'desconocido') para no etiquetar de "Médico" lo que aún no se sabe.
        # En cualquier caso, el LLM reatribuye los roles por contenido al generar
        # el borrador; esto es solo una previsualización en vivo.
        self._speaker_order: dict[str, int] = {}
        # Speechmatics entrega los finales palabra a palabra. Para no fragmentar
        # la transcripción (una tarjeta por palabra) acumulamos por frase y solo
        # emitimos un FinalTranscript al cerrar la frase (`is_eos`) o al cambiar
        # de interlocutor. Mejora también la diarización por LLM en el borrador.
        self._buf_text: str = ""
        self._buf_speaker: str | None = None
        self._buf_start_ms: int | None = None
        self._buf_end_ms: int | None = None

    async def events(self) -> AsyncIterator[TranscriptionEvent]:
        try:
            async for raw in self._ws:
                if isinstance(raw, (bytes, bytearray)):
                    continue
                msg = json.loads(raw)
                message = msg.get("message")
                if message == "AddPartialTranscript":
                    event = self._on_partial(msg)
                    if event is not None:
                        yield event
                elif message == "AddTranscript":
                    for event in self._on_final(msg):
                        yield event
                elif message == "EndOfTranscript":
                    flushed = self._flush_buffer()
                    if flushed is not None:
                        yield flushed
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
        flushed = self._flush_buffer()
        if flushed is not None:
            yield flushed
        if not self._closed:
            yield TranscriptionClosed()

    def _on_final(self, msg: dict) -> list[TranscriptionEvent]:
        """Acumula el delta finalizado; emite la frase al cerrarse o al cambiar
        de interlocutor (puede producir 0, 1 o 2 eventos)."""
        metadata = msg.get("metadata") or {}
        delta = metadata.get("transcript") or ""
        if not delta.strip():
            return []
        speaker = self._role(self._first_speaker(msg))
        events: list[TranscriptionEvent] = []
        # Cambio de interlocutor → cerrar la frase anterior antes de seguir.
        if self._buf_text and speaker != self._buf_speaker:
            flushed = self._flush_buffer()
            if flushed is not None:
                events.append(flushed)
        if not self._buf_text:
            self._buf_speaker = speaker
            start = metadata.get("start_time")
            self._buf_start_ms = int(start * 1000) if start is not None else None
        self._buf_text = self._buf_text + delta if self._buf_text else delta
        end = metadata.get("end_time")
        self._buf_end_ms = int(end * 1000) if end is not None else self._buf_end_ms
        if self._is_eos(msg):
            flushed = self._flush_buffer()
            if flushed is not None:
                events.append(flushed)
        return events

    def _on_partial(self, msg: dict) -> TranscriptionEvent | None:
        """Texto vivo de la frase en curso: lo ya consolidado + el parcial."""
        metadata = msg.get("metadata") or {}
        delta = (metadata.get("transcript") or "").strip()
        live = (self._buf_text + " " + delta).strip() if self._buf_text else delta
        if not live:
            return None
        speaker = self._buf_speaker or self._role(self._first_speaker(msg))
        start_ms = self._buf_start_ms
        if start_ms is None:
            start = metadata.get("start_time")
            start_ms = int(start * 1000) if start is not None else None
        return PartialTranscript(speaker=speaker, text=live, start_ms=start_ms)

    def _flush_buffer(self) -> TranscriptionEvent | None:
        """Vuelca la frase acumulada como FinalTranscript y limpia el buffer."""
        text = self._buf_text.strip()
        if not text:
            self._buf_text = ""
            return None
        event = FinalTranscript(
            speaker=self._buf_speaker or "desconocido",
            text=text,
            start_ms=self._buf_start_ms,
            end_ms=self._buf_end_ms,
        )
        self._buf_text = ""
        self._buf_speaker = None
        self._buf_start_ms = None
        self._buf_end_ms = None
        return event

    @staticmethod
    def _is_eos(msg: dict) -> bool:
        """True si el mensaje cierra una frase (puntuación con `is_eos`)."""
        for result in msg.get("results") or []:
            if result.get("is_eos"):
                return True
        return False

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
        if speaker_id not in self._speaker_order:
            self._speaker_order[speaker_id] = len(self._speaker_order)
        # Con una sola voz no se puede distinguir médico de paciente: 'desconocido'
        # (la UI lo muestra neutro). Solo al aparecer un 2.º interlocutor inferimos
        # el rol por orden (el médico suele abrir); el médico lo corrige si procede.
        if len(self._speaker_order) < 2:
            return "desconocido"
        order = self._speaker_order[speaker_id]
        return "medico" if order == 0 else "paciente" if order == 1 else "desconocido"

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
