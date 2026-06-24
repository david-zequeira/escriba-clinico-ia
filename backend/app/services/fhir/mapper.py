"""Convierte una ClinicalNote validada en recursos FHIR R4 para escribir en el HIS.

STUB: usar la librería `fhir.resources` para construir recursos tipados.
Recursos típicos: Encounter, Composition, Condition, DocumentReference.
"""
from app.models.schemas import ClinicalNote


def note_to_fhir(note: ClinicalNote, patient_id: str, practitioner_id: str) -> dict:
    """Devuelve un Bundle FHIR (dict). Sustituir por modelos `fhir.resources`."""
    return {
        "resourceType": "Composition",
        "status": "preliminary",  # 'final' tras validación médica
        "type": {"text": "Nota de consulta"},
        "subject": {"reference": f"Patient/{patient_id}"},
        "author": [{"reference": f"Practitioner/{practitioner_id}"}],
        "section": [
            {"title": "Motivo de consulta", "text": note.motivo_consulta.content},
            {"title": "Anamnesis", "text": note.anamnesis.content},
            {"title": "Exploración", "text": note.exploracion.content},
            {"title": "Diagnóstico", "text": note.diagnostico.content},
            {"title": "Plan", "text": note.plan.content},
        ],
    }
