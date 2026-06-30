"""Arranque: python -m app (usa API_HOST/API_PORT del .env)."""
from __future__ import annotations

import uvicorn

from app.core.config import settings

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host=settings.API_HOST,
        port=settings.API_PORT,
        reload=settings.ENV == "dev",
    )
