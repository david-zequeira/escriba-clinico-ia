"""Tests del streaming de transcripción en vivo (F2): eventos, mock y endpoint WS."""
from __future__ import annotations

from starlette.testclient import TestClient

from app.domain.streaming import (
    FinalTranscript,
    PartialTranscript,
    TranscriptionClosed,
)
from app.infrastructure.providers.stt.realtime_mock import (
    MockRealtimeSession,
    MockRealtimeSTTProvider,
)
from app.main import app


def test_event_frames_match_contract():
    assert PartialTranscript(speaker="medico", text="hola", start_ms=10).to_frame() == {
        "type": "partial",
        "speaker": "medico",
        "text": "hola",
        "start_ms": 10,
    }
    assert FinalTranscript(
        speaker="paciente", text="me duele", start_ms=10, end_ms=20
    ).to_frame() == {
        "type": "final",
        "speaker": "paciente",
        "text": "me duele",
        "start_ms": 10,
        "end_ms": 20,
    }
    assert TranscriptionClosed().to_frame() == {"type": "closed"}


async def test_mock_realtime_emits_partials_finals_and_closes():
    session = MockRealtimeSession(step=0.0)
    events = [event async for event in session.events()]

    assert any(isinstance(e, PartialTranscript) for e in events)
    assert any(isinstance(e, FinalTranscript) for e in events)
    assert isinstance(events[-1], TranscriptionClosed)

    # Diarización médico/paciente presente en los segmentos consolidados.
    speakers = {e.speaker for e in events if isinstance(e, FinalTranscript)}
    assert speakers == {"medico", "paciente"}


async def test_mock_realtime_close_detiene_el_stream():
    session = MockRealtimeSession(step=0.0)
    stream = session.events()
    first = await stream.__anext__()
    assert isinstance(first, PartialTranscript)

    await session.close()
    rest = [event async for event in stream]
    # Tras cerrar no debe consolidar ni emitir más; se corta limpio.
    assert all(not isinstance(e, FinalTranscript) for e in rest)


def test_websocket_stream_devuelve_frames_del_contrato():
    with TestClient(app) as client:
        with client.websocket_connect("/consultations/abc-123/stream") as ws:
            frames = []
            while True:
                frame = ws.receive_json()
                frames.append(frame)
                if frame["type"] == "closed":
                    break

    types = {f["type"] for f in frames}
    assert "partial" in types
    assert "final" in types
    assert frames[-1]["type"] == "closed"
    # Todos los frames respetan el discriminador del contrato.
    assert types <= {"partial", "final", "error", "closed"}
