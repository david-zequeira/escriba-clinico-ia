"""Caso de uso: generar el borrador a partir de una transcripción ya disponible.

Es la otra mitad de F2: la transcripción la produjo el WebSocket en vivo, así que
NO se vuelve a llamar al STT — solo se estructura con el LLM. Espeja el tramo
LLM de `ProcessConsultationUseCase`, pero sin audio ni transcripción batch.
"""
from __future__ import annotations

from uuid import UUID

from app.core.audit import log_event
from app.domain.enums import ConsultationType
from app.domain.exceptions import ConsultationNotFound
from app.domain.ports import ConsultationRepository, LLMProvider
from app.domain.value_objects import Transcript, TranscriptSegment


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

            # Diarización por LLM: el STT en streaming (mono) no separa
            # interlocutores y los marca 'desconocido'. Si es el caso, pedimos al
            # LLM que atribuya médico/paciente por contenido antes de estructurar.
            transcript = await self._assign_speakers_if_needed(
                transcript, consultation.consultation_type
            )

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

    async def _assign_speakers_if_needed(
        self, transcript: Transcript, consultation_type: ConsultationType
    ) -> Transcript:
        """Atribuye médico/paciente con el LLM cuando el STT no separó a los dos
        interlocutores.

        Solo aplica a la entrevista de ingreso (el dictado es monólogo). Si el STT
        ya distinguió ≥2 hablantes (multicanal o diarización acústica real) se
        respeta; el médico corrige en la revisión si quedaron invertidos. Pero si
        todo cayó en un único interlocutor (mono sin diarización, o una sola voz),
        pedimos al LLM que los atribuya por contenido.
        """
        segments = transcript.segments
        if consultation_type != ConsultationType.admission_interview:
            return transcript
        real_roles = {s.speaker for s in segments} - {"desconocido"}
        has_unknown = any(s.speaker == "desconocido" for s in segments)
        # El STT separó limpiamente solo si distinguió a médico y paciente sin
        # dejar ningún segmento sin identificar. En cualquier otro caso (una sola
        # voz, segmentos neutros de la previsualización en vivo…) el LLM atribuye.
        if len(real_roles) >= 2 and not has_unknown:
            return transcript

        labels = await self._llm.assign_speakers(
            [s.text for s in segments], consultation_type
        )
        relabeled = [
            TranscriptSegment(
                speaker=labels[i] if i < len(labels) else "desconocido",
                text=s.text,
                start_ms=s.start_ms,
                end_ms=s.end_ms,
            )
            for i, s in enumerate(segments)
        ]
        return Transcript(language=transcript.language, segments=relabeled)
