"""Tests de autenticación OIDC (validación de JWT) sin red.

Se genera un par de claves RSA en el propio test, se publica su clave pública como
JWKS (sustituyendo el único punto de red, `oidc._fetch_jwks`) y se firman tokens
con la privada. Así se ejercita la verificación real de firma/iss/aud/exp.
"""
from __future__ import annotations

import json
import time

import jwt
import pytest
from cryptography.hazmat.primitives.asymmetric import rsa
from fastapi import HTTPException
from jwt.algorithms import RSAAlgorithm

from app.core import config, oidc, security

_ISSUER = "https://idp.test/realms/vionix"
_AUDIENCE = "vionix-api"
_KID = "test-kid"

# Par de claves de test (uno para todo el módulo: generar RSA es caro).
_PRIVATE_KEY = rsa.generate_private_key(public_exponent=65537, key_size=2048)
_OTHER_KEY = rsa.generate_private_key(public_exponent=65537, key_size=2048)


def _jwk_from(public_key, kid: str = _KID) -> dict:
    jwk = json.loads(RSAAlgorithm.to_jwk(public_key))
    jwk.update({"kid": kid, "use": "sig", "alg": "RS256"})
    return jwk


def _mint(private_key=_PRIVATE_KEY, *, kid: str | None = _KID, **overrides) -> str:
    now = int(time.time())
    payload = {
        "sub": "dr-house",
        "iss": _ISSUER,
        "aud": _AUDIENCE,
        "iat": now,
        "exp": now + 3600,
        "name": "Dr. Gregory House",
        **overrides,
    }
    headers = {"kid": kid} if kid else {}
    return jwt.encode(payload, private_key, algorithm="RS256", headers=headers)


@pytest.fixture
def oidc_configured(monkeypatch):
    """Configura OIDC y publica la clave pública de test como JWKS (sin red)."""
    monkeypatch.setattr(config.settings, "OIDC_ISSUER", _ISSUER)
    monkeypatch.setattr(config.settings, "OIDC_AUDIENCE", _AUDIENCE)

    async def _fake_fetch_jwks() -> list[dict]:
        return [_jwk_from(_PRIVATE_KEY.public_key())]

    monkeypatch.setattr(oidc, "_fetch_jwks", _fake_fetch_jwks)
    oidc._reset_cache_for_tests()
    yield
    oidc._reset_cache_for_tests()


# --- Camino feliz -----------------------------------------------------------

async def test_token_valido_devuelve_medico(oidc_configured):
    user = await security.authenticate(_mint())
    assert user.doctor_id == "dr-house"
    assert user.name == "Dr. Gregory House"


async def test_nombre_cae_a_preferred_username(oidc_configured):
    token = _mint(name=None, preferred_username="ghouse")
    user = await security.authenticate(token)
    assert user.name == "ghouse"


# --- Rechazos ---------------------------------------------------------------

async def test_token_expirado_se_rechaza(oidc_configured):
    expired = _mint(exp=int(time.time()) - 10)
    with pytest.raises(oidc.OidcError):
        await security.authenticate(expired)


async def test_audiencia_incorrecta_se_rechaza(oidc_configured):
    with pytest.raises(oidc.OidcError):
        await security.authenticate(_mint(aud="otro-servicio"))


async def test_emisor_incorrecto_se_rechaza(oidc_configured):
    with pytest.raises(oidc.OidcError):
        await security.authenticate(_mint(iss="https://idp.malo/realms/x"))


async def test_firma_invalida_se_rechaza(oidc_configured):
    # Firmado con otra clave privada, pero mismo kid que el JWKS publicado.
    forged = _mint(_OTHER_KEY)
    with pytest.raises(oidc.OidcError):
        await security.authenticate(forged)


async def test_token_sin_kid_se_rechaza(oidc_configured):
    with pytest.raises(oidc.OidcError):
        await security.authenticate(_mint(kid=None))


async def test_oidc_no_configurado_rechaza_token(monkeypatch):
    monkeypatch.setattr(config.settings, "OIDC_ISSUER", "")
    monkeypatch.setattr(config.settings, "OIDC_AUDIENCE", "")
    with pytest.raises(oidc.OidcError, match="no está configurado"):
        await oidc.verify_token(_mint())


# --- Dev bypass -------------------------------------------------------------

async def test_sin_token_en_dev_usa_medico_simulado(monkeypatch):
    monkeypatch.setattr(config.settings, "ENV", "dev")
    monkeypatch.setattr(config.settings, "AUTH_DEV_BYPASS", True)
    user = await security.authenticate(None)
    assert user.doctor_id == "demo-doctor"


async def test_sin_token_en_prod_exige_autenticacion(monkeypatch):
    # Aunque AUTH_DEV_BYPASS quede a true por error, fuera de dev no aplica.
    monkeypatch.setattr(config.settings, "ENV", "production")
    monkeypatch.setattr(config.settings, "AUTH_DEV_BYPASS", True)
    with pytest.raises(security.NotAuthenticated):
        await security.authenticate(None)


async def test_token_invalido_no_cae_al_bypass_en_dev(oidc_configured, monkeypatch):
    """Un token presente pero inválido se rechaza aunque el bypass esté activo."""
    monkeypatch.setattr(config.settings, "ENV", "dev")
    monkeypatch.setattr(config.settings, "AUTH_DEV_BYPASS", True)
    with pytest.raises(oidc.OidcError):
        await security.authenticate(_mint(_OTHER_KEY))


# --- Dependencia FastAPI ----------------------------------------------------

async def test_get_current_user_lanza_401_con_token_invalido(oidc_configured):
    with pytest.raises(HTTPException) as exc:
        await security.get_current_user(token=_mint(_OTHER_KEY))
    assert exc.value.status_code == 401


async def test_get_current_user_ok_con_token_valido(oidc_configured):
    user = await security.get_current_user(token=_mint())
    assert user.doctor_id == "dr-house"


# --- WebSocket --------------------------------------------------------------

def test_ws_rechaza_token_invalido():
    """Un token presente pero inválido cierra el WS antes de aceptar (1008).

    En el entorno de test OIDC no está configurado, así que cualquier token se
    considera inválido: el WS debe rechazar la conexión (no filtra ni acepta).
    """
    from starlette.testclient import TestClient
    from starlette.websockets import WebSocketDisconnect

    from app.main import app

    with TestClient(app) as client:
        with pytest.raises(WebSocketDisconnect):
            with client.websocket_connect(
                "/consultations/abc-123/stream?token=un-token-invalido"
            ):
                pass
