"""Plantillas de documentación clínica por tipo (etiquetas UI + códigos FHIR LOINC)."""
from __future__ import annotations

from app.domain.enums import ConsultationType

# Títulos de documento
DOCUMENT_TITLES: dict[ConsultationType, str] = {
    ConsultationType.admission_interview: "Historia clínica de ingreso",
    ConsultationType.treatment_orders: "Indicaciones médicas de tratamiento",
    ConsultationType.evolution: "Nota de evolución",
}

# LOINC para Composition.type (FHIR R4 — EU eHealth Network)
FHIR_LOINC: dict[ConsultationType, dict[str, str]] = {
    ConsultationType.admission_interview: {
        "system": "http://loinc.org",
        "code": "47039-3",
        "display": "Hospital Admission history and physical note",
    },
    ConsultationType.treatment_orders: {
        "system": "http://loinc.org",
        "code": "18776-5",
        "display": "Plan of care note",
    },
    ConsultationType.evolution: {
        "system": "http://loinc.org",
        "code": "11506-3",
        "display": "Progress note",
    },
}

# Etiquetas por campo interno del modelo tipado
SECTION_LABELS: dict[ConsultationType, dict[str, str]] = {
    ConsultationType.admission_interview: {
        "motivo_ingreso": "Motivo de ingreso",
        "enfermedad_actual": "Enfermedad actual",
        "antecedentes": "Antecedentes (personales, familiares, alergias, medicación)",
        "exploracion_fisica": "Exploración física",
        "pruebas_complementarias": "Pruebas complementarias",
        "juicio_clinico": "Juicio clínico (borrador)",
        "plan": "Plan de ingreso y actuación",
    },
    ConsultationType.treatment_orders: {
        "contexto": "Contexto del paciente",
        "indicaciones_farmacologicas": "Indicaciones farmacológicas",
        "indicaciones_no_farmacologicas": "Indicaciones no farmacológicas y cuidados",
        "vigilancia": "Vigilancia y constantes",
        "observaciones": "Observaciones y prioridad",
    },
    ConsultationType.evolution: {
        "subjetivo": "Subjetivo",
        "objetivo": "Objetivo y exploración",
        "evolucion": "Evolución clínica",
        "juicio_clinico": "Juicio clínico (borrador)",
        "plan": "Plan terapéutico y próximos pasos",
    },
}


def section_labels(consultation_type: ConsultationType) -> dict[str, str]:
    return SECTION_LABELS[consultation_type]


def document_title(consultation_type: ConsultationType) -> str:
    return DOCUMENT_TITLES[consultation_type]


def fhir_composition_type(consultation_type: ConsultationType) -> dict[str, str]:
    return FHIR_LOINC[consultation_type]
