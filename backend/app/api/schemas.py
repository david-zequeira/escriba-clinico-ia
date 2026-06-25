"""DTOs HTTP (Pydantic v2). Separan el contrato REST del modelo de dominio."""
from __future__ import annotations

from datetime import datetime
from typing import Annotated, Union
from uuid import UUID

from pydantic import BaseModel, Field

from app.domain.clinical_documents import AdmissionNote, EvolutionNote, TreatmentOrdersNote
from app.domain.document_templates import document_title, section_labels
from app.domain.entities import Consultation
from app.domain.enums import ConsultationStatus, ConsultationType
from app.domain.value_objects import Transcript

ClinicalDraftDto = Annotated[
    Union[AdmissionNote, TreatmentOrdersNote, EvolutionNote],
    Field(discriminator="document_type"),
]


class CreateConsultationRequest(BaseModel):
    doctor_id: str | None = Field(
        default=None, description="Opcional: por defecto el médico autenticado."
    )
    patient_id: str = Field(
        description="Número de identidad del paciente (DNI, NIE o identificador hospitalario).",
    )
    consultation_type: ConsultationType = Field(
        default=ConsultationType.admission_interview,
        description="Tipo de documento clínico a generar.",
    )


class ConsultationStatusResponse(BaseModel):
    id: UUID
    consultation_type: ConsultationType
    status: ConsultationStatus
    error: str | None = None
    updated_at: datetime


class ConsultationResponse(BaseModel):
    id: UUID
    doctor_id: str
    patient_id: str
    consultation_type: ConsultationType
    document_title: str
    section_labels: dict[str, str]
    status: ConsultationStatus
    transcript: Transcript | None = None
    clinical_draft: ClinicalDraftDto | None = None
    error: str | None = None
    created_at: datetime
    updated_at: datetime

    @classmethod
    def from_entity(cls, c: Consultation) -> "ConsultationResponse":
        return cls(
            id=c.id,
            doctor_id=c.doctor_id,
            patient_id=c.patient_id,
            consultation_type=c.consultation_type,
            document_title=document_title(c.consultation_type),
            section_labels=section_labels(c.consultation_type),
            status=c.status,
            transcript=c.transcript,
            clinical_draft=c.clinical_draft,
            error=c.error,
            created_at=c.created_at,
            updated_at=c.updated_at,
        )


class AudioUploadResponse(BaseModel):
    id: UUID
    consultation_type: ConsultationType
    status: ConsultationStatus


class ValidateConsultationRequest(BaseModel):
    note: ClinicalDraftDto


class ValidateConsultationResponse(BaseModel):
    id: UUID
    status: ConsultationStatus
    fhir: dict
