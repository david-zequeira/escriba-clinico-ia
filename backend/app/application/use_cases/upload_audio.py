"""Caso de uso: subir audio y encolar el procesamiento. NUNCA llama a la IA aquí."""
from __future__ import annotations

from uuid import UUID

from app.core.audit import log_event
from app.domain.entities import Consultation
from app.domain.exceptions import ConsultationNotFound
from app.domain.ports import AudioStorage, ConsultationRepository, JobQueue


class UploadAudioUseCase:
    def __init__(
        self,
        repo: ConsultationRepository,
        storage: AudioStorage,
        queue: JobQueue,
    ) -> None:
        self._repo = repo
        self._storage = storage
        self._queue = queue

    async def execute(
        self, consultation_id: UUID, filename: str, data: bytes
    ) -> Consultation:
        consultation = await self._repo.get(consultation_id)
        if consultation is None:
            raise ConsultationNotFound(str(consultation_id))

        path = await self._storage.save(consultation_id, filename, data)
        consultation.attach_audio(path)  # -> estado queued
        await self._repo.update(consultation)

        log_event(consultation.doctor_id, "upload_audio", str(consultation_id))

        # Procesamiento IA desacoplado: se ejecuta en el worker, no en el request.
        await self._queue.enqueue_processing(consultation_id)
        return consultation
