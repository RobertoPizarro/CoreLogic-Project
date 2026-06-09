"""
Router de FastAPI para el Módulo de Reportes Analíticos.
"""

from typing import Optional
from fastapi import APIRouter, Depends, Query
from app.core.auth import obtener_usuario_actual, DatosUsuario
from app.schemas.reportes import ResumenResponse, DistribucionResponse
from app.services import reportes_service

router = APIRouter(prefix="/reportes", tags=["Reportes"])


@router.get("", response_model=ResumenResponse)
async def obtener_resumen(
    vista: str = Query(..., description="Vista temporal: diaria, semanal o mensual"),
    mes: Optional[str] = Query(None, description="Mes del reporte en formato YYYY-MM"),
    anio: Optional[int] = Query(None, description="Año del reporte en formato YYYY"),
    usuario: DatosUsuario = Depends(obtener_usuario_actual),
):
    """
    Obtiene el resumen financiero con ingresos, gastos y balances agrupados por períodos temporales.
    """
    return await reportes_service.obtener_resumen_periodos(
        user_id=usuario.user_id,
        vista=vista,
        mes=mes,
        anio=anio,
    )


@router.get("/categorias", response_model=DistribucionResponse)
async def obtener_distribucion_categorias(
    vista: str = Query(..., description="Vista temporal: diaria, semanal o mensual"),
    tipo: str = Query("expense", description="Tipo de movimientos: income o expense"),
    mes: Optional[str] = Query(None, description="Mes del reporte en formato YYYY-MM"),
    anio: Optional[int] = Query(None, description="Año del reporte en formato YYYY"),
    usuario: DatosUsuario = Depends(obtener_usuario_actual),
):
    """
    Obtiene la distribución porcentual y montos por categoría de ingresos o gastos.
    """
    return await reportes_service.obtener_distribucion_categorias(
        user_id=usuario.user_id,
        vista=vista,
        tipo=tipo,
        mes=mes,
        anio=anio,
    )
