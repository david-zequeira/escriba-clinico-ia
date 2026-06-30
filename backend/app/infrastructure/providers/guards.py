"""Guard de proveedores: el 'mock' nunca debe activarse fuera de desarrollo.

Un proveedor simulado fabrica datos clínicos (una conversación o un borrador
inventados). Si se activara en staging/prod sería una alucinación grave (§7).
"""
from __future__ import annotations

from app.core.config import settings


def ensure_mock_allowed(provider: str) -> None:
    if provider == "mock" and not settings.is_dev_like:
        raise RuntimeError(
            f"Proveedor 'mock' prohibido fuera de desarrollo (ENV={settings.ENV}). "
            "Configura un proveedor real: el mock fabrica datos clínicos y no debe "
            "ejecutarse con datos de pacientes (CLAUDE.md §7)."
        )
