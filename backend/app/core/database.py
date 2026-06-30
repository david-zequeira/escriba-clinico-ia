"""Motor async de SQLAlchemy 2.0 y fábrica de sesiones."""
from __future__ import annotations

from collections.abc import AsyncIterator
from pathlib import Path

from sqlalchemy.engine import make_url
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

from app.core.config import settings


class Base(DeclarativeBase):
    """Base declarativa para todos los modelos ORM."""


def _ensure_sqlite_parent_dir() -> None:
    """SQLite no crea directorios; asegura ./var/ antes de conectar."""
    url = make_url(settings.DATABASE_URL)
    if not url.drivername.startswith("sqlite"):
        return
    if not url.database or url.database == ":memory:":
        return
    Path(url.database).parent.mkdir(parents=True, exist_ok=True)


_ensure_sqlite_parent_dir()


engine: AsyncEngine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.ENV == "dev",
    pool_pre_ping=True,
)

SessionFactory: async_sessionmaker[AsyncSession] = async_sessionmaker(
    bind=engine,
    expire_on_commit=False,
    autoflush=False,
)


async def get_session() -> AsyncIterator[AsyncSession]:
    """Dependencia FastAPI: una sesión por request."""
    async with SessionFactory() as session:
        yield session


async def init_db() -> None:
    """Crea las tablas (MVP). En producción usar Alembic para migraciones."""
    # Importar modelos para registrarlos en la metadata antes de create_all.
    from app.infrastructure.db import models  # noqa: F401

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
