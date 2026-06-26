"""Caso de uso central: orquestación asíncrona STT -> LLM. Lo ejecuta el worker.

Persiste el estado en cada paso para que GET /status refleje el progreso real.
"""
from __future__ import annotations

from uuid import UUID

from app.core.audit import log_event
from app.core.config import settings
from app.domain.exceptions import AudioNotAvailable, ConsultationNotFound
from app.domain.ports import (
    AudioStorage,
    ConsultationRepository,
    LLMProvider,
    STTProvider,
)


class ProcessConsultationUseCase:
    def __init__(
        self,
        repo: ConsultationRepository,
        stt: STTProvider,
        llm: LLMProvider,
        storage: AudioStorage,
    ) -> None:
        self._repo = repo
        self._stt = stt
        self._llm = llm
        self._storage = storage

    async def execute(self, consultation_id: UUID) -> None:
        consultation = await self._repo.get(consultation_id)
        if consultation is None:
            raise ConsultationNotFound(str(consultation_id))

        try:
            if not consultation.audio_path:
                raise AudioNotAvailable(str(consultation_id))

            # 1) Transcripción (STT)
            consultation.mark_processing_stt()
            await self._repo.update(consultation)

            audio_bytes = await self._storage.read(consultation.audio_path)
            transcript = await self._stt.transcribe(
                audio_bytes,
                language=settings.STT_LANGUAGE,
                consultation_type=consultation.consultation_type,
            )
            consultation.set_transcript(transcript)

            # 2) Minimización del audio (RGPD): se descarta tras transcribir.
            if settings.DELETE_AUDIO_AFTER_TRANSCRIPTION:
                await self._storage.delete(consultation.audio_path)
                consultation.discard_audio()
            del audio_bytes

            # 3) Estructuración (LLM)
            consultation.mark_processing_llm()
            await self._repo.update(consultation)

            draft = await self._llm.structure_note(
                transcript, consultation_type=consultation.consultation_type
            )
            consultation.complete(draft)
            await self._repo.update(consultation)

            log_event(consultation.doctor_id, "draft_generated", str(consultation_id))

        except Exception as exc:  # noqa: BLE001 - el worker no debe propagar y dejar estado inconsistente
            consultation.fail(str(exc))
            await self._repo.update(consultation)
            log_event(consultation.doctor_id, "processing_failed", str(consultation_id), str(exc))
