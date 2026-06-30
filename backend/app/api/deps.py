"""Dependencias FastAPI: wiring de repositorios, almacenamiento y cola hacia los casos de uso."""
from __future__ import annotations

from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_session
from app.domain.ports import AudioStorage, ConsultationRepository, JobQueue
from app.infrastructure.db.repositories import SqlAlchemyConsultationRepository
from app.infrastructure.storage.local import get_audio_storage
from app.workers.queue import get_job_queue

SessionDep = Annotated[AsyncSession, Depends(get_session)]


def get_consultation_repository(session: SessionDep) -> ConsultationRepository:
    return SqlAlchemyConsultationRepository(session)


RepositoryDep = Annotated[ConsultationRepository, Depends(get_consultation_repository)]
StorageDep = Annotated[AudioStorage, Depends(get_audio_storage)]
QueueDep = Annotated[JobQueue, Depends(get_job_queue)]
