"""Fábrica del proveedor STT en streaming (F2).

Nunca acoplar el endpoint WebSocket a un proveedor concreto: se selecciona por
configuración (`STT_REALTIME_PROVIDER`), igual que el STT batch.
"""
from __future__ import annotations

from app.core.config import settings
from app.domain.ports import RealtimeSTTProvider
from app.infrastructure.providers.stt.realtime_mock import MockRealtimeSTTProvider


def get_realtime_stt_provider() -> RealtimeSTTProvider:
    provider = settings.STT_REALTIME_PROVIDER.lower()
    if provider == "mock":
        return MockRealtimeSTTProvider()
    # TODO(F2): registrar gladia | speechmatics realtime cuando se implementen.
    raise ValueError(f"Proveedor STT realtime no soportado: {provider}")
