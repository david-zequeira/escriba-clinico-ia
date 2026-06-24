"""Interfaz de estructuración con LLM. Implementa por proveedor (Mistral, Azure OpenAI UE, self-hosted)."""
from abc import ABC, abstractmethod

from app.models.schemas import ClinicalNote, Transcript


class LLMProvider(ABC):
    """Contrato común para convertir una transcripción en historia clínica estructurada."""

    name: str = "base"

    @abstractmethod
    async def structure_note(
        self, transcript: Transcript, specialty: str = "general"
    ) -> ClinicalNote:
        """Genera el borrador estructurado a partir de la transcripción."""
        raise NotImplementedError
