"""Smoke-test del LLM real (Mistral): transcripción de ejemplo → borrador estructurado.

Valida de extremo a extremo, sin levantar el servidor, que el provider Mistral
estructura una conversación en un borrador clínico que REFLEJA lo dicho (y no
inventa: las secciones sin información quedan vacías).

Requisitos (en `backend/.env` o por entorno):
    LLM_PROVIDER=mistral
    LLM_API_KEY=...            # https://console.mistral.ai  (residencia UE)
    LLM_MODEL=mistral-small-latest   # opcional

Uso:
    cd backend && source .venv/bin/activate
    python -m scripts.smoke_mistral

Nada de esto persiste datos ni sube audio: es una llamada puntual al LLM.
"""
from __future__ import annotations

import asyncio
import sys

from app.core.config import settings
from app.domain.clinical_documents import iter_clinical_sections
from app.domain.enums import ConsultationType
from app.domain.value_objects import Transcript, TranscriptSegment
from app.infrastructure.providers.llm.factory import get_llm_provider

# Conversación de ejemplo (datos ficticios, sin PHI real).
_SAMPLE = Transcript(
    language="es",
    segments=[
        TranscriptSegment(speaker="medico", text="Buenos días, ¿qué le trae por aquí?"),
        TranscriptSegment(
            speaker="paciente",
            text="Llevo dos días con dolor en el pecho cuando subo escaleras.",
        ),
        TranscriptSegment(speaker="medico", text="¿Ese dolor se va al descansar?"),
        TranscriptSegment(speaker="paciente", text="Sí, en cuanto paro se me pasa."),
        TranscriptSegment(speaker="medico", text="¿Tiene alergias a algún medicamento?"),
        TranscriptSegment(speaker="paciente", text="No, ninguna que yo sepa."),
    ],
)


async def _run() -> int:
    if settings.LLM_PROVIDER.lower() != "mistral":
        print(
            "✖ LLM_PROVIDER no es 'mistral' (es "
            f"'{settings.LLM_PROVIDER}'). Configúralo en backend/.env.",
            file=sys.stderr,
        )
        return 1
    if not settings.LLM_API_KEY:
        print("✖ Falta LLM_API_KEY en backend/.env.", file=sys.stderr)
        return 1

    provider = get_llm_provider()
    print(f"▶ Estructurando con {provider.name} (modelo {settings.LLM_MODEL})…\n")

    draft = await provider.structure_note(
        _SAMPLE, consultation_type=ConsultationType.admission_interview
    )

    print(f"Documento: entrevista de ingreso · IA={draft.generated_by_ai}\n")
    for name, section in iter_clinical_sections(draft):
        marca = "  ⚠ pendiente de confirmar" if section.needs_confirmation else ""
        contenido = section.content.strip() or "(vacío)"
        print(f"── {name} ──{marca}\n{contenido}\n")

    print("✅ Smoke-test completado. Revisa que el borrador refleje la conversación.")
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(_run()))
