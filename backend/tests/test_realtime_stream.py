"""Tests del streaming de transcripción en vivo (F2): eventos, mock y endpoint WS."""
from __future__ import annotations

import json
import time

from starlette.testclient import TestClient

from app.application.use_cases.draft_from_transcript import DraftFromTranscriptUseCase
from app.domain.entities import Consultation
from app.domain.enums import ConsultationStatus, ConsultationType
from app.domain.streaming import (
    FinalTranscript,
    PartialTranscript,
    TranscriptionClosed,
)
from app.domain.value_objects import Transcript, TranscriptSegment
from app.infrastructure.providers.llm.mock import MockLLMProvider
from app.infrastructure.providers.stt.realtime_mock import (
    MockRealtimeSession,
    MockRealtimeSTTProvider,
)
from app.main import app


class _InMemoryRepo:
    """Repositorio en memoria para aislar el caso de uso de la BD."""

    def __init__(self, consultation: Consultation) -> None:
        self._store = {consultation.id: consultation}

    async def add(self, consultation: Consultation) -> Consultation:
        self._store[consultation.id] = consultation
        return consultation

    async def get(self, consultation_id):
        return self._store.get(consultation_id)

    async def update(self, consultation: Consultation) -> Consultation:
        self._store[consultation.id] = consultation
        return consultation


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


async def test_draft_from_transcript_completa_la_consulta():
    consultation = Consultation(
        doctor_id="d-1",
        patient_id="p-1",
        consultation_type=ConsultationType.admission_interview,
    )
    repo = _InMemoryRepo(consultation)
    transcript = Transcript(
        segments=[TranscriptSegment(speaker="medico", text="Buenos días.")]
    )

    await DraftFromTranscriptUseCase(repo, MockLLMProvider()).execute(
        consultation.id, transcript
    )

    assert consultation.status == ConsultationStatus.completed
    assert consultation.clinical_draft is not None
    assert consultation.transcript is not None


async def test_draft_from_transcript_vacia_falla():
    consultation = Consultation(doctor_id="d-1", patient_id="p-1")
    repo = _InMemoryRepo(consultation)

    await DraftFromTranscriptUseCase(repo, MockLLMProvider()).execute(
        consultation.id, Transcript(segments=[])
    )

    assert consultation.status == ConsultationStatus.failed


def test_websocket_stream_genera_borrador_desde_el_stream():
    """De extremo a extremo: crear consulta → stream WS → borrador sin re-subir audio."""
    with TestClient(app) as client:
        created = client.post("/consultations", json={"patient_id": "p-stream"})
        cid = created.json()["id"]

        with client.websocket_connect(f"/consultations/{cid}/stream") as ws:
            while ws.receive_json()["type"] != "closed":
                pass

        # El borrador se genera al cerrar el WS, a partir de la transcripción.
        status = None
        for _ in range(100):
            status = client.get(f"/consultations/{cid}/status").json()["status"]
            if status in ("completed", "failed"):
                break
            time.sleep(0.05)
        assert status == "completed"

        result = client.get(f"/consultations/{cid}").json()
        assert result["clinical_draft"] is not None
        assert result["transcript"] is not None


class _FakeGladiaWS:
    """WebSocket falso de Gladia para testear el mapeo sin red ni clave."""

    def __init__(self, messages: list[str]) -> None:
        self._messages = list(messages)
        self.sent: list = []
        self.closed = False

    def __aiter__(self):
        return self._iter()

    async def _iter(self):
        for message in self._messages:
            yield message

    async def send(self, data) -> None:
        self.sent.append(data)

    async def close(self, code: int = 1000) -> None:
        self.closed = True


async def test_gladia_realtime_mapea_transcript_partial_y_final():
    from app.infrastructure.providers.stt.realtime_gladia import GladiaRealtimeSession

    messages = [
        json.dumps({"type": "speech_start"}),  # se ignora
        json.dumps({
            "type": "transcript",
            "data": {
                "is_final": False,
                "utterance": {"text": "Buenos", "start": 0.1, "channel": 0},
            },
        }),
        json.dumps({
            "type": "transcript",
            "data": {
                "is_final": True,
                "utterance": {
                    "text": "Buenos días",
                    "start": 0.1,
                    "end": 1.2,
                    "channel": 0,
                },
            },
        }),
    ]
    session = GladiaRealtimeSession(
        _FakeGladiaWS(messages), ConsultationType.admission_interview
    )

    events = [event async for event in session.events()]

    assert isinstance(events[0], PartialTranscript)
    assert events[0].speaker == "medico"
    assert events[0].text == "Buenos"
    assert events[0].start_ms == 100
    assert isinstance(events[1], FinalTranscript)
    assert events[1].text == "Buenos días"
    assert events[1].end_ms == 1200
    assert isinstance(events[-1], TranscriptionClosed)


async def test_gladia_realtime_push_pause_close():
    from app.infrastructure.providers.stt.realtime_gladia import GladiaRealtimeSession

    ws = _FakeGladiaWS([])
    session = GladiaRealtimeSession(ws, ConsultationType.admission_interview)

    await session.push_audio(b"\x00\x01")
    assert ws.sent == [b"\x00\x01"]

    await session.pause()
    await session.push_audio(b"\x02")
    assert ws.sent == [b"\x00\x01"]  # en pausa no se envía audio

    await session.resume()
    await session.close()
    assert ws.closed is True
    assert any(isinstance(s, str) and "stop_recording" in s for s in ws.sent)
