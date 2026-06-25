"""Objetos de valor del dominio: transcripción y sección clínica."""
from __future__ import annotations

from pydantic import BaseModel, Field


class TranscriptSegment(BaseModel):
    """Fragmento de transcripción con diarización (médico / paciente)."""

    speaker: str = Field(description="'medico' | 'paciente' | 'desconocido'")
    text: str
    start_ms: int | None = None
    end_ms: int | None = None


class Transcript(BaseModel):
    language: str = "es"
    segments: list[TranscriptSegment] = Field(default_factory=list)

    @property
    def full_text(self) -> str:
        return "\n".join(f"[{s.speaker}] {s.text}" for s in self.segments)


class ClinicalSection(BaseModel):
    """Sección de la historia. `needs_confirmation` marca lo que el LLM no da por seguro."""

    content: str = ""
    needs_confirmation: bool = False
