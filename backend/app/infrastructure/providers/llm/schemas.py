"""Esquemas Pydantic para salida estructurada del LLM (sin metadatos del servidor)."""
from __future__ import annotations

from pydantic import BaseModel, Field

from app.domain.value_objects import ClinicalSection


class AdmissionNoteDraft(BaseModel):
    motivo_ingreso: ClinicalSection = Field(default_factory=ClinicalSection)
    enfermedad_actual: ClinicalSection = Field(default_factory=ClinicalSection)
    antecedentes: ClinicalSection = Field(default_factory=ClinicalSection)
    exploracion_fisica: ClinicalSection = Field(default_factory=ClinicalSection)
    pruebas_complementarias: ClinicalSection = Field(default_factory=ClinicalSection)
    juicio_clinico: ClinicalSection = Field(default_factory=ClinicalSection)
    plan: ClinicalSection = Field(default_factory=ClinicalSection)


class TreatmentOrdersNoteDraft(BaseModel):
    contexto: ClinicalSection = Field(default_factory=ClinicalSection)
    indicaciones_farmacologicas: ClinicalSection = Field(default_factory=ClinicalSection)
    indicaciones_no_farmacologicas: ClinicalSection = Field(default_factory=ClinicalSection)
    vigilancia: ClinicalSection = Field(default_factory=ClinicalSection)
    observaciones: ClinicalSection = Field(default_factory=ClinicalSection)


class EvolutionNoteDraft(BaseModel):
    subjetivo: ClinicalSection = Field(default_factory=ClinicalSection)
    objetivo: ClinicalSection = Field(default_factory=ClinicalSection)
    evolucion: ClinicalSection = Field(default_factory=ClinicalSection)
    juicio_clinico: ClinicalSection = Field(default_factory=ClinicalSection)
    plan: ClinicalSection = Field(default_factory=ClinicalSection)


class SpeakerLabelsDraft(BaseModel):
    """Una etiqueta de interlocutor por intervención, en el mismo orden recibido."""

    speakers: list[str] = Field(
        default_factory=list,
        description="'medico' | 'paciente' | 'desconocido' por cada intervención.",
    )
