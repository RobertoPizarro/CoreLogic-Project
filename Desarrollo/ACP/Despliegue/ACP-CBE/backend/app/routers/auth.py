"""
Router de Autenticación y Perfil.
POST /auth/registro — crea perfil tras registro en Supabase Auth.
GET /perfil — devuelve nombre completo y email del usuario autenticado.
"""

from fastapi import APIRouter, Depends, HTTPException, status

from app.core.auth import obtener_usuario_actual, DatosUsuario
from app.core.database import obtener_pool
from app.schemas.auth import RegistroRequest, RegistroResponse, PerfilResponse

router = APIRouter(tags=["Autenticación"])


@router.post("/auth/registro", response_model=RegistroResponse, status_code=status.HTTP_201_CREATED)
async def crear_perfil(
    datos: RegistroRequest,
    usuario: DatosUsuario = Depends(obtener_usuario_actual),
):
    """
    Crea el registro en la tabla profiles tras un registro exitoso en Supabase Auth.
    El user_id se extrae del JWT, nunca del body.
    """
    pool = obtener_pool()

    async with pool.acquire() as conn:
        # Verificar si ya existe un perfil para este usuario
        existente = await conn.fetchval(
            "SELECT id::text FROM profiles WHERE id = $1",
            usuario.user_id,
        )
        if existente:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Ya existe un perfil para este usuario.",
            )

        # Crear perfil
        fila = await conn.fetchrow(
            """
            INSERT INTO profiles (id, full_name)
            VALUES ($1, $2)
            RETURNING id::text, full_name, created_at
            """,
            usuario.user_id,
            datos.full_name,
        )

    return RegistroResponse(
        id=fila["id"],
        full_name=fila["full_name"],
        created_at=fila["created_at"],
    )


@router.get("/perfil", response_model=PerfilResponse)
async def obtener_perfil(
    usuario: DatosUsuario = Depends(obtener_usuario_actual),
):
    """
    Devuelve el perfil del usuario autenticado.
    El nombre viene de profiles, el email del JWT.
    """
    pool = obtener_pool()

    async with pool.acquire() as conn:
        fila = await conn.fetchrow(
            "SELECT id::text, full_name FROM profiles WHERE id = $1",
            usuario.user_id,
        )

        if not fila:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Perfil no encontrado.",
            )

    return PerfilResponse(
        id=fila["id"],
        full_name=fila["full_name"],
        email=usuario.email,
    )
