"""Implementación SQLAlchemy del ConsultationRepository (mapeo ORM <-> dominio)."""
from __future__ import annotations

from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.clinical_documents import parse_clinical_draft
from app.domain.entities import Consultation
from app.domain.enums import ConsultationStatus, ConsultationType
from app.domain.ports import ConsultationRepository
from app.domain.value_objects import Transcript
from app.infrastructure.db.models import ConsultationModel


def _to_entity(row: ConsultationModel) -> Consultation:
    return Consultation(
        id=row.id,
        doctor_id=row.doctor_id,
        patient_id=row.patient_id,
        consultation_type=ConsultationType(row.consultation_type),
        status=ConsultationStatus(row.status),
        audio_path=row.audio_path,
        transcript=Transcript.model_validate(row.transcript) if row.transcript else None,
        clinical_draft=(
            parse_clinical_draft(row.clinical_draft) if row.clinical_draft else None
        ),
        error=row.error,
        created_at=row.created_at,
        updated_at=row.updated_at,
    )


def _apply(entity: Consultation, row: ConsultationModel) -> None:
    row.doctor_id = entity.doctor_id
    row.patient_id = entity.patient_id
    row.consultation_type = entity.consultation_type
    row.status = entity.status
    row.audio_path = entity.audio_path
    row.transcript = entity.transcript.model_dump(mode="json") if entity.transcript else None
    row.clinical_draft = (
        entity.clinical_draft.model_dump(mode="json") if entity.clinical_draft else None
    )
    row.error = entity.error
    row.created_at = entity.created_at
    row.updated_at = entity.updated_at


class SqlAlchemyConsultationRepository(ConsultationRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def add(self, consultation: Consultation) -> Consultation:
        row = ConsultationModel(id=consultation.id)
        _apply(consultation, row)
        self._session.add(row)
        await self._session.commit()
        await self._session.refresh(row)
        return _to_entity(row)

    async def get(self, consultation_id: UUID) -> Consultation | None:
        row = await self._session.get(ConsultationModel, consultation_id)
        return _to_entity(row) if row else None

    async def update(self, consultation: Consultation) -> Consultation:
        row = await self._session.get(ConsultationModel, consultation.id)
        if row is None:
            raise ValueError(f"Consultation {consultation.id} no existe")
        _apply(consultation, row)
        await self._session.commit()
        await self._session.refresh(row)
        return _to_entity(row)
