"""Implementación LLM con Mistral (proveedor UE, postura RGPD más limpia).

STUB: sustituir por el SDK real de Mistral. Usar salida estructurada (JSON schema)
para forzar campos mapeables a FHIR. Prompt anti-alucinación incluido abajo.
"""
from app.config import settings
from app.models.schemas import ClinicalNote, ClinicalSection, Transcript
from app.services.llm.base import LLMProvider

SYSTEM_PROMPT = (
    "Eres un asistente de documentación clínica. A partir de la transcripción de una "
    "consulta, redacta un borrador de historia clínica en español, estructurado en: "
    "motivo de consulta, anamnesis, exploración, diagnóstico y plan. "
    "Reglas estrictas: no inventes datos que no aparezcan en la transcripción; "
    "marca como pendiente de confirmar cualquier dato dudoso; no tomes decisiones "
    "diagnósticas ni terapéuticas: solo redactas un borrador que el médico revisará."
)


class MistralLLM(LLMProvider):
    name = "mistral"

    def __init__(self) -> None:
        self.api_key = settings.LLM_API_KEY
        self.model = settings.LLM_MODEL
        # TODO: inicializar cliente real (endpoint UE).

    async def structure_note(
        self, transcript: Transcript, specialty: str = "general"
    ) -> ClinicalNote:
        # TODO: llamar a Mistral con SYSTEM_PROMPT + transcript.full_text
        #       y response_format de tipo JSON acorde a ClinicalNote.
        # Resultado simulado para validar el flujo de extremo a extremo:
        return ClinicalNote(
            motivo_consulta=ClinicalSection(content="(pendiente de la integración real)"),
            model_name=self.model,
        )
