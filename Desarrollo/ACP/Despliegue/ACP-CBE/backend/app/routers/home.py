"""
Router de Home.
GET /home — saldo total, totales de ingresos/gastos y movimientos recientes.
"""

from fastapi import APIRouter, Depends

from app.core.auth import obtener_usuario_actual, DatosUsuario
from app.services.home_service import obtener_datos_home

router = APIRouter(tags=["Home"])


@router.get("/home")
async def home(usuario: DatosUsuario = Depends(obtener_usuario_actual)):
    """Devuelve los datos del Home: saldo, totales y últimos 5 movimientos."""
    return await obtener_datos_home(usuario.user_id)
