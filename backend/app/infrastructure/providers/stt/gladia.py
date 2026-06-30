"""STT con Gladia (Francia, UE): transcripción async con diarización médico/paciente.

Requiere STT_API_KEY (clave Gladia). En free tier el audio puede usarse para entrenamiento;
para datos reales de pacientes usar plan de pago con DPA y opt-out.
"""
from __future__ import annotations

import asyncio
import time
from typing import Any

import httpx

from app.core.config import settings
from app.domain.enums import ConsultationType
from app.domain.ports import STTProvider
from app.domain.value_objects import Transcript, TranscriptSegment

_API_BASE = "https://api.gladia.io"

# Gladia devuelve índices 0/1; en consultas médicas el médico suele hablar primero.
_SPEAKER_LABELS = ("medico", "paciente")


class GladiaSTTProvider(STTProvider):
    name = "gladia"

    def __init__(self) -> None:
        if not settings.STT_API_KEY:
            raise ValueError("STT_API_KEY es obligatoria para Gladia")

    async def transcribe(
        self,
        audio_bytes: bytes,
        language: str = "es",
        consultation_type: ConsultationType = ConsultationType.admission_interview,
    ) -> Transcript:
        timeout = httpx.Timeout(60.0, read=settings.GLADIA_POLL_TIMEOUT_SEC)
        async with httpx.AsyncClient(timeout=timeout) as client:
            audio_url = await self._upload(client, audio_bytes)
            job_id = await self._start_job(client, audio_url, language, consultation_type)
            payload = await self._poll_job(client, job_id)
        return _map_transcript(payload, language, consultation_type)

    async def _upload(self, client: httpx.AsyncClient, audio_bytes: bytes) -> str:
        response = await client.post(
            f"{_API_BASE}/v2/upload",
            headers={"x-gladia-key": settings.STT_API_KEY},
            files={"audio": ("consultation.wav", audio_bytes, "application/octet-stream")},
        )
        response.raise_for_status()
        return response.json()["audio_url"]

    async def _start_job(
        self,
        client: httpx.AsyncClient,
        audio_url: str,
        language: str,
        consultation_type: ConsultationType,
    ) -> str:
        body: dict[str, Any] = {
            "audio_url": audio_url,
            "model": settings.GLADIA_MODEL,
            "language_config": {"languages": [_gladia_language(language)]},
            "diarization": True,
            "diarization_config": _diarization_config(consultation_type),
        }
        response = await client.post(
            f"{_API_BASE}/v2/pre-recorded",
            headers={
                "x-gladia-key": settings.STT_API_KEY,
                "Content-Type": "application/json",
            },
            json=body,
        )
        response.raise_for_status()
        return response.json()["id"]

    async def _poll_job(self, client: httpx.AsyncClient, job_id: str) -> dict[str, Any]:
        deadline = time.monotonic() + settings.GLADIA_POLL_TIMEOUT_SEC
        headers = {"x-gladia-key": settings.STT_API_KEY}

        while time.monotonic() < deadline:
            response = await client.get(f"{_API_BASE}/v2/pre-recorded/{job_id}", headers=headers)
            response.raise_for_status()
            payload = response.json()
            status = payload.get("status")

            if status == "done":
                result = payload.get("result")
                if not result:
                    raise RuntimeError("Gladia devolvió status=done sin resultado")
                return result
            if status == "error":
                detail = payload.get("error") or payload.get("error_code") or "error desconocido"
                raise RuntimeError(f"Gladia STT falló: {detail}")

            await asyncio.sleep(settings.GLADIA_POLL_INTERVAL_SEC)

        raise TimeoutError(
            f"Gladia STT no terminó en {settings.GLADIA_POLL_TIMEOUT_SEC:.0f}s"
        )


def _diarization_config(consultation_type: ConsultationType) -> dict[str, int]:
    if consultation_type == ConsultationType.admission_interview:
        return {"number_of_speakers": 2, "min_speakers": 2, "max_speakers": 2}
    return {"min_speakers": 1, "max_speakers": 2}


def _gladia_language(language: str) -> str:
    """Gladia solaria-3 usa códigos ISO de dos letras (es, fr, en...)."""
    return language.split("-")[0].lower()


def _map_speaker(
    speaker_index: int | None, consultation_type: ConsultationType
) -> str:
    if consultation_type != ConsultationType.admission_interview:
        return "medico"
    if speaker_index is None:
        return "desconocido"
    if 0 <= speaker_index < len(_SPEAKER_LABELS):
        return _SPEAKER_LABELS[speaker_index]
    return "desconocido"


def _map_transcript(
    result: dict[str, Any], language: str, consultation_type: ConsultationType
) -> Transcript:
    transcription = result.get("transcription") or {}
    utterances: list[dict[str, Any]] = transcription.get("utterances") or []

    segments: list[TranscriptSegment] = []
    for utterance in utterances:
        text = (utterance.get("text") or "").strip()
        if not text:
            continue
        start = utterance.get("start")
        end = utterance.get("end")
        segments.append(
            TranscriptSegment(
                speaker=_map_speaker(utterance.get("speaker"), consultation_type),
                text=text,
                start_ms=int(start * 1000) if start is not None else None,
                end_ms=int(end * 1000) if end is not None else None,
            )
        )

    if not segments:
        full_text = (transcription.get("full_transcript") or "").strip()
        if full_text:
            segments.append(
                TranscriptSegment(
                    speaker="medico"
                    if consultation_type != ConsultationType.admission_interview
                    else "desconocido",
                    text=full_text,
                )
            )

    return Transcript(language=language, segments=segments)
