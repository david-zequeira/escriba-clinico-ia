"""LLM con Mistral (proveedor UE): salida JSON estructurada por tipo de documento."""
from __future__ import annotations

import json
import logging
from collections.abc import Awaitable, Callable
from typing import TypeVar

from mistralai.client import Mistral

from app.core.config import settings
from app.domain.clinical_documents import (
    AdmissionNote,
    ClinicalDraft,
    EvolutionNote,
    TreatmentOrdersNote,
)
from app.domain.enums import ConsultationType
from app.domain.ports import LLMProvider
from app.domain.value_objects import Transcript
from app.infrastructure.providers.llm.prompts import get_system_prompt
from app.infrastructure.providers.llm.schemas import (
    AdmissionNoteDraft,
    EvolutionNoteDraft,
    SpeakerLabelsDraft,
    TreatmentOrdersNoteDraft,
)

logger = logging.getLogger("app.llm.mistral")

_T = TypeVar("_T")

_VALID_SPEAKERS = {"medico", "paciente", "desconocido"}


async def _parse_with_retry(
    call: Callable[[], Awaitable[_T]], *, attempts: int = 2
) -> _T:
    """Reintenta una llamada al LLM si devuelve JSON inválido.

    Los modelos a veces emiten JSON malformado de forma puntual (`JSONDecodeError`);
    un reintento lo resuelve sin cambiar de modelo. `call` crea la corutina cada vez.
    """
    last_exc: json.JSONDecodeError | None = None
    for attempt in range(attempts):
        try:
            return await call()
        except json.JSONDecodeError as exc:
            last_exc = exc
            logger.warning(
                "Mistral devolvió JSON inválido (intento %d/%d)", attempt + 1, attempts
            )
    assert last_exc is not None
    raise last_exc

_SPEAKER_SYSTEM_PROMPT = (
    "Eres un anotador clínico. Recibes, en orden, las intervenciones de una "
    "consulta entre un médico y un paciente. Clasifica CADA intervención como "
    "'medico' o 'paciente' razonando por su CONTENIDO y el contexto de la "
    "conversación, NO por alternancia estricta: un mismo interlocutor puede hablar "
    "en varios turnos seguidos.\n"
    "Pistas:\n"
    "- El médico pregunta por síntomas, explora, explica, indica pruebas o "
    "tratamiento, y suele tratar de 'usted' al paciente.\n"
    "- El paciente describe sus síntomas, antecedentes y vivencias en primera "
    "persona.\n"
    "- Si quien habla SE DIRIGE al otro como 'doctor', 'doctora' o 'médico' "
    "(p. ej. '¿qué tal, doctor?'), esa intervención es del PACIENTE.\n"
    "- Los saludos y aperturas suelen ser del médico, pero decide por el contenido.\n"
    "Si una intervención es genuinamente ambigua, usa 'desconocido'; no inventes. "
    "Devuelve EXACTAMENTE una etiqueta por intervención, en el mismo orden, sin "
    "texto adicional."
)

_CLUSTER_ROLE_SYSTEM_PROMPT = (
    "Recibes las intervenciones de una consulta médica YA agrupadas por "
    "interlocutor: cada grupo corresponde a UNA sola voz (la diarización acústica "
    "ya separó a los hablantes). Tu tarea es decidir, para CADA grupo, si esa voz "
    "es la del 'medico' o la del 'paciente', razonando por el CONTENIDO de todo lo "
    "que dice ese interlocutor.\n"
    "Pistas:\n"
    "- El médico pregunta por síntomas, explora, explica, indica pruebas o "
    "tratamiento, y suele tratar de 'usted'.\n"
    "- El paciente describe sus síntomas, antecedentes y vivencias en primera "
    "persona.\n"
    "- En una entrevista de ingreso hay exactamente un médico y un paciente: no "
    "asignes el mismo rol a dos grupos.\n"
    "Si un grupo es genuinamente ambiguo, usa 'desconocido'; no inventes. Devuelve "
    "EXACTAMENTE una etiqueta por grupo, en el mismo orden recibido, sin texto "
    "adicional."
)

_DRAFT_SCHEMA: dict[ConsultationType, type] = {
    ConsultationType.admission_interview: AdmissionNoteDraft,
    ConsultationType.treatment_orders: TreatmentOrdersNoteDraft,
    ConsultationType.evolution: EvolutionNoteDraft,
}


class MistralLLMProvider(LLMProvider):
    name = "mistral"

    def __init__(self) -> None:
        if not settings.LLM_API_KEY:
            raise ValueError("LLM_API_KEY es obligatoria para Mistral")
        self._client = Mistral(api_key=settings.LLM_API_KEY)
        self._model = settings.LLM_MODEL

    async def structure_note(
        self,
        transcript: Transcript,
        consultation_type: ConsultationType = ConsultationType.admission_interview,
        specialty: str = "general",
    ) -> ClinicalDraft:
        schema = _DRAFT_SCHEMA[consultation_type]
        user_content = (
            f"Tipo de documento: {consultation_type.value}\n"
            f"Especialidad: {specialty}\n\n"
            f"Transcripción:\n\n{transcript.full_text}"
        )
        response = await _parse_with_retry(
            lambda: self._client.chat.parse_async(
                model=self._model,
                messages=[
                    {"role": "system", "content": get_system_prompt(consultation_type)},
                    {"role": "user", "content": user_content},
                ],
                response_format=schema,
                temperature=0.1,
                max_tokens=8192,
            )
        )
        draft = response.choices[0].message.parsed
        if draft is None:
            raise RuntimeError("Mistral no devolvió un borrador estructurado")

        return _to_clinical_draft(draft, consultation_type, self._model)

    async def assign_speakers(
        self,
        texts: list[str],
        consultation_type: ConsultationType = ConsultationType.admission_interview,
    ) -> list[str]:
        if not texts:
            return []
        numbered = "\n".join(f"{i}: {text}" for i, text in enumerate(texts))
        response = await _parse_with_retry(
            lambda: self._client.chat.parse_async(
                model=self._model,
                messages=[
                    {"role": "system", "content": _SPEAKER_SYSTEM_PROMPT},
                    {"role": "user", "content": f"Intervenciones (índice: texto):\n{numbered}"},
                ],
                response_format=SpeakerLabelsDraft,
                temperature=0.0,
                # Una etiqueta por intervención: en consultas largas hay cientos de
                # segmentos, así que el margen debe ser amplio (evita truncar el JSON).
                max_tokens=8192,
            )
        )
        parsed = response.choices[0].message.parsed
        labels = parsed.speakers if parsed is not None else []
        # Normaliza longitud y valores: nunca menos etiquetas que intervenciones,
        # y cualquier valor inesperado → 'desconocido' (no se inventa interlocutor).
        out: list[str] = []
        for i in range(len(texts)):
            value = labels[i].strip().lower() if i < len(labels) else "desconocido"
            out.append(value if value in _VALID_SPEAKERS else "desconocido")
        return out

    async def assign_cluster_roles(
        self,
        clusters: list[list[str]],
        consultation_type: ConsultationType = ConsultationType.admission_interview,
    ) -> list[str]:
        if not clusters:
            return []
        # Cada grupo es una sola voz: se presenta su texto agregado como evidencia.
        blocks = []
        for i, texts in enumerate(clusters):
            joined = " ".join(t.strip() for t in texts if t.strip())
            blocks.append(f"Grupo {i} (una sola voz):\n{joined}")
        numbered = "\n\n".join(blocks)
        response = await _parse_with_retry(
            lambda: self._client.chat.parse_async(
                model=self._model,
                messages=[
                    {"role": "system", "content": _CLUSTER_ROLE_SYSTEM_PROMPT},
                    {"role": "user", "content": f"Interlocutores a clasificar:\n\n{numbered}"},
                ],
                response_format=SpeakerLabelsDraft,
                temperature=0.0,
                max_tokens=512,
            )
        )
        parsed = response.choices[0].message.parsed
        labels = parsed.speakers if parsed is not None else []
        out: list[str] = []
        for i in range(len(clusters)):
            value = labels[i].strip().lower() if i < len(labels) else "desconocido"
            out.append(value if value in _VALID_SPEAKERS else "desconocido")
        return out


def _to_clinical_draft(
    draft: AdmissionNoteDraft | TreatmentOrdersNoteDraft | EvolutionNoteDraft,
    consultation_type: ConsultationType,
    model_name: str,
) -> ClinicalDraft:
    common = {"generated_by_ai": True, "model_name": model_name}
    if consultation_type == ConsultationType.admission_interview:
        assert isinstance(draft, AdmissionNoteDraft)
        return AdmissionNote(**draft.model_dump(), **common)
    if consultation_type == ConsultationType.treatment_orders:
        assert isinstance(draft, TreatmentOrdersNoteDraft)
        return TreatmentOrdersNote(**draft.model_dump(), **common)
    assert isinstance(draft, EvolutionNoteDraft)
    return EvolutionNote(**draft.model_dump(), **common)
