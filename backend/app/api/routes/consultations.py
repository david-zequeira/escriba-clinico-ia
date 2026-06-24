"""Endpoints de consulta: subir audio, recibir borrador, validar y volcar a FHIR."""
import uuid

from fastapi import APIRouter, Depends, UploadFile

from app.core.audit import log_event
from app.core.security import get_current_user
from app.models.schemas import ClinicalNote, ConsultationResult
from app.pipeline.orchestrator import run_pipeline
from app.services.fhir.mapper import note_to_fhir

router = APIRouter(prefix="/consultations", tags=["consultations"])


@router.post("", response_model=ConsultationResult)
async def create_consultation(
    audio: UploadFile,
    specialty: str = "general",
    user: dict = Depends(get_current_user),
) -> ConsultationResult:
    consultation_id = str(uuid.uuid4())
    audio_bytes = await audio.read()
    log_event(user["practitioner_id"], "upload_audio", consultation_id)
    result = await run_pipeline(consultation_id, audio_bytes, specialty)
    log_event(user["practitioner_id"], "draft_generated", consultation_id)
    return result


@router.post("/{consultation_id}/validate")
async def validate_consultation(
    consultation_id: str,
    note: ClinicalNote,
    patient_id: str,
    user: dict = Depends(get_current_user),
) -> dict:
    """El médico envía la nota revisada; se construye el recurso FHIR para el HIS."""
    bundle = note_to_fhir(note, patient_id, user["practitioner_id"])
    log_event(user["practitioner_id"], "validate_note", consultation_id)
    # TODO: escribir `bundle` en el HIS del hospital vía conector FHIR.
    return {"status": "validated", "fhir": bundle}
