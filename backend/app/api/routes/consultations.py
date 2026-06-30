"""Endpoints de consulta. Solo HTTP: validan, delegan en casos de uso y serializan.

NUNCA se llama a la IA dentro de estos handlers: el procesamiento va al worker.
"""
from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, UploadFile, status

from app.api.deps import QueueDep, RepositoryDep, StorageDep
from app.api.schemas import (
    AudioUploadResponse,
    ConsultationResponse,
    ConsultationStatusResponse,
    CreateConsultationRequest,
    ValidateConsultationRequest,
    ValidateConsultationResponse,
)
from app.application.use_cases.create_consultation import CreateConsultationUseCase
from app.application.use_cases.get_consultation import GetConsultationUseCase
from app.application.use_cases.upload_audio import UploadAudioUseCase
from app.application.use_cases.validate_consultation import ValidateConsultationUseCase
from app.core.security import CurrentUser, get_current_user
from app.domain.exceptions import (
    ConsultationNotFound,
    DomainError,
    InvalidStateTransition,
)

router = APIRouter(prefix="/consultations", tags=["consultations"])

# Audio de hasta ~30 min: límite defensivo de tamaño (ajustar según códec).
MAX_AUDIO_BYTES = 200 * 1024 * 1024


@router.post("", response_model=ConsultationResponse, status_code=status.HTTP_201_CREATED)
async def create_consultation(
    body: CreateConsultationRequest,
    repo: RepositoryDep,
    user: CurrentUser = Depends(get_current_user),
) -> ConsultationResponse:
    use_case = CreateConsultationUseCase(repo)
    consultation = await use_case.execute(
        doctor_id=body.doctor_id or user.doctor_id,
        patient_id=body.patient_id,
        consultation_type=body.consultation_type,
    )
    return ConsultationResponse.from_entity(consultation)


@router.post(
    "/{consultation_id}/audio",
    response_model=AudioUploadResponse,
    status_code=status.HTTP_202_ACCEPTED,
)
async def upload_audio(
    consultation_id: UUID,
    audio: UploadFile,
    repo: RepositoryDep,
    storage: StorageDep,
    queue: QueueDep,
    user: CurrentUser = Depends(get_current_user),
) -> AudioUploadResponse:
    data = await audio.read()
    if not data:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Audio vacío")
    if len(data) > MAX_AUDIO_BYTES:
        raise HTTPException(status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, "Audio demasiado grande")

    use_case = UploadAudioUseCase(repo, storage, queue)
    try:
        consultation = await use_case.execute(
            consultation_id, audio.filename or "audio.bin", data
        )
    except ConsultationNotFound:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Consulta no encontrada")
    except InvalidStateTransition as exc:
        raise HTTPException(status.HTTP_409_CONFLICT, str(exc))

    return AudioUploadResponse(
        id=consultation.id,
        consultation_type=consultation.consultation_type,
        status=consultation.status,
    )


@router.get("/{consultation_id}/status", response_model=ConsultationStatusResponse)
async def get_status(
    consultation_id: UUID,
    repo: RepositoryDep,
    user: CurrentUser = Depends(get_current_user),
) -> ConsultationStatusResponse:
    try:
        consultation = await GetConsultationUseCase(repo).execute(consultation_id)
    except ConsultationNotFound:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Consulta no encontrada")
    return ConsultationStatusResponse(
        id=consultation.id,
        consultation_type=consultation.consultation_type,
        status=consultation.status,
        error=consultation.error,
        updated_at=consultation.updated_at,
    )


@router.get("/{consultation_id}", response_model=ConsultationResponse)
async def get_consultation(
    consultation_id: UUID,
    repo: RepositoryDep,
    user: CurrentUser = Depends(get_current_user),
) -> ConsultationResponse:
    try:
        consultation = await GetConsultationUseCase(repo).execute(consultation_id)
    except ConsultationNotFound:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Consulta no encontrada")
    return ConsultationResponse.from_entity(consultation)


@router.post("/{consultation_id}/validate", response_model=ValidateConsultationResponse)
async def validate_consultation(
    consultation_id: UUID,
    body: ValidateConsultationRequest,
    repo: RepositoryDep,
    user: CurrentUser = Depends(get_current_user),
) -> ValidateConsultationResponse:
    """El médico envía la nota revisada (humano en el bucle) y se construye el FHIR."""
    use_case = ValidateConsultationUseCase(repo)
    try:
        consultation, bundle = await use_case.execute(consultation_id, body.note)
    except ConsultationNotFound:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Consulta no encontrada")
    except InvalidStateTransition as exc:
        raise HTTPException(status.HTTP_409_CONFLICT, str(exc))
    except DomainError as exc:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(exc))

    return ValidateConsultationResponse(
        id=consultation.id, status=consultation.status, fhir=bundle
    )
