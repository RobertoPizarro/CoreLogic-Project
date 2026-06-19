"""
Schemas Pydantic para el módulo de autenticación y perfil.
"""

from pydantic import BaseModel
from datetime import datetime


class RegistroRequest(BaseModel):
    """Request para crear perfil tras registro exitoso en Supabase Auth."""
    full_name: str


class PerfilResponse(BaseModel):
    """Response con datos del perfil del usuario."""
    id: str
    full_name: str
    email: str


class RegistroResponse(BaseModel):
    """Response tras crear el perfil."""
    id: str
    full_name: str
    created_at: datetime
