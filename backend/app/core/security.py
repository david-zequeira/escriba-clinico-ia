"""Autenticación OIDC: valida el access token del IdP y lo mapea a un médico.

El backend confía en el IdP del hospital (Keycloak u OIDC equivalente, UE): no
maneja contraseñas. Cada petición trae un JWT firmado que aquí se valida
(`app.core.oidc`). En desarrollo, si no llega token, se permite un usuario
simulado (`dev_bypass_active`), nunca en staging/prod.
"""
from __future__ import annotations

from dataclasses import dataclass

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

from app.core.config import settings
from app.core.oidc import OidcError, verify_token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token", auto_error=False)


class NotAuthenticated(Exception):
    """No hay token y el entorno no permite usuario simulado."""


@dataclass(frozen=True)
class CurrentUser:
    """Médico autenticado que opera sobre la consulta."""

    doctor_id: str
    name: str = ""


def _claims_to_user(claims: dict) -> CurrentUser:
    """Mapea los claims del token al usuario del dominio.

    `sub` es el identificador estable del médico en el IdP. El nombre se toma del
    primer claim disponible; nunca es obligatorio para operar.
    """
    doctor_id = str(claims["sub"])
    name = (
        claims.get("name")
        or claims.get("preferred_username")
        or claims.get("email")
        or ""
    )
    return CurrentUser(doctor_id=doctor_id, name=str(name))


async def authenticate(token: str | None) -> CurrentUser:
    """Resuelve el médico a partir del token (o del bypass de dev).

    Reutilizable fuera de una dependencia FastAPI (p. ej. el WebSocket). Lanza
    `OidcError` (token inválido) o `NotAuthenticated` (sin token y sin bypass).
    """
    if token:
        # Un token presente SIEMPRE se valida, también en dev: si es inválido, se
        # rechaza (no se cae al bypass con un token falso).
        return _claims_to_user(await verify_token(token))
    if settings.dev_bypass_active:
        return CurrentUser(doctor_id="demo-doctor", name="Demo (dev)")
    raise NotAuthenticated("No autenticado")


async def get_current_user(
    token: str | None = Depends(oauth2_scheme),
) -> CurrentUser:
    """Dependencia FastAPI: médico autenticado o 401."""
    try:
        return await authenticate(token)
    except (OidcError, NotAuthenticated) as exc:
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            detail=str(exc),
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc
