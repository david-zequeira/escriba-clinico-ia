"""LLM con Mistral (proveedor UE): salida JSON estructurada por tipo de documento."""
from __future__ import annotations

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

_VALID_SPEAKERS = {"medico", "paciente", "desconocido"}

_SPEAKER_SYSTEM_PROMPT = (
    "Eres un anotador clínico. Recibes las intervenciones de una consulta en orden. "
    "Clasifica CADA intervención como 'medico' o 'paciente' según quién la diría: "
    "el médico pregunta, explora, explica e indica; el paciente describe síntomas, "
    "antecedentes y vivencias. No inventes: si una intervención es ambigua, usa "
    "'desconocido'. Devuelve EXACTAMENTE una etiqueta por intervención, en el mismo "
    "orden, sin texto adicional."
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
        response = await self._client.chat.parse_async(
            model=self._model,
            messages=[
                {"role": "system", "content": get_system_prompt(consultation_type)},
                {"role": "user", "content": user_content},
            ],
            response_format=schema,
            temperature=0.1,
            max_tokens=4096,
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
        response = await self._client.chat.parse_async(
            model=self._model,
            messages=[
                {"role": "system", "content": _SPEAKER_SYSTEM_PROMPT},
                {"role": "user", "content": f"Intervenciones (índice: texto):\n{numbered}"},
            ],
            response_format=SpeakerLabelsDraft,
            temperature=0.0,
            max_tokens=1024,
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
