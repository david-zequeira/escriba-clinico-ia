"""Tests de tipos de documento clínico en la API."""
from __future__ import annotations

import pytest

from app.domain.document_templates import section_labels
from app.domain.enums import ConsultationType


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("consultation_type", "expected_sections"),
    [
        (ConsultationType.admission_interview, 7),
        (ConsultationType.treatment_orders, 5),
        (ConsultationType.evolution, 5),
    ],
)
async def test_create_consultation_by_type(client, consultation_type, expected_sections):
    resp = await client.post(
        "/consultations",
        json={"patient_id": "p-1", "consultation_type": consultation_type.value},
    )
    assert resp.status_code == 201
    body = resp.json()
    assert body["consultation_type"] == consultation_type.value
    assert body["document_title"]
    assert len(body["section_labels"]) == expected_sections
    assert len(section_labels(consultation_type)) == expected_sections
