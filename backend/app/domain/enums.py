"""Estados del ciclo de vida y tipos de documento clínico."""
from __future__ import annotations

from enum import Enum


class ConsultationType(str, Enum):
    """Tipo de documento clínico (casos de uso del MVP).

    admission_interview — Entrevista médico-paciente para historia de ingreso.
    treatment_orders    — Indicaciones de tratamiento dictadas solo por el médico.
    evolution           — Nota de evolución de paciente ya ingresado.
    """

    admission_interview = "admission_interview"
    treatment_orders = "treatment_orders"
    evolution = "evolution"


class ConsultationStatus(str, Enum):
    """Máquina de estados del procesamiento asíncrono.

    created          -> consulta abierta, sin audio aún
    queued           -> audio recibido, job encolado
    processing_stt   -> transcribiendo
    processing_llm   -> estructurando borrador
    completed        -> borrador listo para revisión médica
    validated        -> el médico validó la nota (humano en el bucle)
    failed           -> error en el procesamiento
    """

    created = "created"
    queued = "queued"
    processing_stt = "processing_stt"
    processing_llm = "processing_llm"
    completed = "completed"
    validated = "validated"
    failed = "failed"
