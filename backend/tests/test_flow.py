"""Test del flujo crítico de extremo a extremo: crear -> subir audio -> procesar -> resultado."""
from __future__ import annotations

import asyncio

import pytest


async def _wait_completed(client, consultation_id: str, timeout: float = 5.0) -> dict:
    """Sondea GET /status hasta que el worker termina (estado terminal)."""
    deadline = asyncio.get_event_loop().time() + timeout
    while asyncio.get_event_loop().time() < deadline:
        resp = await client.get(f"/consultations/{consultation_id}/status")
        body = resp.json()
        if body["status"] in ("completed", "failed"):
            return body
        await asyncio.sleep(0.05)
    raise AssertionError("El procesamiento no terminó a tiempo")


@pytest.mark.asyncio
async def test_full_flow(client):
    # 1) Crear consulta
    resp = await client.post("/consultations", json={"patient_id": "patient-123"})
    assert resp.status_code == 201
    consultation = resp.json()
    cid = consultation["id"]
    assert consultation["status"] == "created"

    # 2) Subir audio -> 202 y estado queued (NO se procesa IA en el request)
    resp = await client.post(
        f"/consultations/{cid}/audio",
        files={"audio": ("consulta.wav", b"fake-audio-bytes", "audio/wav")},
    )
    assert resp.status_code == 202
    assert resp.json()["status"] == "queued"

    # 3) El worker procesa async -> completed
    status_body = await _wait_completed(client, cid)
    assert status_body["status"] == "completed"

    # 4) Resultado con transcripción y borrador
    resp = await client.get(f"/consultations/{cid}")
    assert resp.status_code == 200
    result = resp.json()
    assert result["transcript"] is not None
    assert result["clinical_draft"] is not None
    assert result["clinical_draft"]["document_type"] == "admission_interview"
    assert result["clinical_draft"]["generated_by_ai"] is True
    assert "motivo_ingreso" in result["clinical_draft"]
    # Minimización: el audio se descartó tras transcribir.

    # 5) Validación médica (humano en el bucle) -> FHIR
    resp = await client.post(
        f"/consultations/{cid}/validate",
        json={"note": result["clinical_draft"]},
    )
    assert resp.status_code == 200
    validated = resp.json()
    assert validated["status"] == "validated"
    assert validated["fhir"]["resourceType"] == "Composition"


@pytest.mark.asyncio
async def test_audio_on_unknown_consultation(client):
    resp = await client.post(
        "/consultations/00000000-0000-0000-0000-000000000000/audio",
        files={"audio": ("x.wav", b"data", "audio/wav")},
    )
    assert resp.status_code == 404
