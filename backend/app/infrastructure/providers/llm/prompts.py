"""Prompts de estructuración por tipo de documento. Anti-alucinación NO negociable."""
from __future__ import annotations

from app.domain.document_templates import section_labels
from app.domain.enums import ConsultationType

_BASE_RULES = (
    "Tu tarea es EXTRAER y RESUMIR en cada campo ÚNICAMENTE lo que se dijo de forma "
    "explícita en la transcripción, redactado en español clínico, en tercera persona "
    "y con el estilo habitual de un hospital de la Unión Europea. Reformular o "
    "resumir lo dicho está bien; AÑADIR, INFERIR o COMPLETAR información no dicha NO. "
    "Reglas ESTRICTAS (anti-alucinación, no negociables): "
    "(1) Usa solo datos verbalizados. Cíñete a lo dicho: NO añadas matices ni "
    "interpretaciones que el interlocutor no haya expresado —p. ej. gravedad o "
    "cualidades ('leve', 'intenso'), duración o evolución no dichas, etiquetas como "
    "'inespecífico' o 'empírico', o interpretaciones como 'automedicación'. Si el "
    "paciente dijo 'me duele un poco la cabeza', escribe eso, no 'cefalea leve'. "
    "(2) Si en la transcripción no se dijo nada que encaje en una sección, deja su "
    "contenido EXACTAMENTE vacío (''). NUNCA narres ausencias ni lo que NO se dijo "
    "(prohibido escribir 'no se refieren alergias', 'no se aportan más detalles', "
    "'sin antecedentes conocidos', etc.): si no se dijo, el campo va vacío. "
    "(3) NO inventes diagnósticos, dosis, antecedentes, exploraciones ni pruebas. "
    "(4) Marca needs_confirmation=true cuando un dato sea ambiguo, dudoso, incompleto "
    "o no esté verbalizado con claridad. "
    "(5) No tomas decisiones diagnósticas ni terapéuticas autónomas: redactas un "
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
        f"{_BASE_RULES} "
        f"{_EXAMPLE}"
    )
