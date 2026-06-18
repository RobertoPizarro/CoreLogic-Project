"""
Router de Movimientos Personales.
CRUD completo de ingresos y gastos + evaluación de presupuesto.
"""

from typing import Optional

from fastapi import APIRouter, Depends, Query

from app.core.auth import obtener_usuario_actual, DatosUsuario
from app.schemas.movimientos import (
    MovimientoCreate,
    MovimientoUpdate,
    MovimientoResponse,
    EvaluarPresupuestoRequest,
    EvaluarPresupuestoResponse,
)
from app.services import movimientos_service

router = APIRouter(prefix="/movimientos", tags=["Movimientos"])


@router.get("", response_model=list[MovimientoResponse])
async def listar_movimientos(
    tipo: Optional[str] = Query(None, alias="type"),
    busqueda: Optional[str] = Query(None),
    mes: Optional[int] = Query(None),
    anio: Optional[int] = Query(None),
    category_id: Optional[str] = Query(None),
    limit: int = Query(10, ge=1, le=100),
    offset: int = Query(0, ge=0),
    usuario: DatosUsuario = Depends(obtener_usuario_actual),
):
    """Lista movimientos con filtros opcionales y paginación."""
    return await movimientos_service.listar_movimientos(
        user_id=usuario.user_id,
        tipo=tipo,
        busqueda=busqueda,
        mes=mes,
        anio=anio,
        category_id=category_id,
        limit=limit,
        offset=offset,
    )


@router.get("/{movimiento_id}", response_model=MovimientoResponse)
async def obtener_movimiento(
    movimiento_id: str,
    usuario: DatosUsuario = Depends(obtener_usuario_actual),
):
    """Obtiene el detalle de un movimiento."""
    return await movimientos_service.obtener_movimiento(usuario.user_id, movimiento_id)


@router.post("", response_model=MovimientoResponse, status_code=201)
async def crear_movimiento(
    datos: MovimientoCreate,
    usuario: DatosUsuario = Depends(obtener_usuario_actual),
):
    """Crea un nuevo movimiento personal (ingreso o gasto)."""
    return await movimientos_service.crear_movimiento(
        user_id=usuario.user_id,
        tipo=datos.type,
        monto=datos.amount,
        category_id=datos.category_id,
        fecha=datos.date,
        descripcion=datos.description,
        metodo_pago=datos.payment_method,
    )


@router.put("/{movimiento_id}", response_model=MovimientoResponse)
async def editar_movimiento(
    movimiento_id: str,
    datos: MovimientoUpdate,
    usuario: DatosUsuario = Depends(obtener_usuario_actual),
):
    """Edita un movimiento existente."""
    return await movimientos_service.editar_movimiento(
        user_id=usuario.user_id,
        movimiento_id=movimiento_id,
        tipo=datos.type,
        monto=datos.amount,
        category_id=datos.category_id,
        fecha=datos.date,
        descripcion=datos.description,
        metodo_pago=datos.payment_method,
    )


@router.delete("/{movimiento_id}", status_code=204)
async def eliminar_movimiento(
    movimiento_id: str,
    usuario: DatosUsuario = Depends(obtener_usuario_actual),
):
    """Elimina un movimiento personal."""
    await movimientos_service.eliminar_movimiento(usuario.user_id, movimiento_id)


@router.post("/evaluar-presupuesto", response_model=EvaluarPresupuestoResponse)
async def evaluar_presupuesto(
    datos: EvaluarPresupuestoRequest,
    usuario: DatosUsuario = Depends(obtener_usuario_actual),
):
    """Evalúa si un gasto excede algún presupuesto activo antes de guardarlo."""
    return await movimientos_service.evaluar_presupuesto(
        user_id=usuario.user_id,
        category_id=datos.category_id,
        monto=datos.amount,
        fecha=datos.date,
        movement_id=datos.movement_id,
    )
