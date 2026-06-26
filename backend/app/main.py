"""Punto de entrada FastAPI. Sistema de orquestación IA async (no es un CRUD)."""
from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, RedirectResponse

from app.api.routes import consultations, health, streaming
from app.core.config import settings
from app.core.database import init_db
from app.domain.exceptions import ConsultationNotFound, DomainError

logging.basicConfig(level=logging.INFO)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # MVP: crea las tablas al arrancar. En producción, Alembic.
    await init_db()
    yield


_docs = "/docs" if settings.DOCS_ENABLED else None
_redoc = "/redoc" if settings.DOCS_ENABLED else None
_openapi = "/openapi.json" if settings.DOCS_ENABLED else None

app = FastAPI(
    title=settings.APP_NAME,
    lifespan=lifespan,
    docs_url=_docs,
    redoc_url=_redoc,
    openapi_url=_openapi,
)

# CORS en dev/staging (p. ej. Flutter web contra API en Fly).
if settings.ENV in ("dev", "staging"):
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

app.include_router(health.router)
app.include_router(consultations.router)
app.include_router(streaming.router)


if settings.DOCS_ENABLED:

    @app.get("/swagger", include_in_schema=False)
    @app.get("/swagger/", include_in_schema=False)
    @app.get("/swagger/index.html", include_in_schema=False)
    async def swagger_alias() -> RedirectResponse:
        """Alias tipo .NET → Swagger UI de FastAPI."""
        return RedirectResponse(url="/docs")


@app.exception_handler(ConsultationNotFound)
async def _not_found_handler(_: Request, exc: ConsultationNotFound) -> JSONResponse:
    return JSONResponse(status_code=404, content={"detail": "Consulta no encontrada"})


@app.exception_handler(DomainError)
async def _domain_error_handler(_: Request, exc: DomainError) -> JSONResponse:
    # No exponer trazas internas; solo el mensaje de negocio.
    return JSONResponse(status_code=400, content={"detail": str(exc)})


@app.get("/")
async def root(request: Request):
    accept = request.headers.get("accept", "")
    if settings.DOCS_ENABLED and "text/html" in accept:
        return RedirectResponse(url="/docs")
    payload: dict = {"app": settings.APP_NAME, "env": settings.ENV}
    if settings.DOCS_ENABLED:
        payload["docs"] = "/docs"
        payload["redoc"] = "/redoc"
    return payload
