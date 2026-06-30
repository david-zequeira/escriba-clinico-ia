"""Eventos de la transcripción en vivo (F2).

Espejo en el backend del contrato WebSocket de `docs/07-contrato-streaming.md`.
Cada evento sabe serializarse al *frame* JSON que el frontend espera
(`type` discrimina: partial | final | error | closed).

Anti-alucinación (§7): el motor STT no debe inventar texto; lo dudoso se emite
como `desconocido` o no se emite, nunca se rellena.
"""
from __future__ import annotations

from pydantic import BaseModel


class TranscriptionEvent(BaseModel):
    """Base de los eventos servidor→cliente del canal de transcripción."""

    def to_frame(self) -> dict[str, object]:  # pragma: no cover - se sobreescribe
        raise NotImplementedError


class PartialTranscript(TranscriptionEvent):
    """Resultado interino: el texto aún puede cambiar. El front lo muestra tenue."""

    speaker: str
    text: str
    start_ms: int | None = None

    def to_frame(self) -> dict[str, object]:
        return {
            "type": "partial",
            "speaker": self.speaker,
            "text": self.text,
            "start_ms": self.start_ms,
        }


class FinalTranscript(TranscriptionEvent):
    """Segmento consolidado: ya no cambia."""

    speaker: str
    text: str
    start_ms: int | None = None
    end_ms: int | None = None

    def to_frame(self) -> dict[str, object]:
        return {
            "type": "final",
            "speaker": self.speaker,
            "text": self.text,
            "start_ms": self.start_ms,
            "end_ms": self.end_ms,
        }


class TranscriptionStreamError(TranscriptionEvent):
    """Error recuperable o fatal de la transcripción."""

    message: str

    def to_frame(self) -> dict[str, object]:
        return {"type": "error", "message": self.message}


class TranscriptionClosed(TranscriptionEvent):
    """Cierre ordenado del canal (fin de la consulta)."""

    def to_frame(self) -> dict[str, object]:
        return {"type": "closed"}
