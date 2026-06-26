"""Casos de uso de lectura: obtener consulta completa y obtener estado."""
from __future__ import annotations

from uuid import UUID

from app.domain.entities import Consultation
from app.domain.exceptions import ConsultationNotFound
from app.domain.ports import ConsultationRepository


class GetConsultationUseCase:
    def __init__(self, repo: ConsultationRepository) -> None:
        self._repo = repo

    async def execute(self, consultation_id: UUID) -> Consultation:
        consultation = await self._repo.get(consultation_id)
        if consultation is None:
            raise ConsultationNotFound(str(consultation_id))
        return consultation
