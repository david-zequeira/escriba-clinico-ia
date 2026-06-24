"""Registro de auditoría inmutable (requisito RGPD/MDR). STUB: persistir en almacenamiento propio UE."""
import logging
from datetime import datetime

logger = logging.getLogger("audit")


def log_event(actor: str, action: str, consultation_id: str, detail: str = "") -> None:
    logger.info(
        "%s | actor=%s action=%s consultation=%s detail=%s",
        datetime.utcnow().isoformat(), actor, action, consultation_id, detail,
    )
