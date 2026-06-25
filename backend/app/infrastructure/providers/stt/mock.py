"""STT simulado para desarrollo y tests. Devuelve una transcripción diarizada fija."""
from __future__ import annotations

import asyncio

from app.domain.enums import ConsultationType
from app.domain.ports import STTProvider
from app.domain.value_objects import Transcript, TranscriptSegment


class MockSTTProvider(STTProvider):
    name = "mock-stt"

    async def transcribe(
        self,
        audio_bytes: bytes,
        language: str = "es",
        consultation_type: ConsultationType = ConsultationType.admission_interview,
    ) -> Transcript:
        await asyncio.sleep(0)  # simula I/O async
        return Transcript(
            language=language,
            segments=[
                TranscriptSegment(speaker="medico", text="Buenos días, ¿qué le trae hoy?", start_ms=0, end_ms=2000),
                TranscriptSegment(speaker="paciente", text="Tengo dolor de cabeza desde hace tres días.", start_ms=2000, end_ms=5000),
                TranscriptSegment(speaker="medico", text="¿Toma alguna medicación?", start_ms=5000, end_ms=7000),
            ],
        )
