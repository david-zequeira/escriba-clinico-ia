"""Fábrica de proveedor LLM según configuración. Añadir aquí: azure_openai_eu, self_hosted_vllm."""
from __future__ import annotations

from app.core.config import settings
from app.domain.ports import LLMProvider
from app.infrastructure.providers.llm.mistral import MistralLLMProvider
from app.infrastructure.providers.llm.mock import MockLLMProvider


def get_llm_provider() -> LLMProvider:
    provider = settings.LLM_PROVIDER.lower()
    if provider == "mock":
        return MockLLMProvider()
    if provider == "mistral":
        return MistralLLMProvider()
    raise ValueError(f"Proveedor LLM no soportado: {provider}")
