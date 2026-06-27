"""Caso de uso: generar el borrador a partir de una transcripción ya disponible.

Es la otra mitad de F2: la transcripción la produjo el WebSocket en vivo, así que
NO se vuelve a llamar al STT — solo se estructura con el LLM. Espeja el tramo
LLM de `ProcessConsultationUseCase`, pero sin audio ni transcripción batch.
"""
from __future__ import annotations

from uuid import UUID

from app.core.audit import log_event
from app.domain.exceptions import ConsultationNotFound
from app.domain.ports import ConsultationRepository, LLMProvider
from app.domain.value_objects import Transcript


class DraftFromTranscriptUseCase:
    def __init__(self, repo: ConsultationRepository, llm: LLMProvider) -> None:
        self._repo = repo
        self._llm = llm

    async def execute(self, consultation_id: UUID, transcript: Transcript) -> None:
        consultation = await self._repo.get(consultation_id)
        if consultation is None:
            raise ConsultationNotFound(str(consultation_id))

        try:
            # Sin transcripción no hay nada que estructurar: fallo explícito para
            # que el cliente no quede esperando indefinidamente.
            if not transcript.segments:
                raise ValueError("La transcripción del stream está vacía")

            consultation.set_transcript(transcript)
            consultation.mark_processing_llm()
            await self._repo.update(consultation)

            draft = await self._llm.structure_note(
                transcript, consultation_type=consultation.consultation_type
            )
            consultation.complete(draft)
            await self._repo.update(consultation)

            log_event(
                consultation.doctor_id,
                "draft_generated_from_stream",
                str(consultation_id),
            )
        except Exception as exc:  # noqa: BLE001 - no propagar: dejar estado coherente
            consultation.fail(str(exc))
            await self._repo.update(consultation)
            log_event(
                consultation.doctor_id,
                "draft_from_stream_failed",
                str(consultation_id),
                str(exc),
            )
