"""Tests de modelos clínicos tipados por ConsultationType."""
from __future__ import annotations

import pytest

from app.domain.clinical_documents import (
    AdmissionNote,
    EvolutionNote,
    TreatmentOrdersNote,
    iter_clinical_sections,
    parse_clinical_draft,
)
from app.domain.document_templates import section_labels
from app.domain.enums import ConsultationType
from app.domain.value_objects import ClinicalSection


def test_admission_note_has_seven_clinical_sections():
    note = AdmissionNote(motivo_ingreso=ClinicalSection(content="Dolor"))
    assert len(iter_clinical_sections(note)) == 7
    assert len(section_labels(ConsultationType.admission_interview)) == 7


def test_treatment_orders_has_five_sections():
    note = TreatmentOrdersNote()
    assert len(iter_clinical_sections(note)) == 5


def test_evolution_follows_soap_fields():
    note = EvolutionNote(subjetivo=ClinicalSection(content="Mejor"))
    fields = [name for name, _ in iter_clinical_sections(note)]
    assert fields == ["subjetivo", "objetivo", "evolucion", "juicio_clinico", "plan"]


@pytest.mark.parametrize(
    ("consultation_type", "model_cls"),
    [
        (ConsultationType.admission_interview, AdmissionNote),
        (ConsultationType.treatment_orders, TreatmentOrdersNote),
        (ConsultationType.evolution, EvolutionNote),
    ],
)
def test_parse_clinical_draft_roundtrip(consultation_type, model_cls):
    original = model_cls()
    data = original.model_dump(mode="json")
    parsed = parse_clinical_draft(data)
    assert isinstance(parsed, model_cls)
    assert parsed.document_type == consultation_type
