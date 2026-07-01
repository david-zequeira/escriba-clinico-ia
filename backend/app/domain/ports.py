"""Puertos (interfaces) del dominio. La infraestructura los implementa.

Regla de dependencias: el dominio/aplicación dependen de estos contratos,
NUNCA de proveedores concretos. Así STT, LLM, BD o cola son intercambiables.
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from collections.abc import AsyncIterator
from uuid import UUID

from app.domain.entities import Consultation
from app.domain.enums import ConsultationType
from app.domain.clinical_documents import ClinicalDraft
from app.domain.enums import ConsultationType
from app.domain.streaming import TranscriptionEvent
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


class RealtimeTranscriptionSession(ABC):
    """Sesión de transcripción en vivo (F2): se le empuja audio y emite eventos.

    El audio fluye en tránsito y se descarta; no se persiste (minimización §7).
    Se cierra con `close()` (idempotente) al terminar la consulta o desconectar.
    """

    @abstractmethod
    def events(self) -> AsyncIterator[TranscriptionEvent]:
        """Stream de eventos (partial/final/error/closed) hacia el cliente."""
        ...

    @abstractmethod
    async def push_audio(self, chunk: bytes) -> None:
        """Entrega un chunk de audio (PCM 16-bit, 16 kHz, mono) al motor STT."""
        ...

    @abstractmethod
    async def pause(self) -> None: ...

    @abstractmethod
    async def resume(self) -> None: ...

    @abstractmethod
    async def close(self) -> None: ...


class RealtimeSTTProvider(ABC):
    """Motor de voz a texto en streaming. Intercambiable (mock | gladia | speechmatics).

    Separado de `STTProvider` (batch) a propósito: no todo proveedor batch sabe
    hacer streaming, y así no obligamos a implementarlo a los que solo transcriben
    audio completo.
    """

    name: str = "base"

    @abstractmethod
    async def open(
        self,
        *,
        language: str = "es",
        consultation_type: ConsultationType = ConsultationType.admission_interview,
    ) -> RealtimeTranscriptionSession:
        """Abre una sesión de transcripción en vivo lista para recibir audio."""
        ...


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

    @abstractmethod
    async def assign_speakers(
        self,
        texts: list[str],
        consultation_type: ConsultationType = ConsultationType.admission_interview,
    ) -> list[str]:
        """Atribuye interlocutor ('medico'|'paciente'|'desconocido') a cada
        intervención, en orden. Para diarizar cuando el STT no lo hace (mono).
        No inventa: ante la duda, 'desconocido'."""
        ...

    @abstractmethod
    async def assign_cluster_roles(
        self,
        clusters: list[list[str]],
        consultation_type: ConsultationType = ConsultationType.admission_interview,
    ) -> list[str]:
        """Asigna el rol de CADA voz ya separada por diarización acústica.

        Recibe N grupos de intervenciones (cada grupo = una sola voz, según el
        STT) y devuelve un rol por grupo, en orden. A diferencia de
        `assign_speakers`, decide con TODA la evidencia de cada voz (más robusto y
        consistente: nunca deja una misma voz medio invertida). Ante la duda,
        'desconocido'; no fuerza un rol."""
        ...


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
