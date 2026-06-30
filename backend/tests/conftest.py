"""Configura un entorno de test aislado (sqlite) antes de importar la app."""
from __future__ import annotations

import os
import tempfile

# Configurar entorno ANTES de importar la app (el engine se crea al importar).
_DB_FD, _DB_PATH = tempfile.mkstemp(suffix=".db")
os.environ["DATABASE_URL"] = f"sqlite+aiosqlite:///{_DB_PATH}"
os.environ["AUDIO_STORAGE_DIR"] = tempfile.mkdtemp()
os.environ["STT_PROVIDER"] = "mock"
os.environ["STT_REALTIME_PROVIDER"] = "mock"  # tests herméticos: nunca Gladia real
os.environ["LLM_PROVIDER"] = "mock"
os.environ["STT_API_KEY"] = ""  # no usar claves reales del .env en los tests
os.environ["LLM_API_KEY"] = ""
os.environ["JOB_QUEUE"] = "asyncio"
os.environ["ENV"] = "test"

import pytest  # noqa: E402
from httpx import ASGITransport, AsyncClient  # noqa: E402

from app.core.database import init_db  # noqa: E402
from app.main import app  # noqa: E402


@pytest.fixture
async def client():
    await init_db()
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c
