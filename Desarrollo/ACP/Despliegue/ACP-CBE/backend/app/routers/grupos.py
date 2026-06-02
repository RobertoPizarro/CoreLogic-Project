"""
Router de Grupos y Gastos Compartidos.
CRUD de grupos, gastos compartidos, balances y pagos.
"""

from typing import Optional

from fastapi import APIRouter, Depends, Query

from app.core.auth import obtener_usuario_actual, DatosUsuario
from app.schemas.grupos import (
    GrupoCreate, InvitarMiembroRequest, GrupoListItem,
    GastoCompartidoCreate, GastoCompartidoUpdate, GastoCompartidoResponse,
    BalancesResponse, PagoCreate, PagoResponse,
)
from app.services import grupos_service

router = APIRouter(prefix="/grupos", tags=["Grupos"])


@router.get("")
async def listar_grupos(
    busqueda: Optional[str] = Query(None),
    usuario: DatosUsuario = Depends(obtener_usuario_actual),
):
    """Lista los grupos del usuario (activos + invitaciones pendientes)."""
    grupos = await grupos_service.listar_grupos(usuario.user_id, busqueda)
    return {"grupos": grupos}


@router.post("", status_code=201)
async def crear_grupo(datos: GrupoCreate, usuario: DatosUsuario = Depends(obtener_usuario_actual)):
    """Crea un nuevo grupo e invita miembros."""
    return await grupos_service.crear_grupo(usuario.user_id, datos.name, datos.emails)


@router.post("/{group_id}/invitar")
async def invitar_miembro(group_id: str, datos: InvitarMiembroRequest, usuario: DatosUsuario = Depends(obtener_usuario_actual)):
    """Invita a un miembro al grupo por correo electrónico."""
    return await grupos_service.invitar_miembro(usuario.user_id, group_id, datos.email)


@router.post("/{group_id}/unirse")
async def unirse_a_grupo(group_id: str, usuario: DatosUsuario = Depends(obtener_usuario_actual)):
    """Acepta la invitación a un grupo."""
    return await grupos_service.unirse_a_grupo(usuario.user_id, group_id)


@router.get("/{group_id}/gastos")
async def listar_gastos(group_id: str, usuario: DatosUsuario = Depends(obtener_usuario_actual)):
    """Lista los gastos de un grupo."""
    return await grupos_service.listar_gastos(usuario.user_id, group_id)


@router.post("/{group_id}/gastos", status_code=201)
async def crear_gasto(group_id: str, datos: GastoCompartidoCreate, usuario: DatosUsuario = Depends(obtener_usuario_actual)):
    """Registra un nuevo gasto compartido."""
    return await grupos_service.crear_gasto(usuario.user_id, group_id, datos.model_dump())


@router.get("/{group_id}/gastos/{gasto_id}")
async def obtener_gasto(group_id: str, gasto_id: str, usuario: DatosUsuario = Depends(obtener_usuario_actual)):
    """Obtiene el detalle de un gasto compartido."""
    return await grupos_service.obtener_gasto(usuario.user_id, group_id, gasto_id)


@router.put("/{group_id}/gastos/{gasto_id}")
async def editar_gasto(group_id: str, gasto_id: str, datos: GastoCompartidoUpdate, usuario: DatosUsuario = Depends(obtener_usuario_actual)):
    """Edita un gasto compartido existente."""
    return await grupos_service.editar_gasto(usuario.user_id, group_id, gasto_id, datos.model_dump())


@router.delete("/{group_id}/gastos/{gasto_id}", status_code=204)
async def eliminar_gasto(group_id: str, gasto_id: str, usuario: DatosUsuario = Depends(obtener_usuario_actual)):
    """Elimina un gasto compartido."""
    await grupos_service.eliminar_gasto(usuario.user_id, group_id, gasto_id)


@router.get("/{group_id}/balances")
async def obtener_balances(group_id: str, usuario: DatosUsuario = Depends(obtener_usuario_actual)):
    """Obtiene los balances del grupo personalizados por usuario."""
    return await grupos_service.calcular_balances(usuario.user_id, group_id)


@router.post("/{group_id}/pagos", status_code=201)
async def registrar_pago(group_id: str, datos: PagoCreate, usuario: DatosUsuario = Depends(obtener_usuario_actual)):
    """Registra un pago entre miembros."""
    return await grupos_service.registrar_pago(
        user_id=usuario.user_id, group_id=group_id,
        to_user_id=datos.to_user_id, amount=datos.amount, fecha=datos.date, note=datos.note,
    )
