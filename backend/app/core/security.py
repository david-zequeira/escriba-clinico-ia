"""Autenticación. STUB: integrar OAuth2/OIDC (Keycloak UE o equivalente)."""
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")


async def get_current_user(token: str = Depends(oauth2_scheme)) -> dict:
    # TODO: validar el token contra el proveedor OIDC y devolver el usuario/médico.
    if not token:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "No autenticado")
    return {"practitioner_id": "demo-practitioner"}
