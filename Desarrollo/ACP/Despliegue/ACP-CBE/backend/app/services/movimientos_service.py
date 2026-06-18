"""
Servicio de Movimientos Personales.
CRUD de ingresos y gastos + evaluación de presupuesto antes de guardar un gasto.
"""

from datetime import date
from typing import Optional

from fastapi import HTTPException, status

from app.core.database import obtener_pool


async def validar_categoria(conn, category_id: str, tipo_esperado: str):
    """Valida que la categoría exista y que su tipo coincida con el del movimiento."""
    categoria = await conn.fetchrow(
        "SELECT id, type FROM categories WHERE id = $1",
        category_id,
    )
    if not categoria:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La categoría no existe.",
        )
    if categoria["type"] != tipo_esperado:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"La categoría seleccionada es de tipo '{categoria['type']}', pero el movimiento es de tipo '{tipo_esperado}'.",
        )


async def crear_movimiento(
    user_id: str,
    tipo: str,
    monto: float,
    category_id: str,
    fecha: date,
    descripcion: Optional[str],
    metodo_pago: str,
) -> dict:
    """Crea un nuevo movimiento personal."""
    pool = obtener_pool()

    async with pool.acquire() as conn:
        # Validar categoría vs tipo
        await validar_categoria(conn, category_id, tipo)

        # Insertar movimiento
        fila = await conn.fetchrow(
            """
            INSERT INTO movements (user_id, type, amount, category_id, date, description, payment_method)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING id::text, type, amount, category_id::text, date, description, payment_method
            """,
            user_id, tipo, monto, category_id, fecha, descripcion, metodo_pago,
        )

        # Obtener nombre e ícono de categoría
        cat = await conn.fetchrow("SELECT name, icon FROM categories WHERE id = $1", category_id)

    return {
        "id": fila["id"],
        "type": fila["type"],
        "amount": float(fila["amount"]),
        "description": fila["description"],
        "category": cat["name"],
        "category_id": fila["category_id"],
        "icon": cat["icon"],
        "date": fila["date"].isoformat(),
        "payment_method": fila["payment_method"],
    }


async def obtener_movimiento(user_id: str, movimiento_id: str) -> dict:
    """Obtiene el detalle de un movimiento. Verifica que pertenezca al usuario."""
    pool = obtener_pool()

    async with pool.acquire() as conn:
        fila = await conn.fetchrow(
            """
            SELECT
                m.id::text, m.type, m.amount, m.description,
                c.name AS category, c.icon AS icon, m.category_id::text,
                m.date, m.payment_method
            FROM movements m
            JOIN categories c ON m.category_id = c.id
            WHERE m.id = $1
            """,
            movimiento_id,
        )

        if not fila:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Movimiento no encontrado.")

        # Verificar que pertenece al usuario
        propietario = await conn.fetchval("SELECT user_id::text FROM movements WHERE id = $1", movimiento_id)
        if propietario != user_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a este movimiento.")

    return {
        "id": fila["id"],
        "type": fila["type"],
        "amount": float(fila["amount"]),
        "description": fila["description"],
        "category": fila["category"],
        "category_id": fila["category_id"],
        "icon": fila["icon"],
        "date": fila["date"].isoformat(),
        "payment_method": fila["payment_method"],
    }


async def listar_movimientos(
    user_id: str,
    tipo: Optional[str] = None,
    busqueda: Optional[str] = None,
    mes: Optional[int] = None,
    anio: Optional[int] = None,
    category_id: Optional[str] = None,
    limit: int = 10,
    offset: int = 0,
) -> list[dict]:
    """Lista movimientos con filtros opcionales y paginación."""
    pool = obtener_pool()

    # Construir query dinámica con filtros
    condiciones = ["m.user_id = $1"]
    parametros: list = [user_id]
    indice = 2  # Siguiente parámetro posicional

    if tipo and tipo in ("income", "expense"):
        condiciones.append(f"m.type = ${indice}")
        parametros.append(tipo)
        indice += 1

    if busqueda:
        condiciones.append(f"m.description ILIKE ${indice}")
        parametros.append(f"%{busqueda}%")
        indice += 1

    if mes and anio:
        condiciones.append(f"EXTRACT(MONTH FROM m.date) = ${indice}")
        parametros.append(mes)
        indice += 1
        condiciones.append(f"EXTRACT(YEAR FROM m.date) = ${indice}")
        parametros.append(anio)
        indice += 1

    if category_id:
        condiciones.append(f"m.category_id = ${indice}")
        parametros.append(category_id)
        indice += 1

    where = " AND ".join(condiciones)

    # Agregar limit y offset
    parametros.append(limit)
    param_limit = indice
    indice += 1
    parametros.append(offset)
    param_offset = indice

    query = f"""
        SELECT
            m.id::text, m.type, m.amount, m.description,
            c.name AS category, c.icon AS icon, m.category_id::text,
            m.date, m.payment_method
        FROM movements m
        JOIN categories c ON m.category_id = c.id
        WHERE {where}
        ORDER BY m.date DESC, m.created_at DESC
        LIMIT ${param_limit} OFFSET ${param_offset}
    """

    async with pool.acquire() as conn:
        filas = await conn.fetch(query, *parametros)

    return [
        {
            "id": f["id"],
            "type": f["type"],
            "amount": float(f["amount"]),
            "description": f["description"],
            "category": f["category"],
            "category_id": f["category_id"],
            "icon": f["icon"],
            "date": f["date"].isoformat(),
            "payment_method": f["payment_method"],
        }
        for f in filas
    ]


async def editar_movimiento(
    user_id: str,
    movimiento_id: str,
    tipo: str,
    monto: float,
    category_id: str,
    fecha: date,
    descripcion: Optional[str],
    metodo_pago: str,
) -> dict:
    """Edita un movimiento existente. Verifica propiedad y validaciones."""
    pool = obtener_pool()

    async with pool.acquire() as conn:
        # Verificar que existe y pertenece al usuario
        propietario = await conn.fetchval(
            "SELECT user_id::text FROM movements WHERE id = $1", movimiento_id
        )
        if not propietario:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Movimiento no encontrado.")
        if propietario != user_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a este movimiento.")

        # Validar categoría vs tipo
        await validar_categoria(conn, category_id, tipo)

        # Actualizar
        await conn.execute(
            """
            UPDATE movements
            SET type = $1, amount = $2, category_id = $3, date = $4,
                description = $5, payment_method = $6
            WHERE id = $7
            """,
            tipo, monto, category_id, fecha, descripcion, metodo_pago, movimiento_id,
        )

        # Obtener nombre e ícono de categoría
        cat = await conn.fetchrow("SELECT name, icon FROM categories WHERE id = $1", category_id)

    return {
        "id": movimiento_id,
        "type": tipo,
        "amount": monto,
        "description": descripcion,
        "category": cat["name"],
        "category_id": category_id,
        "icon": cat["icon"],
        "date": fecha.isoformat(),
        "payment_method": metodo_pago,
    }


async def eliminar_movimiento(user_id: str, movimiento_id: str):
    """Elimina un movimiento. Verifica propiedad."""
    pool = obtener_pool()

    async with pool.acquire() as conn:
        propietario = await conn.fetchval(
            "SELECT user_id::text FROM movements WHERE id = $1", movimiento_id
        )
        if not propietario:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Movimiento no encontrado.")
        if propietario != user_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a este movimiento.")

        await conn.execute("DELETE FROM movements WHERE id = $1", movimiento_id)


async def evaluar_presupuesto(
    user_id: str,
    category_id: str,
    monto: float,
    fecha: date,
    movement_id: Optional[str] = None,
) -> dict:
    """
    Evalúa si un gasto excede algún presupuesto activo.
    Si movement_id se provee (edición), se excluye del cálculo de consumo.
    """
    pool = obtener_pool()

    async with pool.acquire() as conn:
        # Buscar presupuesto cuya categoría y período incluyan la fecha del gasto
        presupuesto = await conn.fetchrow(
            """
            SELECT id::text, description, amount
            FROM budgets
            WHERE user_id = $1
              AND category_id = $2
              AND start_date <= $3
              AND end_date >= $3
            LIMIT 1
            """,
            user_id, category_id, fecha,
        )

        if not presupuesto:
            return {"excede_presupuesto": False}

        # Calcular consumo actual excluyendo el movimiento que se edita
        if movement_id:
            consumo_actual = await conn.fetchval(
                """
                SELECT COALESCE(SUM(amount), 0)
                FROM movements
                WHERE user_id = $1
                  AND type = 'expense'
                  AND category_id = $2
                  AND date >= (SELECT start_date FROM budgets WHERE id = $3)
                  AND date <= (SELECT end_date FROM budgets WHERE id = $3)
                  AND id != $4
                """,
                user_id, category_id, presupuesto["id"], movement_id,
            )
        else:
            consumo_actual = await conn.fetchval(
                """
                SELECT COALESCE(SUM(amount), 0)
                FROM movements
                WHERE user_id = $1
                  AND type = 'expense'
                  AND category_id = $2
                  AND date >= (SELECT start_date FROM budgets WHERE id = $3)
                  AND date <= (SELECT end_date FROM budgets WHERE id = $3)
                """,
                user_id, category_id, presupuesto["id"],
            )

        consumo_con_gasto = float(consumo_actual) + monto
        limite = float(presupuesto["amount"])

        if consumo_con_gasto > limite:
            return {
                "excede_presupuesto": True,
                "presupuesto_descripcion": presupuesto["description"],
                "monto_exceso": round(consumo_con_gasto - limite, 2),
            }

        return {"excede_presupuesto": False}
