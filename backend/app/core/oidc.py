"""Verificación de tokens OIDC (JWT RS256) contra el JWKS del IdP.

El backend NO emite tokens ni maneja contraseñas: confía en el IdP del hospital
(Keycloak u OIDC equivalente, residencia UE). Cada petición trae un access token
firmado por el IdP; aquí se valida su firma (con la clave pública del JWKS), su
emisor (`iss`), su audiencia (`aud`) y su expiración (`exp`).

Sin red en los tests: `_fetch_jwks` es el único punto de E/S y se sustituye por un
doble que devuelve la clave pública de un par RSA generado en el propio test.
"""
from __future__ import annotations

import json
import logging
import time

import httpx
import jwt
from jwt import PyJWKClient  # noqa: F401  (re-export para posibles usos externos)
from jwt.algorithms import RSAAlgorithm

from app.core.config import settings

logger = logging.getLogger("app.oidc")

# TTL del JWKS en caché: las claves del IdP rotan con poca frecuencia; se refresca
# igualmente si aparece un `kid` desconocido (rotación en caliente).
_JWKS_TTL_SEC = 3600.0


class OidcError(Exception):
    """Token OIDC inválido o el IdP no está configurado/accesible."""


# Caché de proceso: {kid: JWK dict} + marca de tiempo de la última descarga.
_jwks_by_kid: dict[str, dict] = {}
_jwks_fetched_at: float = 0.0


def _discovery_url() -> str:
    issuer = settings.OIDC_ISSUER.rstrip("/")
    return f"{issuer}/.well-known/openid-configuration"


async def _fetch_jwks() -> list[dict]:
    """Descarga las claves públicas del IdP. Único punto de red (mockeable en tests).

    Usa `OIDC_JWKS_URL` si está fijado; si no, lo descubre desde el issuer.
    """
    async with httpx.AsyncClient(timeout=5.0) as http:
        jwks_url = settings.OIDC_JWKS_URL
        if not jwks_url:
            discovery = (await http.get(_discovery_url())).raise_for_status().json()
            jwks_url = discovery["jwks_uri"]
        data = (await http.get(jwks_url)).raise_for_status().json()
    return list(data.get("keys", []))


async def _refresh_jwks() -> None:
    global _jwks_fetched_at
    keys = await _fetch_jwks()
    _jwks_by_kid.clear()
    for key in keys:
        kid = key.get("kid")
        if kid:
            _jwks_by_kid[kid] = key
    _jwks_fetched_at = time.monotonic()


async def _signing_key_for(kid: str):
    """Devuelve la clave pública para ese `kid`, refrescando el JWKS si hace falta."""
    stale = (time.monotonic() - _jwks_fetched_at) > _JWKS_TTL_SEC
    if kid not in _jwks_by_kid or stale:
        await _refresh_jwks()
    jwk = _jwks_by_kid.get(kid)
    if jwk is None:
        raise OidcError("Clave de firma desconocida (kid no está en el JWKS)")
    return RSAAlgorithm.from_jwk(json.dumps(jwk))


async def verify_token(token: str) -> dict:
    """Valida el JWT y devuelve sus claims. Lanza `OidcError` si no es válido."""
    if not settings.OIDC_ISSUER or not settings.OIDC_AUDIENCE:
        raise OidcError("OIDC no está configurado (falta OIDC_ISSUER/OIDC_AUDIENCE)")
    try:
        kid = jwt.get_unverified_header(token).get("kid")
    except jwt.PyJWTError as exc:
        raise OidcError("Cabecera de token ilegible") from exc
    if not kid:
        raise OidcError("El token no indica la clave de firma (kid)")

    key = await _signing_key_for(kid)
    try:
        return jwt.decode(
            token,
            key=key,
            algorithms=["RS256"],
            audience=settings.OIDC_AUDIENCE,
            issuer=settings.OIDC_ISSUER,
            options={"require": ["exp", "iss", "aud", "sub"]},
        )
    except jwt.PyJWTError as exc:
        # No filtrar el detalle del token en el mensaje (§7.8): solo la causa.
        raise OidcError(f"Token OIDC inválido: {type(exc).__name__}") from exc


def _reset_cache_for_tests() -> None:
    """Limpia la caché del JWKS. Solo para tests (aislamiento entre casos)."""
    global _jwks_fetched_at
    _jwks_by_kid.clear()
    _jwks_fetched_at = 0.0
