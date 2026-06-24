"""Configuración por variables de entorno (pydantic-settings)."""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    APP_NAME: str = "Escriba Clínico IA"
    ENV: str = "dev"

    # STT
    STT_PROVIDER: str = "speechmatics"
    STT_API_KEY: str = ""

    # LLM
    LLM_PROVIDER: str = "mistral"
    LLM_API_KEY: str = ""
    LLM_MODEL: str = "mistral-large-latest"

    # Base de datos (UE)
    DATABASE_URL: str = "postgresql+asyncpg://user:pass@localhost:5432/escriba"

    # Seguridad
    OIDC_ISSUER: str = ""
    OIDC_AUDIENCE: str = ""


settings = Settings()
