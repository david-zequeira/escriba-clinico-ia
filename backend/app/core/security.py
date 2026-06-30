"""Autenticación OIDC. STUB: integrar validación real (Keycloak UE u OIDC equivalente)."""
from __future__ import annotations

from dataclasses import dataclass

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

from app.core.config import settings

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token", auto_error=False)


@dataclass(frozen=True)
class CurrentUser:
    """Médico autenticado que opera sobre la consulta."""

    doctor_id: str
    name: str = ""


async def get_current_user(token: str | None = Depends(oauth2_scheme)) -> CurrentUser:
    # TODO: validar el JWT contra OIDC_ISSUER/OIDC_AUDIENCE y mapear claims -> doctor_id.
    if token:
        return CurrentUser(doctor_id=f"oidc:{token[:8]}", name="practitioner")
    if settings.AUTH_DEV_BYPASS:
        return CurrentUser(doctor_id="demo-doctor", name="Demo")
    raise HTTPException(status.HTTP_401_UNAUTHORIZED, "No autenticado")
