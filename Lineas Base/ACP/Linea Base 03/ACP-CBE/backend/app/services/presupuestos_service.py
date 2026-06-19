"""
Servicio de Presupuestos Personales.
CRUD con validación de solapamiento de períodos y cálculo de consumo en tiempo real.
"""

from datetime import date
from typing import Optional

from fastapi import HTTPException, status

from app.core.database import obtener_pool


async def _calcular_estado(start_date: date, end_date: date) -> str:
    """Calcula el estado de un presupuesto según la fecha actual del servidor."""
    from datetime import date as date_type
    hoy = date_type.today()
    if start_date <= hoy <= end_date:
        return "activo"
    elif start_date > hoy:
        return "proximo"
    else:
        return "vencido"


async def _validar_solapamiento(conn, user_id: str, category_id: str, start_date: date, end_date: date, excluir_id: str = None):
    """
    Valida que no exista otro presupuesto del mismo usuario con la misma categoría
    cuyos períodos se superpongan.
    """
    if excluir_id:
        solapado = await conn.fetchrow(
            """
            SELECT id::text, description
            FROM budgets
            WHERE user_id = $1
              AND category_id = $2
              AND start_date <= $4
              AND end_date >= $3
              AND id != $5
            LIMIT 1
            """,
            user_id, category_id, start_date, end_date, excluir_id,
        )
    else:
        solapado = await conn.fetchrow(
            """
            SELECT id::text, description
            FROM budgets
            WHERE user_id = $1
              AND category_id = $2
              AND start_date <= $4
              AND end_date >= $3
            LIMIT 1
            """,
            user_id, category_id, start_date, end_date,
        )

    if solapado:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Ya existe un presupuesto para esta categoría en ese período: '{solapado['description']}'.",
        )


async def _validar_categoria_gasto(conn, category_id: str):
    """Valida que la categoría exista y sea de tipo 'expense'."""
    categoria = await conn.fetchrow(
        "SELECT id, type FROM categories WHERE id = $1",
        category_id,
    )
    if not categoria:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="La categoría no existe.")
    if categoria["type"] != "expense":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Los presupuestos solo pueden asociarse a categorías de tipo 'expense'.",
        )


async def _calcular_consumo(conn, user_id: str, category_id: str, start_date: date, end_date: date) -> float:
    """Calcula el monto consumido de un presupuesto sumando gastos en su período."""
    consumo = await conn.fetchval(
        """
        SELECT COALESCE(SUM(amount), 0)
        FROM movements
        WHERE user_id = $1
          AND type = 'expense'
          AND category_id = $2
          AND date >= $3
          AND date <= $4
        """,
        user_id, category_id, start_date, end_date,
    )
    return float(consumo)


async def _construir_respuesta(conn, fila, user_id: str) -> dict:
    """Construye la respuesta de un presupuesto con valores calculados."""
    category_id = fila["category_id"] if isinstance(fila["category_id"], str) else str(fila["category_id"])
    start_date = fila["start_date"]
    end_date = fila["end_date"]
    monto = float(fila["amount"])

    # Obtener nombre e ícono de categoría
    cat = await conn.fetchrow("SELECT name, icon FROM categories WHERE id = $1", fila["category_id"])

    # Calcular consumo en tiempo real
    consumo = await _calcular_consumo(conn, user_id, fila["category_id"], start_date, end_date)
    restante = monto - consumo
    porcentaje = (consumo / monto * 100) if monto > 0 else 0

    # Calcular estado
    estado = await _calcular_estado(start_date, end_date)

    return {
        "id": fila["id"] if isinstance(fila["id"], str) else str(fila["id"]),
        "description": fila["description"],
        "category": cat["name"],
        "category_id": category_id,
        "icon": cat["icon"],
        "amount": monto,
        "consumed": round(consumo, 2),
        "remaining": round(restante, 2),
        "percentage_used": round(porcentaje, 2),
        "start_date": start_date.isoformat(),
        "end_date": end_date.isoformat(),
        "status": estado,
    }


async def listar_presupuestos(user_id: str, busqueda: Optional[str] = None) -> list[dict]:
    """Lista todos los presupuestos del usuario con consumo calculado, con filtro de búsqueda opcional."""
    pool = obtener_pool()

    async with pool.acquire() as conn:
        if busqueda:
            term = f"%{busqueda}%"
            filas = await conn.fetch(
                """
                SELECT id, description, amount, category_id, start_date, end_date
                FROM budgets
                WHERE user_id = $1
                  AND description ILIKE $2
                ORDER BY start_date DESC
                """,
                user_id,
                term,
            )
        else:
            filas = await conn.fetch(
                """
                SELECT id, description, amount, category_id, start_date, end_date
                FROM budgets
                WHERE user_id = $1
                ORDER BY start_date DESC
                """,
                user_id,
            )

        resultado = []
        for fila in filas:
            resp = await _construir_respuesta(conn, fila, user_id)
            resultado.append(resp)

    return resultado


async def obtener_presupuesto(user_id: str, presupuesto_id: str) -> dict:
    """Obtiene el detalle de un presupuesto. Verifica propiedad."""
    pool = obtener_pool()

    async with pool.acquire() as conn:
        fila = await conn.fetchrow(
            """
            SELECT id, description, amount, category_id, start_date, end_date, user_id::text
            FROM budgets
            WHERE id = $1
            """,
            presupuesto_id,
        )

        if not fila:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Presupuesto no encontrado.")
        if fila["user_id"] != user_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a este presupuesto.")

        return await _construir_respuesta(conn, fila, user_id)


async def crear_presupuesto(
    user_id: str,
    descripcion: str,
    monto: float,
    category_id: str,
    start_date: date,
    end_date: date,
) -> dict:
    """Crea un nuevo presupuesto personal."""
    pool = obtener_pool()

    async with pool.acquire() as conn:
        # Validar categoría de gasto
        await _validar_categoria_gasto(conn, category_id)

        # Validar solapamiento
        await _validar_solapamiento(conn, user_id, category_id, start_date, end_date)

        # Insertar
        fila = await conn.fetchrow(
            """
            INSERT INTO budgets (user_id, description, amount, category_id, start_date, end_date)
            VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING id, description, amount, category_id, start_date, end_date
            """,
            user_id, descripcion, monto, category_id, start_date, end_date,
        )

        return await _construir_respuesta(conn, fila, user_id)


async def editar_presupuesto(
    user_id: str,
    presupuesto_id: str,
    descripcion: str,
    monto: float,
    category_id: str,
    start_date: date,
    end_date: date,
) -> dict:
    """Edita un presupuesto existente. Se puede editar en cualquier estado."""
    pool = obtener_pool()

    async with pool.acquire() as conn:
        # Verificar propiedad
        propietario = await conn.fetchval(
            "SELECT user_id::text FROM budgets WHERE id = $1", presupuesto_id
        )
        if not propietario:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Presupuesto no encontrado.")
        if propietario != user_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a este presupuesto.")

        # Validar categoría de gasto
        await _validar_categoria_gasto(conn, category_id)

        # Validar solapamiento (excluyendo el propio)
        await _validar_solapamiento(conn, user_id, category_id, start_date, end_date, excluir_id=presupuesto_id)

        # Actualizar
        await conn.execute(
            """
            UPDATE budgets
            SET description = $1, amount = $2, category_id = $3, start_date = $4, end_date = $5
            WHERE id = $6
            """,
            descripcion, monto, category_id, start_date, end_date, presupuesto_id,
        )

        fila = await conn.fetchrow(
            "SELECT id, description, amount, category_id, start_date, end_date FROM budgets WHERE id = $1",
            presupuesto_id,
        )

        return await _construir_respuesta(conn, fila, user_id)


async def eliminar_presupuesto(user_id: str, presupuesto_id: str):
    """Elimina un presupuesto. Solo borra el registro, los gastos persisten."""
    pool = obtener_pool()

    async with pool.acquire() as conn:
        propietario = await conn.fetchval(
            "SELECT user_id::text FROM budgets WHERE id = $1", presupuesto_id
        )
        if not propietario:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Presupuesto no encontrado.")
        if propietario != user_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a este presupuesto.")

        await conn.execute("DELETE FROM budgets WHERE id = $1", presupuesto_id)
