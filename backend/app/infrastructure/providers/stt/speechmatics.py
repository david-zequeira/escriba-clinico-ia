"""STT con Speechmatics (modelo médico, español, región UE).

STUB: sustituir la simulación por el SDK/REST real. Verificar región UE y firmar
el DPA antes de procesar datos reales (residencia UE, §7 cumplimiento).
"""
from __future__ import annotations

from app.core.config import settings
from app.domain.enums import ConsultationType
from app.domain.ports import STTProvider
from app.domain.value_objects import Transcript, TranscriptSegment


class SpeechmaticsSTTProvider(STTProvider):
    name = "speechmatics-medical"

    def __init__(self) -> None:
        self.api_key = settings.STT_API_KEY
        # TODO: inicializar cliente real, fijar endpoint UE y modo 'medical' con diarización.

    async def transcribe(
        self,
        audio_bytes: bytes,
        language: str = "es",
        consultation_type: ConsultationType = ConsultationType.admission_interview,
    ) -> Transcript:
        _ = (audio_bytes, language, consultation_type)
        # TODO: enviar audio_bytes a Speechmatics (batch) con diarización y mapear la respuesta.
        raise NotImplementedError(
            "Implementar SDK de Speechmatics. Usar STT_PROVIDER=mock para desarrollo."
        )
        return Transcript(language=language, segments=[TranscriptSegment(speaker="desconocido", text="")])
