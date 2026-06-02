"""
Router de Presupuestos Personales.
CRUD completo con validación de solapamiento y cálculo de consumo en tiempo real.
"""

from typing import Optional

from fastapi import APIRouter, Depends, Query

from app.core.auth import obtener_usuario_actual, DatosUsuario
from app.schemas.presupuestos import (
    PresupuestoCreate,
    PresupuestoUpdate,
    PresupuestoResponse,
)
from app.services import presupuestos_service

router = APIRouter(prefix="/presupuestos", tags=["Presupuestos"])


@router.get("", response_model=list[PresupuestoResponse])
async def listar_presupuestos(
    busqueda: Optional[str] = Query(None),
    usuario: DatosUsuario = Depends(obtener_usuario_actual),
):
    """Lista todos los presupuestos del usuario (activos, próximos y vencidos)."""
    return await presupuestos_service.listar_presupuestos(usuario.user_id, busqueda)


@router.get("/{presupuesto_id}", response_model=PresupuestoResponse)
async def obtener_presupuesto(
    presupuesto_id: str,
    usuario: DatosUsuario = Depends(obtener_usuario_actual),
):
    """Obtiene el detalle de un presupuesto con consumo calculado."""
    return await presupuestos_service.obtener_presupuesto(usuario.user_id, presupuesto_id)


@router.post("", response_model=PresupuestoResponse, status_code=201)
async def crear_presupuesto(
    datos: PresupuestoCreate,
    usuario: DatosUsuario = Depends(obtener_usuario_actual),
):
    """Crea un nuevo presupuesto personal."""
    return await presupuestos_service.crear_presupuesto(
        user_id=usuario.user_id,
        descripcion=datos.description,
        monto=datos.amount,
        category_id=datos.category_id,
        start_date=datos.start_date,
        end_date=datos.end_date,
    )


@router.put("/{presupuesto_id}", response_model=PresupuestoResponse)
async def editar_presupuesto(
    presupuesto_id: str,
    datos: PresupuestoUpdate,
    usuario: DatosUsuario = Depends(obtener_usuario_actual),
):
    """Edita un presupuesto existente (cualquier estado)."""
    return await presupuestos_service.editar_presupuesto(
        user_id=usuario.user_id,
        presupuesto_id=presupuesto_id,
        descripcion=datos.description,
        monto=datos.amount,
        category_id=datos.category_id,
        start_date=datos.start_date,
        end_date=datos.end_date,
    )


@router.delete("/{presupuesto_id}", status_code=204)
async def eliminar_presupuesto(
    presupuesto_id: str,
    usuario: DatosUsuario = Depends(obtener_usuario_actual),
):
    """Elimina un presupuesto. Los gastos asociados persisten."""
    await presupuestos_service.eliminar_presupuesto(usuario.user_id, presupuesto_id)
