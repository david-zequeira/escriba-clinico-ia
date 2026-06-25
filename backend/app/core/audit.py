"""Registro de auditoría (requisito RGPD/MDR). STUB: persistir en almacén inmutable UE."""
from __future__ import annotations

import logging

logger = logging.getLogger("vionix.audit")


def log_event(actor: str, action: str, consultation_id: str, detail: str = "") -> None:
    """Traza quién hizo qué y cuándo. Nunca registrar datos clínicos en claro."""
    logger.info(
        "actor=%s action=%s consultation=%s detail=%s",
        actor,
        action,
        consultation_id,
        detail,
    )
