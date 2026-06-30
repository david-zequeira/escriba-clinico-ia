"""Job de procesamiento. Construye sus propias dependencias y una sesión de BD nueva.

No reutiliza la sesión del request (ya cerrada): cada job es autónomo y reanudable.
"""
from __future__ import annotations

from uuid import UUID

from app.application.use_cases.draft_from_transcript import DraftFromTranscriptUseCase
from app.application.use_cases.process_consultation import ProcessConsultationUseCase
from app.core.database import SessionFactory
from app.domain.value_objects import Transcript
from app.infrastructure.db.repositories import SqlAlchemyConsultationRepository
from app.infrastructure.providers.llm.factory import get_llm_provider
from app.infrastructure.providers.stt.factory import get_stt_provider
from app.infrastructure.storage.local import get_audio_storage


async def run_processing_job(consultation_id: UUID) -> None:
    async with SessionFactory() as session:
        repo = SqlAlchemyConsultationRepository(session)
        use_case = ProcessConsultationUseCase(
            repo=repo,
            stt=get_stt_provider(),
            llm=get_llm_provider(),
            storage=get_audio_storage(),
        )
        await use_case.execute(consultation_id)


async def run_draft_from_transcript_job(
    consultation_id: UUID, transcript: Transcript
) -> None:
    """Genera el borrador desde la transcripción del stream (F2), sin STT."""
    async with SessionFactory() as session:
        repo = SqlAlchemyConsultationRepository(session)
        use_case = DraftFromTranscriptUseCase(repo=repo, llm=get_llm_provider())
        await use_case.execute(consultation_id, transcript)
