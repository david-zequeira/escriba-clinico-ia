"""LLM simulado para desarrollo y tests. Borradores tipados por ConsultationType."""
from __future__ import annotations

import asyncio

from app.domain.clinical_documents import (
    AdmissionNote,
    ClinicalDraft,
    EvolutionNote,
    TreatmentOrdersNote,
)
from app.domain.enums import ConsultationType
from app.domain.ports import LLMProvider
from app.domain.value_objects import ClinicalSection, Transcript


class MockLLMProvider(LLMProvider):
    name = "mock-llm"

    async def assign_speakers(
        self,
        texts: list[str],
        consultation_type: ConsultationType = ConsultationType.admission_interview,
    ) -> list[str]:
        await asyncio.sleep(0)
        if consultation_type != ConsultationType.admission_interview:
            return ["medico"] * len(texts)
        # Alternancia médico→paciente→… (el guion empieza con el médico).
        return ["medico" if i % 2 == 0 else "paciente" for i in range(len(texts))]

    async def structure_note(
        self,
        transcript: Transcript,
        consultation_type: ConsultationType = ConsultationType.admission_interview,
        specialty: str = "general",
    ) -> ClinicalDraft:
        _ = (transcript, specialty)
        await asyncio.sleep(0)
        if consultation_type == ConsultationType.admission_interview:
            return AdmissionNote(
                motivo_ingreso=ClinicalSection(content="Dolor torácico."),
                enfermedad_actual=ClinicalSection(
                    content="Opresión retroesternal de 2 horas.",
                    needs_confirmation=True,
                ),
                antecedentes=ClinicalSection(content="Sin alergias referidas."),
                exploracion_fisica=ClinicalSection(content="", needs_confirmation=True),
                pruebas_complementarias=ClinicalSection(content=""),
                juicio_clinico=ClinicalSection(content="", needs_confirmation=True),
                plan=ClinicalSection(content=""),
                model_name=self.name,
            )
        if consultation_type == ConsultationType.treatment_orders:
            return TreatmentOrdersNote(
                contexto=ClinicalSection(content="Paciente ingresado en planta."),
                indicaciones_farmacologicas=ClinicalSection(
                    content="Paracetamol 1 g cada 8 horas si dolor."
                ),
                indicaciones_no_farmacologicas=ClinicalSection(content="Dieta blanda."),
                vigilancia=ClinicalSection(content="Constantes cada 8 horas."),
                observaciones=ClinicalSection(content="Revalorar mañana."),
                model_name=self.name,
            )
        return EvolutionNote(
            subjetivo=ClinicalSection(content="Refiere mejoría del dolor."),
            objetivo=ClinicalSection(content="Hemodinámicamente estable. Afebril."),
            evolucion=ClinicalSection(content="Evolución favorable."),
            juicio_clinico=ClinicalSection(content="Cuadro en resolución."),
            plan=ClinicalSection(content="Mantener tratamiento. Analítica mañana."),
            model_name=self.name,
        )
