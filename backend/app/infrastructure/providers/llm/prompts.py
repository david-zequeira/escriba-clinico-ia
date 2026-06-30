"""Prompts de estructuración por tipo de documento. Anti-alucinación NO negociable."""
from __future__ import annotations

from app.domain.document_templates import section_labels
from app.domain.enums import ConsultationType

_BASE_RULES = (
    "Tu tarea es RELLENAR cada campo del JSON RESUMIENDO en español clínico (tercera "
    "persona, estilo de un hospital de la Unión Europea) lo que se dijo en la "
    "transcripción. Resumir o parafrasear lo dicho ES lo que debes hacer y NO es "
    "inventar: si el paciente refiere un síntoma, ESE síntoma debe aparecer en el "
    "campo que le corresponda. Reglas: "
    "(1) RELLENA cada campo con la información dicha que le corresponda y coloca cada "
    "dato en su sección (ver descripción de cada sección arriba). "
    "(2) Deja un campo vacío ('') SOLO si en la transcripción no se dijo NADA que "
    "encaje en él. NUNCA vacíes un campo para el que SÍ hay información dicha. "
    "(3) Anti-alucinación (no negociable): NO inventes ni añadas datos no dichos "
    "(diagnósticos, dosis, antecedentes, exploraciones o pruebas no mencionados) ni "
    "matices no expresados ('leve', 'intenso', 'inespecífico', 'empírico'). Si el "
    "paciente dijo 'me duele un poco la cabeza', escribe eso, no 'cefalea leve'. "
    "(4) NO narres ausencias ni lo que NO se dijo (prohibido 'no se refieren "
    "alergias', 'sin antecedentes conocidos', 'no se menciona fiebre'): si no se dijo, "
    "el campo va vacío, sin comentarios. "
    "(5) Marca needs_confirmation=true cuando un dato sea ambiguo, dudoso o incompleto. "
    "(6) No tomas decisiones diagnósticas ni terapéuticas autónomas: redactas un "
    "borrador administrativo que el médico revisará y validará."
)

_EXAMPLE = (
    "Ejemplo (incorrecto vs. correcto):\n"
    "Transcripción: 'paciente: me duele un poco la cabeza. médico: ¿algo más?'.\n"
    "INCORRECTO — inventa matices y narra ausencias: "
    "enfermedad_actual='Cefalea leve de carácter inespecífico.'; "
    "antecedentes='No se refieren alergias ni medicación habitual.'\n"
    "CORRECTO — solo lo dicho, sin ausencias: "
    "enfermedad_actual='El paciente refiere dolor de cabeza.'; "
    "antecedentes='' (vacío, porque no se mencionó ningún antecedente)."
)

_TYPE_INTROS: dict[ConsultationType, str] = {
    ConsultationType.admission_interview: (
        "Documento: historia clínica de ingreso (LOINC 47039-3). Entrevista "
        "médico-paciente. Coloca cada dato en su sección: "
        "motivo_ingreso = razón principal de la consulta en una frase (los síntomas "
        "que trae el paciente); "
        "enfermedad_actual = síntomas actuales que refiere el paciente y su relato "
        "(localización, inicio, etc., solo si se dicen); "
        "antecedentes = SOLO enfermedades, alergias o medicación PREVIAS y explícitas "
        "(NUNCA los síntomas actuales); "
        "exploracion_fisica = hallazgos explorados por el médico; "
        "pruebas_complementarias = pruebas citadas; "
        "juicio_clinico = impresión diagnóstica si se expresa; "
        "plan = lo que se decide hacer (pruebas, tratamiento, ingreso)."
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
        f"{_BASE_RULES} "
        f"{_EXAMPLE}"
    )
