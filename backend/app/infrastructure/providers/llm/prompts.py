"""Prompts de estructuración por tipo de documento. Anti-alucinación NO negociable."""
from __future__ import annotations

from app.domain.document_templates import section_labels
from app.domain.enums import ConsultationType

_BASE_RULES = (
    "Tu tarea es EXTRAER y RESUMIR en cada campo lo que realmente se dijo en la "
    "transcripción, redactado en español clínico, en tercera persona y con el estilo "
    "habitual de un hospital de la Unión Europea. Resumir o parafrasear lo que aparece "
    "en la transcripción NO es inventar: es justo lo que debes hacer. Reglas: "
    "(1) Rellena cada campo con la información relevante que se haya mencionado; usa "
    "la sección que mejor corresponda a cada dato. "
    "(2) Deja el contenido vacío ('') SOLO si en la transcripción no se dijo nada que "
    "encaje en esa sección; no fuerces texto donde no hay información. "
    "(3) NO añadas datos que no aparezcan (diagnósticos, dosis, antecedentes o "
    "exploraciones no mencionados). "
    "(4) Marca needs_confirmation=true cuando un dato sea ambiguo, dudoso, incompleto "
    "o no esté verbalizado con claridad. "
    "(5) No tomas decisiones diagnósticas ni terapéuticas autónomas: redactas un "
    "borrador administrativo que el médico revisará y validará."
)

_TYPE_INTROS: dict[ConsultationType, str] = {
    ConsultationType.admission_interview: (
        "Documento: historia clínica de ingreso (LOINC 47039-3). "
        "Entrevista médico-paciente. Incluye motivo de ingreso, enfermedad actual, "
        "antecedentes (alergias y medicación si se mencionan), exploración, "
        "pruebas complementarias citadas, juicio clínico y plan."
    ),
    ConsultationType.treatment_orders: (
        "Documento: indicaciones médicas de tratamiento (LOINC 18776-5). "
        "Dictado del médico para paciente ingresado. "
        "Separa farmacológicas, no farmacológicas, vigilancia y observaciones. "
        "Si se mencionan fármaco, dosis, vía o frecuencia, inclúyelos en el texto."
    ),
    ConsultationType.evolution: (
        "Documento: nota de evolución (LOINC 11506-3). "
        "Formato SOAP: subjetivo, objetivo/exploración, evolución, juicio clínico y plan."
    ),
}


def get_system_prompt(consultation_type: ConsultationType) -> str:
    labels = section_labels(consultation_type)
    sections_desc = ", ".join(f'"{k}" ({v})' for k, v in labels.items())
    intro = _TYPE_INTROS[consultation_type]
    return (
        f"Eres un asistente de documentación clínica (producto de apoyo administrativo, Clase I). "
        f"{intro} "
        f"Rellena el JSON con exactamente estos campos: {sections_desc}. "
        f"{_BASE_RULES}"
    )
