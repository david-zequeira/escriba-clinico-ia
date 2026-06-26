"""Puertos (interfaces) del dominio. La infraestructura los implementa.

Regla de dependencias: el dominio/aplicación dependen de estos contratos,
NUNCA de proveedores concretos. Así STT, LLM, BD o cola son intercambiables.
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from uuid import UUID

from app.domain.entities import Consultation
from app.domain.enums import ConsultationType
from app.domain.clinical_documents import ClinicalDraft
from app.domain.enums import ConsultationType
from app.domain.value_objects import Transcript


class ConsultationRepository(ABC):
    """Persistencia del agregado Consultation."""

    @abstractmethod
    async def add(self, consultation: Consultation) -> Consultation: ...

    @abstractmethod
    async def get(self, consultation_id: UUID) -> Consultation | None: ...

    @abstractmethod
    async def update(self, consultation: Consultation) -> Consultation: ...


class STTProvider(ABC):
    """Motor de voz a texto con diarización médico/paciente."""

    name: str = "base"

    @abstractmethod
    async def transcribe(
        self,
        audio_bytes: bytes,
        language: str = "es",
        consultation_type: ConsultationType = ConsultationType.admission_interview,
    ) -> Transcript: ...


class LLMProvider(ABC):
    """Estructura una transcripción en historia clínica (solo borrador, sin decisión clínica)."""

    name: str = "base"

    @abstractmethod
    async def structure_note(
        self,
        transcript: Transcript,
        consultation_type: ConsultationType = ConsultationType.admission_interview,
        specialty: str = "general",
    ) -> ClinicalDraft: ...


class AudioStorage(ABC):
    """Almacenamiento del archivo de audio (no persistente por defecto)."""

    @abstractmethod
    async def save(self, consultation_id: UUID, filename: str, data: bytes) -> str: ...

    @abstractmethod
    async def read(self, path: str) -> bytes: ...

    @abstractmethod
    async def delete(self, path: str) -> None: ...


class JobQueue(ABC):
    """Cola de trabajos: desacopla el procesamiento IA del request HTTP."""

    @abstractmethod
    async def enqueue_processing(self, consultation_id: UUID) -> None: ...
