"""Modelos de datos. La nota clínica se diseña para mapear a FHIR."""
from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class TranscriptSegment(BaseModel):
    """Un fragmento de transcripción con etiqueta de interlocutor (diarización)."""
    speaker: str = Field(description="'medico' | 'paciente' | 'desconocido'")
    text: str
    start_ms: Optional[int] = None
    end_ms: Optional[int] = None


class Transcript(BaseModel):
    language: str = "es"
    segments: list[TranscriptSegment] = []

    @property
    def full_text(self) -> str:
        return "\n".join(f"[{s.speaker}] {s.text}" for s in self.segments)


class ClinicalSection(BaseModel):
    """Una sección de la historia. 'confirmar' marca lo que el LLM no da por seguro."""
    content: str = ""
    needs_confirmation: bool = False


class ClinicalNote(BaseModel):
    """Borrador estructurado de la historia clínica (revisable por el médico)."""
    motivo_consulta: ClinicalSection = ClinicalSection()
    anamnesis: ClinicalSection = ClinicalSection()
    exploracion: ClinicalSection = ClinicalSection()
    diagnostico: ClinicalSection = ClinicalSection()
    plan: ClinicalSection = ClinicalSection()

    # Trazabilidad / cumplimiento
    generated_by_ai: bool = True
    model_name: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)


class ConsultationStatus(str, Enum):
    capturing = "capturing"
    transcribing = "transcribing"
    structuring = "structuring"
    awaiting_review = "awaiting_review"
    validated = "validated"
    error = "error"


class ConsultationResult(BaseModel):
    consultation_id: str
    status: ConsultationStatus
    transcript: Optional[Transcript] = None
    draft: Optional[ClinicalNote] = None
