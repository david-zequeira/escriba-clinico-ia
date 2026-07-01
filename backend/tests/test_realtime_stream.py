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


async def test_mock_assign_speakers_alterna_medico_paciente():
    labels = await MockLLMProvider().assign_speakers(
        ["pregunta", "respuesta", "otra pregunta"],
        ConsultationType.admission_interview,
    )
    assert labels == ["medico", "paciente", "medico"]


async def test_draft_from_transcript_diariza_segmentos_desconocidos():
    consultation = Consultation(
        doctor_id="d-1",
        patient_id="p-1",
        consultation_type=ConsultationType.admission_interview,
    )
    repo = _InMemoryRepo(consultation)
    transcript = Transcript(
        segments=[
            TranscriptSegment(speaker="desconocido", text="¿Qué le ocurre?"),
            TranscriptSegment(speaker="desconocido", text="Me duele el pecho."),
        ]
    )

    await DraftFromTranscriptUseCase(repo, MockLLMProvider()).execute(
        consultation.id, transcript
    )

    speakers = [s.speaker for s in consultation.transcript.segments]
    assert speakers == ["medico", "paciente"]
    assert consultation.status == ConsultationStatus.completed


class _SpyLLM(MockLLMProvider):
    """LLM mock que registra las llamadas de diarización.

    - `assign_speakers` (mono): devuelve 'paciente' para toda intervención.
    - `assign_cluster_roles` (diarización limpia): si se le pasan `cluster_roles`
      los devuelve tal cual (para simular confirmación o inversión); si no, usa el
      del mock. Reutiliza structure_note del mock.
    """

    def __init__(self, cluster_roles: list[str] | None = None) -> None:
        self.assign_calls: list[list[str]] = []
        self.cluster_calls: list[list[list[str]]] = []
        self._cluster_roles = cluster_roles

    async def assign_speakers(
        self, texts, consultation_type=ConsultationType.admission_interview
    ):
        self.assign_calls.append(list(texts))
        return ["paciente"] * len(texts)

    async def assign_cluster_roles(
        self, clusters, consultation_type=ConsultationType.admission_interview
    ):
        self.cluster_calls.append([list(c) for c in clusters])
        if self._cluster_roles is not None:
            return list(self._cluster_roles)
        return await super().assign_cluster_roles(clusters, consultation_type)


async def test_draft_diariza_cuando_el_stt_no_separo_dos_voces():
    """Una sola voz en vivo deja todo en un único interlocutor (p. ej. 'medico'):
    el LLM debe reasignar por contenido igualmente (no solo si es 'desconocido')."""
    consultation = Consultation(
        doctor_id="d-1",
        patient_id="p-1",
        consultation_type=ConsultationType.admission_interview,
    )
    repo = _InMemoryRepo(consultation)
    transcript = Transcript(
        segments=[
            TranscriptSegment(speaker="medico", text="Hola."),
            TranscriptSegment(speaker="medico", text="Me duele el pecho."),
        ]
    )
    spy = _SpyLLM()

    await DraftFromTranscriptUseCase(repo, spy).execute(consultation.id, transcript)

    assert spy.assign_calls == [["Hola.", "Me duele el pecho."]]  # se llamó al LLM
    speakers = [s.speaker for s in consultation.transcript.segments]
    assert speakers == ["paciente", "paciente"]  # se aplicaron sus etiquetas


async def test_draft_verifica_rol_por_cluster_en_diarizacion_limpia():
    """Con dos voces limpias del STT no se confía en el orden: el LLM asigna el
    rol de cada voz por contenido (una llamada por consulta, no por intervención).
    Si confirma la orientación, las etiquetas se mantienen."""
    consultation = Consultation(
        doctor_id="d-1",
        patient_id="p-1",
        consultation_type=ConsultationType.admission_interview,
    )
    repo = _InMemoryRepo(consultation)
    transcript = Transcript(
        segments=[
            TranscriptSegment(speaker="medico", text="¿Qué le ocurre?"),
            TranscriptSegment(speaker="paciente", text="Me duele el pecho."),
        ]
    )
    spy = _SpyLLM(cluster_roles=["medico", "paciente"])  # confirma la orientación

    await DraftFromTranscriptUseCase(repo, spy).execute(consultation.id, transcript)

    assert spy.assign_calls == []  # NO se atribuye intervención a intervención
    assert spy.cluster_calls == [[["¿Qué le ocurre?"], ["Me duele el pecho."]]]
    speakers = [s.speaker for s in consultation.transcript.segments]
    assert speakers == ["medico", "paciente"]


async def test_draft_corrige_inversion_de_roles_por_contenido():
    """Si el STT etiquetó las voces al revés (paciente como 'medico'), el LLM las
    reorienta por contenido y el borrador queda con los roles correctos."""
    consultation = Consultation(
        doctor_id="d-1",
        patient_id="p-1",
        consultation_type=ConsultationType.admission_interview,
    )
    repo = _InMemoryRepo(consultation)
    # Etiquetas del STT INVERTIDAS respecto al contenido.
    transcript = Transcript(
        segments=[
            TranscriptSegment(speaker="medico", text="Me duele el pecho."),
            TranscriptSegment(speaker="paciente", text="¿Qué le ocurre?"),
        ]
    )
    spy = _SpyLLM(cluster_roles=["paciente", "medico"])  # el LLM invierte

    await DraftFromTranscriptUseCase(repo, spy).execute(consultation.id, transcript)

    speakers = [s.speaker for s in consultation.transcript.segments]
    assert speakers == ["paciente", "medico"]  # corregido por contenido


async def test_draft_conserva_etiquetas_si_el_llm_no_distingue_roles():
    """Guarda anti-degeneración: si el LLM no separa médico y paciente, se
    conservan las etiquetas del STT en lugar de empeorar."""
    consultation = Consultation(
        doctor_id="d-1",
        patient_id="p-1",
        consultation_type=ConsultationType.admission_interview,
    )
    repo = _InMemoryRepo(consultation)
    transcript = Transcript(
        segments=[
            TranscriptSegment(speaker="medico", text="¿Qué le ocurre?"),
            TranscriptSegment(speaker="paciente", text="Me duele el pecho."),
        ]
    )
    spy = _SpyLLM(cluster_roles=["medico", "medico"])  # degenerado

    await DraftFromTranscriptUseCase(repo, spy).execute(consultation.id, transcript)

    speakers = [s.speaker for s in consultation.transcript.segments]
    assert speakers == ["medico", "paciente"]  # se conservan las originales


async def test_draft_no_diariza_en_tipos_de_dictado():
    """En dictado (no entrevista) no hay dos interlocutores: no se diariza."""
    consultation = Consultation(
        doctor_id="d-1",
        patient_id="p-1",
        consultation_type=ConsultationType.treatment_orders,
    )
    repo = _InMemoryRepo(consultation)
    transcript = Transcript(
        segments=[TranscriptSegment(speaker="medico", text="Paracetamol 1 g cada 8 h.")]
    )
    spy = _SpyLLM()

    await DraftFromTranscriptUseCase(repo, spy).execute(consultation.id, transcript)

    assert spy.assign_calls == []
    assert consultation.status == ConsultationStatus.completed


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
    # En mono Gladia no diariza: el live sale 'desconocido' (el LLM asigna luego).
    assert events[0].speaker == "desconocido"
    assert events[0].text == "Buenos"
    assert events[0].start_ms == 100
    assert isinstance(events[1], FinalTranscript)
    assert events[1].speaker == "desconocido"
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


async def test_speechmatics_extrae_texto_de_metadata_y_agrupa_por_frase():
    """El texto viene en `metadata.transcript` (no en el nivel superior del
    mensaje) y los finales palabra a palabra se agrupan en una sola frase hasta
    el cierre de oración (`is_eos`)."""
    from app.infrastructure.providers.stt.realtime_speechmatics import (
        SpeechmaticsRealtimeSession,
    )

    messages = [
        json.dumps({
            "message": "AddTranscript",
            "metadata": {"start_time": 0.1, "end_time": 0.6, "transcript": "Me duele "},
            "results": [{"alternatives": [{"content": "Me", "speaker": "S1"}]}],
        }),
        json.dumps({
            "message": "AddTranscript",
            "metadata": {"start_time": 0.6, "end_time": 1.4, "transcript": "la cabeza."},
            "results": [
                {"alternatives": [{"content": "cabeza", "speaker": "S1"}]},
                {"type": "punctuation", "is_eos": True,
                 "alternatives": [{"content": ".", "speaker": "S1"}]},
            ],
        }),
        json.dumps({"message": "EndOfTranscript"}),
    ]
    session = SpeechmaticsRealtimeSession(
        _FakeGladiaWS(messages), ConsultationType.admission_interview
    )

    events = [event async for event in session.events()]
    finals = [e for e in events if isinstance(e, FinalTranscript)]

    assert len(finals) == 1  # las dos partes se agrupan en una frase
    assert finals[0].text == "Me duele la cabeza."
    assert finals[0].speaker == "desconocido"  # una sola voz: no se adivina el rol
    assert finals[0].end_ms == 1400
    assert isinstance(events[-1], TranscriptionClosed)


def _sm_final(transcript: str, speaker: str) -> str:
    """Mensaje AddTranscript de Speechmatics con una frase cerrada (`is_eos`)."""
    return json.dumps({
        "message": "AddTranscript",
        "metadata": {"start_time": 0.0, "end_time": 1.0, "transcript": transcript},
        "results": [
            {"alternatives": [{"content": transcript.split()[0], "speaker": speaker}]},
            {"type": "punctuation", "is_eos": True,
             "alternatives": [{"content": ".", "speaker": speaker}]},
        ],
    })


async def test_speechmatics_diariza_medico_paciente_solo_con_dos_voces():
    """Con una sola voz el rol es 'desconocido' (no se inventa "médico"); al
    aparecer un 2.º interlocutor se infiere médico/paciente por orden."""
    from app.infrastructure.providers.stt.realtime_speechmatics import (
        SpeechmaticsRealtimeSession,
    )

    messages = [
        _sm_final("Hola.", "S1"),
        _sm_final("Hola, doctor.", "S2"),
        _sm_final("Cuénteme.", "S1"),
        json.dumps({"message": "EndOfTranscript"}),
    ]
    session = SpeechmaticsRealtimeSession(
        _FakeGladiaWS(messages), ConsultationType.admission_interview
    )

    finals = [e async for e in session.events() if isinstance(e, FinalTranscript)]

    assert finals[0].speaker == "desconocido"  # solo se ha oído a S1
    assert finals[1].speaker == "paciente"  # aparece S2 (2.º interlocutor)
    assert finals[2].speaker == "medico"  # S1 (1.º) ya con dos voces → médico
    assert [f.text for f in finals] == ["Hola.", "Hola, doctor.", "Cuénteme."]


async def test_speechmatics_realtime_endofstream_con_seq():
    from app.infrastructure.providers.stt.realtime_speechmatics import (
        SpeechmaticsRealtimeSession,
    )

    ws = _FakeGladiaWS([])
    session = SpeechmaticsRealtimeSession(ws, ConsultationType.admission_interview)

    await session.push_audio(b"\x00\x01")
    await session.push_audio(b"\x02\x03")
    assert ws.sent == [b"\x00\x01", b"\x02\x03"]

    await session.close()
    assert ws.closed is True
    end = [json.loads(s) for s in ws.sent if isinstance(s, str)]
    assert end and end[-1]["message"] == "EndOfStream"
    assert end[-1]["last_seq_no"] == 2
