"""Entidad agregada del dominio: Consultation. Lógica pura, sin dependencias de framework."""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from uuid import UUID, uuid4

from app.domain.enums import ConsultationStatus, ConsultationType
from app.domain.exceptions import InvalidStateTransition
from app.domain.clinical_documents import ClinicalDraft, parse_clinical_draft
from app.domain.value_objects import Transcript


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


@dataclass
class Consultation:
    """Agregado raíz. El estado solo cambia a través de sus métodos de dominio."""

    doctor_id: str
    patient_id: str
    consultation_type: ConsultationType = ConsultationType.admission_interview
    id: UUID = field(default_factory=uuid4)
    status: ConsultationStatus = ConsultationStatus.created
    audio_path: str | None = None
    transcript: Transcript | None = None
    clinical_draft: ClinicalDraft | None = None
    error: str | None = None
    created_at: datetime = field(default_factory=_utcnow)
    updated_at: datetime = field(default_factory=_utcnow)

    # --- Transiciones de estado (invariantes del dominio) ---

    def attach_audio(self, audio_path: str) -> None:
        if self.status not in (ConsultationStatus.created, ConsultationStatus.failed):
            raise InvalidStateTransition(
                f"No se puede subir audio en estado {self.status.value}"
            )
        self.audio_path = audio_path
        self._set_status(ConsultationStatus.queued)

    def mark_processing_stt(self) -> None:
        self._set_status(ConsultationStatus.processing_stt)

    def set_transcript(self, transcript: Transcript) -> None:
        self.transcript = transcript

    def discard_audio(self) -> None:
        """Minimización de datos (RGPD): el audio se descarta tras transcribir."""
        self.audio_path = None

    def mark_processing_llm(self) -> None:
        self._set_status(ConsultationStatus.processing_llm)

    def complete(self, draft: ClinicalDraft) -> None:
        self.clinical_draft = draft
        self.error = None
        self._set_status(ConsultationStatus.completed)

    def fail(self, reason: str) -> None:
        self.error = reason
        self._set_status(ConsultationStatus.failed)

    def validate(self, validated_note: ClinicalDraft) -> None:
        """El médico confirma la nota (humano en el bucle)."""
        if self.status != ConsultationStatus.completed:
            raise InvalidStateTransition(
                "Solo se valida una consulta con borrador completado"
            )
        self.clinical_draft = validated_note
        self._set_status(ConsultationStatus.validated)

    def _set_status(self, status: ConsultationStatus) -> None:
        self.status = status
        self.updated_at = _utcnow()
