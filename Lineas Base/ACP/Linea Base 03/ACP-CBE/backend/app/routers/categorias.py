"""
Router de Categorías.
GET /categorias — lista de categorías predefinidas, filtrable por tipo.
"""

from typing import Optional

from fastapi import APIRouter, Depends, Query

from app.core.auth import obtener_usuario_actual, DatosUsuario
from app.core.database import obtener_pool

router = APIRouter(tags=["Categorías"])


@router.get("/categorias")
async def listar_categorias(
    type: Optional[str] = Query(None),
    usuario: DatosUsuario = Depends(obtener_usuario_actual),
):
    """
    Lista las categorías predefinidas.
    Filtrable con ?type=income o ?type=expense.
    """
    pool = obtener_pool()

    async with pool.acquire() as conn:
        if type and type in ("income", "expense"):
            filas = await conn.fetch(
                "SELECT id::text, name, type, icon FROM categories WHERE type = $1 ORDER BY name",
                type,
            )
        else:
            filas = await conn.fetch(
                "SELECT id::text, name, type, icon FROM categories ORDER BY type, name"
            )

    return {
        "categorias": [
            {
                "id": f["id"],
                "name": f["name"],
                "type": f["type"],
                "icon": f["icon"],
            }
            for f in filas
        ]
    }
