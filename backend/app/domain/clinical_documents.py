"""Modelos de borrador clínico tipados por caso de uso (Fase A — esquemas semánticos).

Cada ConsultationType tiene su propio esquema de campos, alineado a documentación
hospitalaria habitual en UE/España y exportable a FHIR Composition.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Literal, Union

from pydantic import BaseModel, Field

from app.domain.enums import ConsultationType
from app.domain.value_objects import ClinicalSection


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


class DocumentMeta(BaseModel):
    """Metadatos comunes a todo borrador (cumplimiento IA Act)."""

    generated_by_ai: bool = True
    model_name: str | None = None
    created_at: datetime = Field(default_factory=_utcnow)


class AdmissionNote(DocumentMeta):
    """Historia clínica de ingreso (entrevista médico-paciente).

  Referencia FHIR: Composition LOINC 47039-3 (Hospital Admission H&P note).
    """

    document_type: Literal[ConsultationType.admission_interview] = (
        ConsultationType.admission_interview
    )
    motivo_ingreso: ClinicalSection = Field(default_factory=ClinicalSection)
    enfermedad_actual: ClinicalSection = Field(default_factory=ClinicalSection)
    antecedentes: ClinicalSection = Field(
        default_factory=ClinicalSection,
        description="Antecedentes personales, familiares, alergias y medicación habitual.",
    )
    exploracion_fisica: ClinicalSection = Field(default_factory=ClinicalSection)
    pruebas_complementarias: ClinicalSection = Field(default_factory=ClinicalSection)
    juicio_clinico: ClinicalSection = Field(default_factory=ClinicalSection)
    plan: ClinicalSection = Field(default_factory=ClinicalSection)


class TreatmentOrdersNote(DocumentMeta):
    """Indicaciones médicas de tratamiento (dictado del médico, paciente ingresado).

    MVP: texto estructurado en secciones. Fase B: MedicationRequest FHIR.
    Referencia FHIR: Composition LOINC 18776-5 (Plan of care note).
    """

    document_type: Literal[ConsultationType.treatment_orders] = ConsultationType.treatment_orders
    contexto: ClinicalSection = Field(default_factory=ClinicalSection)
    indicaciones_farmacologicas: ClinicalSection = Field(default_factory=ClinicalSection)
    indicaciones_no_farmacologicas: ClinicalSection = Field(default_factory=ClinicalSection)
    vigilancia: ClinicalSection = Field(default_factory=ClinicalSection)
    observaciones: ClinicalSection = Field(default_factory=ClinicalSection)


class EvolutionNote(DocumentMeta):
    """Nota de evolución de paciente ingresado (formato SOAP adaptado).

    Referencia FHIR: Composition LOINC 11506-3 (Progress note).
    """

    document_type: Literal[ConsultationType.evolution] = ConsultationType.evolution
    subjetivo: ClinicalSection = Field(default_factory=ClinicalSection)
    objetivo: ClinicalSection = Field(default_factory=ClinicalSection)
    evolucion: ClinicalSection = Field(default_factory=ClinicalSection)
    juicio_clinico: ClinicalSection = Field(default_factory=ClinicalSection)
    plan: ClinicalSection = Field(default_factory=ClinicalSection)


ClinicalDraft = AdmissionNote | TreatmentOrdersNote | EvolutionNote

_DRAFT_TYPES: dict[ConsultationType, type[BaseModel]] = {
    ConsultationType.admission_interview: AdmissionNote,
    ConsultationType.treatment_orders: TreatmentOrdersNote,
    ConsultationType.evolution: EvolutionNote,
}

_META_FIELDS = frozenset({"document_type", "generated_by_ai", "model_name", "created_at"})


def parse_clinical_draft(data: dict) -> AdmissionNote | TreatmentOrdersNote | EvolutionNote:
    """Deserializa JSON persistido al modelo tipado correcto."""
    raw_type = data.get("document_type", ConsultationType.admission_interview.value)
    doc_type = ConsultationType(raw_type)
    model_cls = _DRAFT_TYPES[doc_type]
    return model_cls.model_validate(data)  # type: ignore[return-value]


def iter_clinical_sections(
    draft: AdmissionNote | TreatmentOrdersNote | EvolutionNote,
) -> list[tuple[str, ClinicalSection]]:
    """Devuelve (nombre_campo, sección) excluyendo metadatos."""
    fields = type(draft).model_fields
    return [
        (name, getattr(draft, name))
        for name in fields
        if name not in _META_FIELDS and isinstance(getattr(draft, name), ClinicalSection)
    ]
