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
        """Fija el rol (médico/paciente) de cada intervención antes de estructurar.

        Solo aplica a la entrevista de ingreso (el dictado es monólogo). Dos casos:

        - **Diarización acústica limpia** (el STT distinguió ≥2 voces, sin dejar
          nadie sin identificar): NO se confía en el orden de aparición (adivina
          "quien abre = médico" y a veces invierte). Se pide al LLM que asigne el
          rol de cada voz con TODA su evidencia (`assign_cluster_roles`), lo que
          corrige inversiones y garantiza consistencia por voz.
        - **Sin separación fiable** (mono, una sola voz, segmentos neutros del
          directo): el LLM atribuye por contenido intervención a intervención.
        """
        segments = transcript.segments
        if consultation_type != ConsultationType.admission_interview:
            return transcript

        clusters = _acoustic_clusters(segments)
        has_unknown = any(s.speaker == "desconocido" for s in segments)

        if len(clusters) >= 2 and not has_unknown:
            return await self._assign_roles_by_cluster(
                transcript, clusters, consultation_type
            )

        labels = await self._llm.assign_speakers(
            [s.text for s in segments], consultation_type
        )
        return _relabel(
            transcript,
            [labels[i] if i < len(labels) else "desconocido" for i in range(len(segments))],
        )

    async def _assign_roles_by_cluster(
        self,
        transcript: Transcript,
        clusters: list[str],
        consultation_type: ConsultationType,
    ) -> Transcript:
        segments = transcript.segments
        groups = [[s.text for s in segments if s.speaker == c] for c in clusters]
        roles = await self._llm.assign_cluster_roles(groups, consultation_type)
        mapping = {
            clusters[i]: (roles[i] if i < len(roles) else "desconocido")
            for i in range(len(clusters))
        }
        # Guarda anti-degeneración: si el LLM no distingue médico y paciente
        # (p. ej. asigna el mismo rol a ambas voces), se conservan las etiquetas
        # originales del STT en vez de empeorar la diarización.
        if not {"medico", "paciente"} <= set(mapping.values()):
            return transcript
        return _relabel(transcript, [mapping.get(s.speaker, "desconocido") for s in segments])


def _acoustic_clusters(segments: list[TranscriptSegment]) -> list[str]:
    """Voces distintas que trajo el STT, en orden de aparición (sin 'desconocido')."""
    clusters: list[str] = []
    for s in segments:
        if s.speaker != "desconocido" and s.speaker not in clusters:
            clusters.append(s.speaker)
    return clusters


def _relabel(transcript: Transcript, labels: list[str]) -> Transcript:
    relabeled = [
        TranscriptSegment(
            speaker=labels[i] if i < len(labels) else "desconocido",
            text=s.text,
            start_ms=s.start_ms,
            end_ms=s.end_ms,
        )
        for i, s in enumerate(transcript.segments)
    ]
    return Transcript(language=transcript.language, segments=relabeled)
