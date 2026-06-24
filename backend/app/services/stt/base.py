"""Interfaz de transcripción. Implementa esta clase por cada proveedor (Speechmatics, Deepgram, etc.)."""
from abc import ABC, abstractmethod

from app.models.schemas import Transcript


class STTProvider(ABC):
    """Contrato común para cualquier motor de voz a texto.

    Mantener esta abstracción permite cambiar de proveedor sin tocar el pipeline.
    """

    name: str = "base"

    @abstractmethod
    async def transcribe(self, audio_bytes: bytes, language: str = "es") -> Transcript:
        """Transcribe audio (modo por lotes) con diarización médico/paciente."""
        raise NotImplementedError

    @abstractmethod
    async def transcribe_stream(self, audio_chunks, language: str = "es"):
        """Transcripción en tiempo real. Devuelve un async iterator de segmentos parciales."""
        raise NotImplementedError
