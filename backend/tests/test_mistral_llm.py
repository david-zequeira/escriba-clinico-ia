"""Tests del provider LLM Mistral con un cliente simulado (sin red ni API key real).

Verifican el contrato contra el SDK `mistralai` (2.x): construcción del request
(`chat.parse_async` con `response_format` Pydantic) y el mapeo de la respuesta
parseada al borrador clínico tipado. El cliente real se sustituye por un doble que
graba las llamadas y devuelve respuestas predefinidas.
"""
from __future__ import annotations

import json

import pytest

from app.core import config
from app.domain.clinical_documents import AdmissionNote
from app.domain.enums import ConsultationType
from app.domain.value_objects import ClinicalSection, Transcript, TranscriptSegment
from app.infrastructure.providers.llm.mistral import MistralLLMProvider
from app.infrastructure.providers.llm.schemas import (
    AdmissionNoteDraft,
    SpeakerLabelsDraft,
)


# --- Doble de prueba del cliente Mistral -----------------------------------

class _FakeMessage:
    def __init__(self, parsed: object) -> None:
        self.parsed = parsed


class _FakeChoice:
    def __init__(self, parsed: object) -> None:
        self.message = _FakeMessage(parsed)


class _FakeResponse:
    def __init__(self, parsed: object) -> None:
        self.choices = [_FakeChoice(parsed)]


class _FakeChat:
    """Graba cada llamada y devuelve (o lanza) lo que tenga en la cola.

    Cada elemento de `queue` es o bien un objeto `parsed` (se envuelve en una
    respuesta tipo SDK) o una excepción (se lanza, p. ej. para simular JSON inválido).
    """

    def __init__(self, queue: list[object]) -> None:
        self._queue = queue
        self.calls: list[dict] = []

    async def parse_async(self, *, response_format, **kwargs):  # noqa: ANN001
        self.calls.append({"response_format": response_format, **kwargs})
        item = self._queue.pop(0)
        if isinstance(item, Exception):
            raise item
        return _FakeResponse(item)


class _FakeClient:
    def __init__(self, queue: list[object]) -> None:
        self.chat = _FakeChat(queue)


def _provider_with(monkeypatch, queue: list[object]) -> MistralLLMProvider:
    """Crea el provider con una API key ficticia y le inyecta el cliente falso."""
    monkeypatch.setattr(config.settings, "LLM_API_KEY", "test-key")
    monkeypatch.setattr(config.settings, "LLM_MODEL", "mistral-large-latest")
    provider = MistralLLMProvider()
    provider._client = _FakeClient(queue)  # type: ignore[attr-defined]
    return provider


def _transcript() -> Transcript:
    return Transcript(
        language="es",
        segments=[
            TranscriptSegment(speaker="medico", text="¿Qué le ocurre?"),
            TranscriptSegment(speaker="paciente", text="Me duele el pecho."),
        ],
    )


# --- Construcción del provider ---------------------------------------------

def test_mistral_requires_api_key(monkeypatch):
    monkeypatch.setattr(config.settings, "LLM_API_KEY", "")
    with pytest.raises(ValueError, match="LLM_API_KEY"):
        MistralLLMProvider()


# --- structure_note ---------------------------------------------------------

async def test_structure_note_construye_request_y_mapea_borrador(monkeypatch):
    parsed = AdmissionNoteDraft(
        motivo_ingreso=ClinicalSection(content="Dolor torácico."),
        enfermedad_actual=ClinicalSection(
            content="Opresión de 2 horas.", needs_confirmation=True
        ),
    )
    provider = _provider_with(monkeypatch, [parsed])

    draft = await provider.structure_note(
        _transcript(),
        consultation_type=ConsultationType.admission_interview,
        specialty="cardiología",
    )

    # Mapeo correcto al modelo de dominio tipado.
    assert isinstance(draft, AdmissionNote)
    assert draft.generated_by_ai is True
    assert draft.model_name == "mistral-large-latest"
    assert draft.motivo_ingreso.content == "Dolor torácico."
    assert draft.enfermedad_actual.needs_confirmation is True

    # Request enviado al SDK.
    call = provider._client.chat.calls[0]  # type: ignore[attr-defined]
    assert call["response_format"] is AdmissionNoteDraft
    assert call["model"] == "mistral-large-latest"
    assert call["temperature"] == 0.1
    assert call["max_tokens"] == 4096
    system, user = call["messages"]
    assert system["role"] == "system"
    assert user["role"] == "user"
    # El contenido del usuario lleva el tipo, la especialidad y la transcripción real.
    assert "cardiología" in user["content"]
    assert ConsultationType.admission_interview.value in user["content"]
    assert "Me duele el pecho." in user["content"]


async def test_structure_note_falla_si_parsed_es_none(monkeypatch):
    provider = _provider_with(monkeypatch, [None])
    with pytest.raises(RuntimeError, match="no devolvió"):
        await provider.structure_note(_transcript())


async def test_structure_note_reintenta_ante_json_invalido(monkeypatch):
    parsed = AdmissionNoteDraft(motivo_ingreso=ClinicalSection(content="Fiebre."))
    # Primer intento: JSON inválido; segundo intento: respuesta válida.
    provider = _provider_with(
        monkeypatch, [json.JSONDecodeError("bad", "doc", 0), parsed]
    )

    draft = await provider.structure_note(_transcript())

    assert isinstance(draft, AdmissionNote)
    assert draft.motivo_ingreso.content == "Fiebre."
    assert len(provider._client.chat.calls) == 2  # type: ignore[attr-defined]


# --- assign_speakers --------------------------------------------------------

async def test_assign_speakers_normaliza_y_rellena(monkeypatch):
    # El LLM devuelve una etiqueta inválida y menos etiquetas que intervenciones.
    parsed = SpeakerLabelsDraft(speakers=["medico", "ROBOT"])
    provider = _provider_with(monkeypatch, [parsed])

    labels = await provider.assign_speakers(
        ["hola", "me duele", "tome esto"],
        ConsultationType.admission_interview,
    )

    # 'ROBOT' no es válido y falta la 3ª → 'desconocido'; nunca se inventa interlocutor.
    assert labels == ["medico", "desconocido", "desconocido"]
    call = provider._client.chat.calls[0]  # type: ignore[attr-defined]
    assert call["response_format"] is SpeakerLabelsDraft
    assert call["temperature"] == 0.0


async def test_assign_speakers_vacio_no_llama_al_llm(monkeypatch):
    provider = _provider_with(monkeypatch, [])
    assert await provider.assign_speakers([]) == []
    assert provider._client.chat.calls == []  # type: ignore[attr-defined]
