"""Cola de trabajos. MVP: asyncio en proceso. Futuro: Celery + Redis (mismo puerto JobQueue).

Para escalar a varios hospitales, sustituir AsyncioJobQueue por CeleryJobQueue sin tocar
los casos de uso: ambos implementan el puerto JobQueue.
"""
from __future__ import annotations

import asyncio
import logging
from uuid import UUID

from app.core.config import settings
from app.domain.ports import JobQueue
from app.workers.tasks import run_processing_job

logger = logging.getLogger("vionix.worker")


class AsyncioJobQueue(JobQueue):
    """Ejecuta el job en el event loop. Mantiene referencias fuertes a las tareas."""

    def __init__(self) -> None:
        self._tasks: set[asyncio.Task] = set()

    async def enqueue_processing(self, consultation_id: UUID) -> None:
        task = asyncio.create_task(self._run(consultation_id))
        self._tasks.add(task)
        task.add_done_callback(self._tasks.discard)

    async def _run(self, consultation_id: UUID) -> None:
        try:
            await run_processing_job(consultation_id)
        except Exception:  # noqa: BLE001
            logger.exception("Job de consulta %s falló", consultation_id)


class CeleryJobQueue(JobQueue):
    """STUB: enviar la tarea a un broker (Redis/RabbitMQ UE). Implementar con Celery."""

    async def enqueue_processing(self, consultation_id: UUID) -> None:  # pragma: no cover
        raise NotImplementedError(
            "Configurar Celery + broker. Usar JOB_QUEUE=asyncio para el MVP."
        )


_queue_singleton: JobQueue | None = None


def get_job_queue() -> JobQueue:
    """Singleton: la cola asyncio guarda estado (referencias a tareas) entre requests."""
    global _queue_singleton
    if _queue_singleton is None:
        if settings.JOB_QUEUE == "celery":
            _queue_singleton = CeleryJobQueue()
        else:
            _queue_singleton = AsyncioJobQueue()
    return _queue_singleton
