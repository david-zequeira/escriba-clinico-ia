"""Configuración por variables de entorno (pydantic-settings).

Nada de secretos hardcodeados: todo proveedor y clave se inyecta por entorno.
"""
from __future__ import annotations

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    APP_NAME: str = "Vionix IA"
    ENV: str = "dev"

    # --- Servidor HTTP ---
    # 0.0.0.0 = Swagger accesible desde otros dispositivos en la misma red.
    API_HOST: str = "0.0.0.0"
    API_PORT: int = 8000
    # Documentación OpenAPI (/docs, /redoc). Desactivar en producción si no debe ser pública.
    DOCS_ENABLED: bool = True

    # --- Base de datos (residencia UE) ---
    DATABASE_URL: str = "postgresql+asyncpg://vionix:vionix@localhost:5432/vionix"

    # --- Almacenamiento de audio ---
    AUDIO_STORAGE_DIR: str = "./var/audio"
    # Minimización (RGPD): borrar el audio en cuanto se transcribe.
    DELETE_AUDIO_AFTER_TRANSCRIPTION: bool = True

    # --- STT (voz a texto) ---
    STT_PROVIDER: str = "mock"  # mock | gladia | speechmatics  (batch, subida de audio)
    # STT en vivo (F2, WebSocket). Hoy solo 'mock'; gladia/speechmatics realtime pendientes.
    STT_REALTIME_PROVIDER: str = "mock"  # mock | gladia | speechmatics
    STT_API_KEY: str = ""
    STT_LANGUAGE: str = "es"
    GLADIA_MODEL: str = "solaria-3"  # solaria-3 (EU, es/fr/en/de/it) | solaria-1
    GLADIA_POLL_INTERVAL_SEC: float = 2.0
    GLADIA_POLL_TIMEOUT_SEC: float = 600.0
    # Speechmatics Real-Time (modelo médico, endpoint UE para residencia de datos).
    SPEECHMATICS_API_KEY: str = ""
    SPEECHMATICS_RT_URL: str = "wss://eu.rt.speechmatics.com/v2"
    SPEECHMATICS_OPERATING_POINT: str = "enhanced"  # enhanced (máxima precisión) | standard
    SPEECHMATICS_DOMAIN: str = "medical"  # modelo médico; vaciar si la cuenta no lo tiene
    SPEECHMATICS_MAX_DELAY: float = 2.0  # latencia/precisión de los finales (s)

    # --- LLM (estructuración) ---
    LLM_PROVIDER: str = "mock"  # mock | mistral
    LLM_API_KEY: str = ""
    LLM_MODEL: str = "mistral-large-latest"

    # --- Worker / cola de trabajos ---
    JOB_QUEUE: str = "asyncio"  # asyncio (MVP) | celery (futuro)

    # --- Seguridad (OIDC) ---
    # Emisor y audiencia esperados en el access token (IdP del hospital, UE).
    OIDC_ISSUER: str = ""
    OIDC_AUDIENCE: str = ""
    # Opcional: fija el JWKS directamente; si se deja vacío se descubre desde el issuer.
    OIDC_JWKS_URL: str = ""
    # En dev se permite un usuario simulado; en prod debe validarse el token real.
    AUTH_DEV_BYPASS: bool = True

    @property
    def dev_bypass_active(self) -> bool:
        """El bypass de auth solo puede activarse en entornos de desarrollo.

        Igual que el mock (§7): un usuario simulado nunca debe poder autenticar en
        staging/prod. Aunque AUTH_DEV_BYPASS quede a true por error, fuera de dev
        el efecto es nulo y se exige token real.
        """
        return self.AUTH_DEV_BYPASS and self.is_dev_like

    @property
    def is_dev_like(self) -> bool:
        """Entorno de desarrollo/pruebas donde se permiten proveedores 'mock'.

        Fuera de aquí (staging/prod) el mock se prohíbe: un mock que fabrica una
        conversación clínica nunca debe poder activarse con datos reales (§7).
        """
        return self.ENV.lower() in ("dev", "test", "local")


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
