"""
Schemas Pydantic para el módulo de movimientos personales (ingresos y gastos).
"""

from pydantic import BaseModel, field_validator
from datetime import date
from typing import Optional


class MovimientoCreate(BaseModel):
    """Request para crear un nuevo movimiento personal."""
    type: str  # 'income' o 'expense'
    amount: float
    category_id: str
    date: date
    description: Optional[str] = None
    payment_method: str  # 'efectivo', 'tarjeta', 'transferencia'

    @field_validator("type")
    @classmethod
    def validar_tipo(cls, v):
        if v not in ("income", "expense"):
            raise ValueError("El tipo debe ser 'income' o 'expense'.")
        return v

    @field_validator("amount")
    @classmethod
    def validar_monto(cls, v):
        if v <= 0:
            raise ValueError("El monto debe ser mayor a 0.")
        return v

    @field_validator("payment_method")
    @classmethod
    def validar_metodo_pago(cls, v):
        if v not in ("efectivo", "tarjeta", "transferencia"):
            raise ValueError("Método de pago inválido. Use: efectivo, tarjeta o transferencia.")
        return v


class MovimientoUpdate(BaseModel):
    """Request para editar un movimiento existente."""
    type: str
    amount: float
    category_id: str
    date: date
    description: Optional[str] = None
    payment_method: str

    @field_validator("type")
    @classmethod
    def validar_tipo(cls, v):
        if v not in ("income", "expense"):
            raise ValueError("El tipo debe ser 'income' o 'expense'.")
        return v

    @field_validator("amount")
    @classmethod
    def validar_monto(cls, v):
        if v <= 0:
            raise ValueError("El monto debe ser mayor a 0.")
        return v

    @field_validator("payment_method")
    @classmethod
    def validar_metodo_pago(cls, v):
        if v not in ("efectivo", "tarjeta", "transferencia"):
            raise ValueError("Método de pago inválido. Use: efectivo, tarjeta o transferencia.")
        return v


class MovimientoResponse(BaseModel):
    """Response con los datos de un movimiento."""
    id: str
    type: str
    amount: float
    description: Optional[str] = None
    category: str  # Nombre de la categoría
    category_id: str
    icon: str  # Ícono de la categoría
    date: date
    payment_method: str


class EvaluarPresupuestoRequest(BaseModel):
    """Request para evaluar si un gasto excede un presupuesto activo."""
    category_id: str
    amount: float
    date: date
    movement_id: Optional[str] = None  # Se envía al editar para excluirse del cálculo

    @field_validator("amount")
    @classmethod
    def validar_monto(cls, v):
        if v <= 0:
            raise ValueError("El monto debe ser mayor a 0.")
        return v


class EvaluarPresupuestoResponse(BaseModel):
    """Response de la evaluación de presupuesto."""
    excede_presupuesto: bool
    presupuesto_descripcion: Optional[str] = None
    monto_exceso: Optional[float] = None
