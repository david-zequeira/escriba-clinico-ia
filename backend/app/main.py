"""Punto de entrada FastAPI."""
from fastapi import FastAPI

from app.api.routes import consultations, health
from app.config import settings

app = FastAPI(title=settings.APP_NAME)

app.include_router(health.router)
app.include_router(consultations.router)


@app.get("/")
async def root() -> dict:
    return {"app": settings.APP_NAME, "env": settings.ENV}
