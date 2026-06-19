"""
Schemas Pydantic para el módulo de grupos y gastos compartidos.
"""

from pydantic import BaseModel, field_validator
from datetime import date, datetime
from typing import Optional


# --- Grupos ---

class GrupoCreate(BaseModel):
    """Request para crear un nuevo grupo."""
    name: str
    emails: list[str] = []  # Correos de miembros a invitar

    @field_validator("name")
    @classmethod
    def validar_nombre(cls, v):
        if not v or not v.strip():
            raise ValueError("El nombre del grupo es obligatorio.")
        return v.strip()


class InvitarMiembroRequest(BaseModel):
    """Request para invitar a un miembro por correo."""
    email: str

    @field_validator("email")
    @classmethod
    def validar_email(cls, v):
        if not v or "@" not in v:
            raise ValueError("El correo electrónico no es válido.")
        return v.strip().lower()


class MiembroResponse(BaseModel):
    """Datos de un miembro del grupo."""
    user_id: str
    name: str
    status: str  # 'activo' o 'pendiente'


class BalanceResumen(BaseModel):
    """Resumen del balance del usuario en un grupo (para la lista)."""
    status: str  # 'debes', 'te_deben', 'saldado', 'pendiente_invitacion'
    amount: Optional[float] = None
    to: Optional[str] = None  # Nombre de la persona (solo si status es 'debes' o 'te_deben')


class GrupoListItem(BaseModel):
    """Un grupo en la lista de grupos del usuario."""
    id: str
    name: str
    members: list[MiembroResponse]
    my_balance_summary: BalanceResumen


# --- Gastos Compartidos ---

class SplitItem(BaseModel):
    """Un participante en la división del gasto."""
    user_id: str
    amount_owed: float
    percentage: Optional[float] = None  # Solo para split_type = 'porcentaje'


class GastoCompartidoCreate(BaseModel):
    """Request para crear un gasto compartido."""
    description: str
    total_amount: float
    paid_by: str  # user_id de quien pagó
    date: date
    split_type: str  # 'igual', 'porcentaje', 'personalizado'
    participants: list[str]  # Lista de user_ids que participan
    splits: Optional[list[SplitItem]] = None  # Obligatorio para porcentaje y personalizado

    @field_validator("total_amount")
    @classmethod
    def validar_monto(cls, v):
        if v <= 0:
            raise ValueError("El monto debe ser mayor a 0.")
        return v

    @field_validator("split_type")
    @classmethod
    def validar_tipo_division(cls, v):
        if v not in ("igual", "porcentaje", "personalizado"):
            raise ValueError("El tipo de división debe ser 'igual', 'porcentaje' o 'personalizado'.")
        return v

    @field_validator("description")
    @classmethod
    def validar_descripcion(cls, v):
        if not v or not v.strip():
            raise ValueError("La descripción es obligatoria.")
        return v.strip()


class GastoCompartidoUpdate(GastoCompartidoCreate):
    """Request para editar un gasto compartido (mismos campos que Create)."""
    pass


class SplitResponse(BaseModel):
    """Detalle de la parte de un participante en un gasto."""
    user_id: str
    name: str
    amount_owed: float


class PaidByResponse(BaseModel):
    """Datos de quien pagó un gasto."""
    user_id: str
    name: str


class GastoCompartidoResponse(BaseModel):
    """Response con los datos de un gasto compartido."""
    id: str
    group_id: str
    description: str
    total_amount: float
    paid_by: PaidByResponse
    date: date
    split_type: Optional[str] = None
    splits: Optional[list[SplitResponse]] = None
    created_at: Optional[datetime] = None


class GastoListItem(BaseModel):
    """Un gasto en la lista de gastos del grupo."""
    id: str
    description: str
    total_amount: float
    paid_by: PaidByResponse
    date: date
    created_at: Optional[datetime] = None


# --- Balances ---

class BalanceMiembro(BaseModel):
    """Balance neto de un miembro del grupo."""
    user_id: str
    name: str
    paid: float
    net: float


class DeudaItem(BaseModel):
    """Una deuda del usuario hacia otro miembro."""
    to_user_id: str
    to_name: str
    amount: float


class DeudorItem(BaseModel):
    """Un deudor que le debe al usuario."""
    from_user_id: str
    from_name: str
    amount: float


class BalancesResponse(BaseModel):
    """Response completa de balances de un grupo."""
    group_id: str
    total_group: float
    last_updated: Optional[datetime] = None
    member_balances: list[BalanceMiembro]
    my_debts: list[DeudaItem]
    owed_to_me: list[DeudorItem]


# --- Pagos ---

class PagoCreate(BaseModel):
    """Request para registrar un pago entre miembros."""
    to_user_id: str
    amount: float
    date: date
    note: Optional[str] = None

    @field_validator("amount")
    @classmethod
    def validar_monto(cls, v):
        if v <= 0:
            raise ValueError("El monto debe ser mayor a 0.")
        return round(v, 2)


class PagoResponse(BaseModel):
    """Response de un pago registrado."""
    id: str
    group_id: str
    from_user_id: str
    from_name: str
    to_user_id: str
    to_name: str
    amount: float
    note: Optional[str] = None
    date: date
    created_at: Optional[datetime] = None
