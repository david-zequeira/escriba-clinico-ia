"""STT en streaming simulado para desarrollo y demo sin proveedor externo.

Reproduce una conversación de ingreso como parciales que crecen palabra a palabra
y luego se consolidan en un `final`, espejando la fuente *fake* del frontend
(`transcription_stream_source.dart`) para que el comportamiento coincida.

Ignora el audio recibido (no hay motor real) y respeta pausar/reanudar. Útil para
cablear el frontend a un backend real hoy, antes de integrar Gladia Real-Time.
"""
from __future__ import annotations

import asyncio
from collections.abc import AsyncIterator

from app.domain.enums import ConsultationType
from app.domain.ports import RealtimeSTTProvider, RealtimeTranscriptionSession
from app.domain.streaming import (
    FinalTranscript,
    PartialTranscript,
    TranscriptionClosed,
    TranscriptionEvent,
)

# (speaker, text) — conversación clínica verosímil en español (mismo guion que el front).
_SCRIPT: tuple[tuple[str, str], ...] = (
    ("medico", "Buenos días, cuénteme qué le trae hoy a urgencias."),
    ("paciente", "Llevo dos días con dolor en el pecho y me falta el aire al caminar."),
    ("medico", "¿El dolor aparece con el esfuerzo o también en reposo?"),
    ("paciente", "Sobre todo al subir escaleras, pero esta mañana también estando sentado."),
    ("medico", "¿Tiene antecedentes de hipertensión o alguna alergia conocida?"),
    ("paciente", "Soy hipertenso desde hace años y soy alérgico a la penicilina."),
)


class MockRealtimeSession(RealtimeTranscriptionSession):
    """Sesión simulada: emite el guion respetando la cadencia y la pausa."""

    def __init__(self, step: float = 0.05) -> None:
        # Cadencia entre frames (s); 0.0 en tests para que no tarden.
        self._step = step
        self._resumed = asyncio.Event()
        self._resumed.set()
        self._closed = False

    async def events(self) -> AsyncIterator[TranscriptionEvent]:
        elapsed_ms = 0
        for speaker, text in _SCRIPT:
            if self._closed:
                return
            words = text.split(" ")
            start_ms = elapsed_ms

            # Parciales: el texto crece palabra a palabra.
            buffer = ""
            for index, word in enumerate(words):
                if await self._halt():
                    return
                buffer = word if index == 0 else f"{buffer} {word}"
                yield PartialTranscript(speaker=speaker, text=buffer, start_ms=start_ms)

            if await self._halt():
                return
            elapsed_ms += len(words) * 350 + 600
            yield FinalTranscript(
                speaker=speaker, text=text, start_ms=start_ms, end_ms=elapsed_ms
            )

        if not self._closed:
            yield TranscriptionClosed()

    async def _halt(self) -> bool:
        """Espera un paso respetando la pausa. Devuelve True si hay que cortar."""
        await asyncio.sleep(self._step)
        await self._resumed.wait()
        return self._closed

    async def push_audio(self, chunk: bytes) -> None:
        # El mock no usa el audio real: lo descarta (minimización §7).
        _ = chunk

    async def pause(self) -> None:
        self._resumed.clear()

    async def resume(self) -> None:
        self._resumed.set()

    async def close(self) -> None:
        self._closed = True
        self._resumed.set()  # desbloquea cualquier espera pendiente


class MockRealtimeSTTProvider(RealtimeSTTProvider):
    name = "mock-realtime"

    async def open(
        self,
        *,
        language: str = "es",
        consultation_type: ConsultationType = ConsultationType.admission_interview,
    ) -> RealtimeTranscriptionSession:
        _ = (language, consultation_type)
        return MockRealtimeSession()
