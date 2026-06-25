"""Caso de uso: el médico valida la nota (humano en el bucle) y se genera el FHIR."""
from __future__ import annotations

from uuid import UUID

from app.core.audit import log_event
from app.domain.entities import Consultation
from app.domain.exceptions import ConsultationNotFound
from app.domain.ports import ConsultationRepository
from app.domain.clinical_documents import ClinicalDraft, parse_clinical_draft
from app.infrastructure.fhir.mapper import note_to_fhir


class ValidateConsultationUseCase:
    def __init__(self, repo: ConsultationRepository) -> None:
        self._repo = repo

    async def execute(
        self, consultation_id: UUID, validated_note: ClinicalDraft
    ) -> tuple[Consultation, dict]:
        consultation = await self._repo.get(consultation_id)
        if consultation is None:
            raise ConsultationNotFound(str(consultation_id))

        consultation.validate(validated_note)  # invariante: solo desde 'completed'
        await self._repo.update(consultation)

        bundle = note_to_fhir(
            validated_note,
            consultation.patient_id,
            consultation.doctor_id,
            consultation.consultation_type,
        )
        log_event(consultation.doctor_id, "validate_note", str(consultation_id))
        # TODO: escribir `bundle` en el HIS del hospital vía conector FHIR.
        return consultation, bundle
