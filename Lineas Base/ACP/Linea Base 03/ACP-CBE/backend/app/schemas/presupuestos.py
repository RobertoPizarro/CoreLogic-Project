"""
Schemas Pydantic para el módulo de presupuestos personales.
"""

from pydantic import BaseModel, field_validator, model_validator
from datetime import date
from typing import Optional


class PresupuestoCreate(BaseModel):
    """Request para crear un nuevo presupuesto personal."""
    description: str
    amount: float
    category_id: str
    start_date: date
    end_date: date

    @field_validator("amount")
    @classmethod
    def validar_monto(cls, v):
        if v <= 0:
            raise ValueError("El monto debe ser mayor a 0.")
        return v

    @model_validator(mode="after")
    def validar_fechas(self):
        if self.start_date > self.end_date:
            raise ValueError("La fecha de inicio no puede ser posterior a la fecha de fin.")
        return self


class PresupuestoUpdate(BaseModel):
    """Request para editar un presupuesto existente."""
    description: str
    amount: float
    category_id: str
    start_date: date
    end_date: date

    @field_validator("amount")
    @classmethod
    def validar_monto(cls, v):
        if v <= 0:
            raise ValueError("El monto debe ser mayor a 0.")
        return v

    @model_validator(mode="after")
    def validar_fechas(self):
        if self.start_date > self.end_date:
            raise ValueError("La fecha de inicio no puede ser posterior a la fecha de fin.")
        return self


class PresupuestoResponse(BaseModel):
    """Response con los datos de un presupuesto, incluyendo valores calculados."""
    id: str
    description: str
    category: str  # Nombre de la categoría
    category_id: str
    icon: str  # Ícono de la categoría
    amount: float
    consumed: float  # Monto consumido (calculado en tiempo real)
    remaining: float  # Monto restante (puede ser negativo)
    percentage_used: float  # Porcentaje de uso (puede superar 100)
    start_date: date
    end_date: date
    status: str  # 'activo', 'proximo', 'vencido'
