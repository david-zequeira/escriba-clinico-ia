from app.config import settings
from app.services.llm.base import LLMProvider
from app.services.llm.mistral import MistralLLM


def get_llm_provider() -> LLMProvider:
    """Fábrica: devuelve el proveedor LLM según configuración."""
    provider = settings.LLM_PROVIDER.lower()
    if provider == "mistral":
        return MistralLLM()
    # Añadir aquí: azure_openai_eu, self_hosted_vllm, etc.
    raise ValueError(f"Proveedor LLM no soportado: {provider}")
