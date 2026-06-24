"""Implementación STT con Speechmatics (modelo médico, español).

STUB: sustituir las llamadas simuladas por el SDK/REST real de Speechmatics.
Verificar región UE y firmar el DPA antes de procesar datos reales.
"""
from app.config import settings
from app.models.schemas import Transcript, TranscriptSegment
from app.services.stt.base import STTProvider


class SpeechmaticsSTT(STTProvider):
    name = "speechmatics-medical"

    def __init__(self) -> None:
        self.api_key = settings.STT_API_KEY
        # TODO: inicializar cliente real, fijar endpoint UE y modo 'medical'.

    async def transcribe(self, audio_bytes: bytes, language: str = "es") -> Transcript:
        # TODO: enviar audio_bytes a Speechmatics (batch) con diarización.
        # Devolvemos un resultado simulado para que el pipeline funcione de extremo a extremo.
        return Transcript(
            language=language,
            segments=[
                TranscriptSegment(speaker="medico", text="(transcripción simulada)"),
            ],
        )

    async def transcribe_stream(self, audio_chunks, language: str = "es"):
        # TODO: abrir conexión de streaming y emitir segmentos parciales.
        async for _chunk in audio_chunks:
            yield TranscriptSegment(speaker="desconocido", text="(parcial)")
