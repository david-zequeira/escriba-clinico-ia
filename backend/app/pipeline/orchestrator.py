"""Orquesta el flujo: audio -> STT -> LLM -> borrador. El audio se descarta tras transcribir."""
from app.models.schemas import ConsultationResult, ConsultationStatus
from app.services.llm import get_llm_provider
from app.services.stt import get_stt_provider


async def run_pipeline(
    consultation_id: str, audio_bytes: bytes, specialty: str = "general"
) -> ConsultationResult:
    stt = get_stt_provider()
    llm = get_llm_provider()

    # 1) Transcripción
    transcript = await stt.transcribe(audio_bytes, language="es")

    # 2) El audio ya no se necesita: minimización de datos (RGPD)
    del audio_bytes

    # 3) Estructuración en historia clínica
    draft = await llm.structure_note(transcript, specialty=specialty)

    return ConsultationResult(
        consultation_id=consultation_id,
        status=ConsultationStatus.awaiting_review,
        transcript=transcript,
        draft=draft,
    )
