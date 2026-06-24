from app.config import settings
from app.services.stt.base import STTProvider
from app.services.stt.speechmatics import SpeechmaticsSTT


def get_stt_provider() -> STTProvider:
    """Fábrica: devuelve el proveedor STT según configuración."""
    provider = settings.STT_PROVIDER.lower()
    if provider == "speechmatics":
        return SpeechmaticsSTT()
    raise ValueError(f"Proveedor STT no soportado: {provider}")
