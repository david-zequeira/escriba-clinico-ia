"""Modelos ORM (SQLAlchemy 2.0). Mapean el agregado Consultation a PostgreSQL."""
from __future__ import annotations

from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import JSON, DateTime, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.domain.enums import ConsultationStatus, ConsultationType


class ConsultationModel(Base):
    __tablename__ = "consultations"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    doctor_id: Mapped[str] = mapped_column(String(128), index=True)
    patient_id: Mapped[str] = mapped_column(String(128), index=True)
    consultation_type: Mapped[ConsultationType] = mapped_column(
        String(32), default=ConsultationType.admission_interview, index=True
    )
    status: Mapped[ConsultationStatus] = mapped_column(
        String(32), default=ConsultationStatus.created, index=True
    )
    audio_path: Mapped[str | None] = mapped_column(String(512), nullable=True)

    # Transcripción y borrador se guardan como JSON (mapeables a FHIR en el futuro).
    transcript: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    clinical_draft: Mapped[dict | None] = mapped_column(JSON, nullable=True)

    error: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
