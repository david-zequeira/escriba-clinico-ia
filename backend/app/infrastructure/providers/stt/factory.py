"""Fábrica de proveedor STT según configuración. Nunca acoplar el caso de uso a uno concreto."""
from __future__ import annotations

from app.core.config import settings
from app.domain.ports import STTProvider
from app.infrastructure.providers.guards import ensure_mock_allowed
from app.infrastructure.providers.stt.gladia import GladiaSTTProvider
from app.infrastructure.providers.stt.mock import MockSTTProvider
from app.infrastructure.providers.stt.speechmatics import SpeechmaticsSTTProvider


def get_stt_provider() -> STTProvider:
    provider = settings.STT_PROVIDER.lower()
    ensure_mock_allowed(provider)
    if provider == "mock":
        return MockSTTProvider()
    if provider == "gladia":
        return GladiaSTTProvider()
    if provider == "speechmatics":
        return SpeechmaticsSTTProvider()
    raise ValueError(f"Proveedor STT no soportado: {provider}")
