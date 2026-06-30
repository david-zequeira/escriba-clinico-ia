"""Excepciones del dominio. La capa API las traduce a códigos HTTP."""
from __future__ import annotations


class DomainError(Exception):
    """Base de errores de negocio."""


class ConsultationNotFound(DomainError):
    pass


class InvalidStateTransition(DomainError):
    pass


class AudioNotAvailable(DomainError):
    pass
