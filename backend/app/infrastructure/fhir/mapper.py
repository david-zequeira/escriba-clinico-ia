"""Mapeo de borradores clínicos validados a FHIR R4 Composition (LOINC). MVP: sin envío al HIS."""
from __future__ import annotations

from app.domain.clinical_documents import (
    AdmissionNote,
    ClinicalDraft,
    EvolutionNote,
    TreatmentOrdersNote,
    iter_clinical_sections,
)
from app.domain.document_templates import fhir_composition_type, section_labels
from app.domain.enums import ConsultationType


def note_to_fhir(
    note: ClinicalDraft,
    patient_id: str,
    doctor_id: str,
    consultation_type: ConsultationType,
) -> dict:
    """Devuelve un Composition FHIR (dict). `status=final` tras validación médica."""
    labels = section_labels(consultation_type)
    loinc = fhir_composition_type(consultation_type)
    return {
        "resourceType": "Composition",
        "status": "final",
        "type": {
            "coding": [loinc],
            "text": loinc["display"],
        },
        "subject": {"reference": f"Patient/{patient_id}"},
        "author": [{"reference": f"Practitioner/{doctor_id}"}],
        "extension": [
            {
                "url": "https://vionix.health/fhir/ai-assisted",
                "valueBoolean": note.generated_by_ai,
            },
            {
                "url": "https://vionix.health/fhir/document-type",
                "valueCode": consultation_type.value,
            },
        ],
        "section": [
            {
                "title": labels.get(field_name, field_name),
                "text": {"status": "generated", "div": section.content},
            }
            for field_name, section in iter_clinical_sections(note)
        ],
    }


def draft_schema_name(consultation_type: ConsultationType) -> str:
    """Nombre del esquema para documentación OpenAPI."""
    return {
        ConsultationType.admission_interview: "AdmissionNote",
        ConsultationType.treatment_orders: "TreatmentOrdersNote",
        ConsultationType.evolution: "EvolutionNote",
    }[consultation_type]
