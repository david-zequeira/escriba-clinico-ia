"""Almacenamiento de audio en disco local (MVP). Swap futuro: S3 UE / Scaleway Object Storage."""
from __future__ import annotations

import asyncio
from pathlib import Path
from uuid import UUID

from app.core.config import settings
from app.domain.ports import AudioStorage


class LocalAudioStorage(AudioStorage):
    def __init__(self, base_dir: str | None = None) -> None:
        self._base = Path(base_dir or settings.AUDIO_STORAGE_DIR)
        self._base.mkdir(parents=True, exist_ok=True)

    async def save(self, consultation_id: UUID, filename: str, data: bytes) -> str:
        suffix = Path(filename).suffix or ".bin"
        target = self._base / f"{consultation_id}{suffix}"
        await asyncio.to_thread(target.write_bytes, data)
        return str(target)

    async def read(self, path: str) -> bytes:
        return await asyncio.to_thread(Path(path).read_bytes)

    async def delete(self, path: str) -> None:
        await asyncio.to_thread(lambda: Path(path).unlink(missing_ok=True))


def get_audio_storage() -> AudioStorage:
    return LocalAudioStorage()
