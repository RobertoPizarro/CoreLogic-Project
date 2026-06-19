"""
Servicio de Home.
Calcula saldo total, totales de ingresos/gastos y movimientos recientes.
Todos los valores se calculan en tiempo real, nunca se persisten.
"""

from app.core.database import obtener_pool


async def obtener_datos_home(user_id: str) -> dict:
    """
    Obtiene los datos del Home para un usuario:
    - Saldo total (ingresos - gastos de todo el historial)
    - Total de ingresos
    - Total de gastos
    - Últimos 5 movimientos recientes
    """
    pool = obtener_pool()

    async with pool.acquire() as conn:
        # Calcular totales de ingresos y gastos (todo el historial)
        fila_totales = await conn.fetchrow(
            """
            SELECT
                COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS total_ingresos,
                COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS total_gastos
            FROM movements
            WHERE user_id = $1
            """,
            user_id,
        )

        total_ingresos = float(fila_totales["total_ingresos"])
        total_gastos = float(fila_totales["total_gastos"])
        saldo_total = total_ingresos - total_gastos

        # Obtener los últimos 5 movimientos recientes
        filas_recientes = await conn.fetch(
            """
            SELECT
                m.id::text,
                m.type,
                m.amount,
                m.description,
                c.name AS category,
                c.icon AS icon,
                m.date,
                m.payment_method
            FROM movements m
            JOIN categories c ON m.category_id = c.id
            WHERE m.user_id = $1
            ORDER BY m.date DESC, m.created_at DESC
            LIMIT 5
            """,
            user_id,
        )

        movimientos_recientes = [
            {
                "id": fila["id"],
                "type": fila["type"],
                "amount": float(fila["amount"]),
                "description": fila["description"],
                "category": fila["category"],
                "icon": fila["icon"],
                "date": fila["date"].isoformat(),
                "payment_method": fila["payment_method"],
            }
            for fila in filas_recientes
        ]

    return {
        "saldo_total": saldo_total,
        "total_ingresos": total_ingresos,
        "total_gastos": total_gastos,
        "movimientos_recientes": movimientos_recientes,
    }
