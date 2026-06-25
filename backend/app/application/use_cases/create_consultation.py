"""Caso de uso: crear una consulta (aún sin audio)."""
from __future__ import annotations

from app.core.audit import log_event
from app.domain.entities import Consultation
from app.domain.enums import ConsultationType
from app.domain.ports import ConsultationRepository


class CreateConsultationUseCase:
    def __init__(self, repo: ConsultationRepository) -> None:
        self._repo = repo

    async def execute(
        self,
        doctor_id: str,
        patient_id: str,
        consultation_type: ConsultationType,
    ) -> Consultation:
        consultation = Consultation(
            doctor_id=doctor_id,
            patient_id=patient_id,
            consultation_type=consultation_type,
        )
        saved = await self._repo.add(consultation)
        log_event(doctor_id, "create_consultation", str(saved.id))
        return saved
