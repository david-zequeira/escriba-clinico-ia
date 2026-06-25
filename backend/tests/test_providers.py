"""Tests unitarios de mapeo de providers (sin llamadas de red)."""
from __future__ import annotations

import pytest

from app.domain.enums import ConsultationType
from app.infrastructure.providers.stt.gladia import _map_speaker, _map_transcript


def test_map_speaker_medico_paciente_interview():
    assert _map_speaker(0, ConsultationType.admission_interview) == "medico"
    assert _map_speaker(1, ConsultationType.admission_interview) == "paciente"


def test_map_speaker_solo_dictation():
    assert _map_speaker(0, ConsultationType.treatment_orders) == "medico"
    assert _map_speaker(1, ConsultationType.evolution) == "medico"


def test_map_transcript_from_utterances():
    result = {
        "transcription": {
            "utterances": [
                {"speaker": 0, "text": "Buenos días.", "start": 0.5, "end": 1.2},
                {"speaker": 1, "text": "Me duele la cabeza.", "start": 1.5, "end": 3.0},
            ]
        }
    }
    transcript = _map_transcript(result, "es", ConsultationType.admission_interview)
    assert len(transcript.segments) == 2
    assert transcript.segments[0].speaker == "medico"
    assert transcript.segments[1].speaker == "paciente"


def test_map_transcript_fallback_to_full_text_evolution():
    result = {"transcription": {"full_transcript": "Paciente estable.", "utterances": []}}
    transcript = _map_transcript(result, "es", ConsultationType.evolution)
    assert transcript.segments[0].speaker == "medico"


def test_gladia_provider_requires_api_key(monkeypatch):
    from app.core import config
    from app.infrastructure.providers.stt.gladia import GladiaSTTProvider

    monkeypatch.setattr(config.settings, "STT_API_KEY", "")

    with pytest.raises(ValueError, match="STT_API_KEY"):
        GladiaSTTProvider()
