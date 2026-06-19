"""
Schemas Pydantic para el módulo de reportes analíticos de movimientos.
"""

from pydantic import BaseModel
from datetime import date
from typing import List, Optional


class RangoFechas(BaseModel):
    """Estructura para representar un rango de fechas de inicio y fin."""
    desde: date
    hasta: date


class PeriodoResumen(BaseModel):
    """Resumen financiero acumulado de un periodo de tiempo específico."""
    label: str
    rango_fechas: RangoFechas
    total_ingresos: float
    total_gastos: float
    balance: float


class ResumenResponse(BaseModel):
    """Response completa con la lista de resúmenes periódicos."""
    vista: str
    mes: Optional[str] = None
    anio: Optional[int] = None
    periodos: List[PeriodoResumen]


class CategoriaDistribucion(BaseModel):
    """Detalle de gastos o ingresos distribuidos para una categoría específica."""
    category_id: str
    name: str
    icon: str
    amount: float
    percentage: float


class DistribucionResponse(BaseModel):
    """Response completa con la distribución por categorías."""
    vista: str
    mes: Optional[str] = None
    anio: Optional[int] = None
    tipo: str
    total_monto: float
    categorias: List[CategoriaDistribucion]
