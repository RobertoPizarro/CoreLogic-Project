"""
Servicio para la lógica de negocio y consultas de agregación SQL del Módulo de Reportes.
"""

from datetime import date
import calendar
from typing import List, Optional, Dict, Any
from fastapi import HTTPException, status
from app.core.database import obtener_pool

MESES = [
    "", "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
    "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
]

DIAS_SEMANA_COMPLETO = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]


async def obtener_resumen_periodos(
    user_id: str,
    vista: str,
    mes: Optional[str] = None,
    anio: Optional[int] = None,
) -> Dict[str, Any]:
    """
    Obtiene el resumen financiero agrupado por períodos temporales (diario, semanal, mensual).
    """
    pool = obtener_pool()

    if vista not in ("diaria", "semanal", "mensual"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La vista debe ser 'diaria', 'semanal' o 'mensual'.",
        )

    # Determinar mes y año por defecto
    hoy = date.today()
    filtro_mes = hoy.month
    filtro_anio = hoy.year

    if mes:
        try:
            partes = mes.split("-")
            filtro_anio = int(partes[0])
            filtro_mes = int(partes[1])
        except (ValueError, IndexError):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El formato del mes debe ser YYYY-MM.",
            )

    if anio:
        filtro_anio = anio

    periodos = []

    async with pool.acquire() as conn:
        if vista == "diaria":
            # Agrupa por día exacto dentro del mes
            query = """
                SELECT
                    date,
                    COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS total_ingresos,
                    COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS total_gastos
                FROM movements
                WHERE user_id = $1
                  AND EXTRACT(MONTH FROM date) = $2
                  AND EXTRACT(YEAR FROM date) = $3
                GROUP BY date
                ORDER BY date DESC
            """
            filas = await conn.fetch(query, user_id, filtro_mes, filtro_anio)

            for f in filas:
                d: date = f["date"]
                # Formato del label: "Lunes 12"
                label = f"{DIAS_SEMANA_COMPLETO[d.weekday()]} {d.day}"
                total_ing = float(f["total_ingresos"])
                total_gas = float(f["total_gastos"])
                periodos.append({
                    "label": label,
                    "rango_fechas": {"desde": d.isoformat(), "hasta": d.isoformat()},
                    "total_ingresos": total_ing,
                    "total_gastos": total_gas,
                    "balance": round(total_ing - total_gas, 2)
                })

        elif vista == "semanal":
            # Agrupa en 5 semanas fijas basadas en el día calendario
            query = """
                SELECT
                    CASE
                        WHEN EXTRACT(DAY FROM date) BETWEEN 1 AND 7 THEN 1
                        WHEN EXTRACT(DAY FROM date) BETWEEN 8 AND 14 THEN 2
                        WHEN EXTRACT(DAY FROM date) BETWEEN 15 AND 21 THEN 3
                        WHEN EXTRACT(DAY FROM date) BETWEEN 22 AND 28 THEN 4
                        ELSE 5
                    END AS semana_idx,
                    COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS total_ingresos,
                    COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS total_gastos
                FROM movements
                WHERE user_id = $1
                  AND EXTRACT(MONTH FROM date) = $2
                  AND EXTRACT(YEAR FROM date) = $3
                GROUP BY semana_idx
                ORDER BY semana_idx DESC
            """
            filas = await conn.fetch(query, user_id, filtro_mes, filtro_anio)
            _, último_dia = calendar.monthrange(filtro_anio, filtro_mes)

            # Rango de fechas por semana fija
            limites_semanas = {
                1: (1, 7),
                2: (8, 14),
                3: (15, 21),
                4: (22, 28),
                5: (29, último_dia)
            }

            for f in filas:
                sem_idx = int(f["semana_idx"])
                if sem_idx not in limites_semanas:
                    continue
                # Si es febrero y tiene 28 días, no hay semana 5
                inicio_dia, fin_dia = limites_semanas[sem_idx]
                if inicio_dia > último_dia:
                    continue

                d_desde = date(filtro_anio, filtro_mes, inicio_dia)
                d_hasta = date(filtro_anio, filtro_mes, fin_dia)

                label = f"Semana {sem_idx}"
                total_ing = float(f["total_ingresos"])
                total_gas = float(f["total_gastos"])

                periodos.append({
                    "label": label,
                    "rango_fechas": {"desde": d_desde.isoformat(), "hasta": d_hasta.isoformat()},
                    "total_ingresos": total_ing,
                    "total_gastos": total_gas,
                    "balance": round(total_ing - total_gas, 2)
                })

        elif vista == "mensual":
            # Agrupa por mes dentro del año
            query = """
                SELECT
                    EXTRACT(MONTH FROM date) AS mes_idx,
                    COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS total_ingresos,
                    COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS total_gastos
                FROM movements
                WHERE user_id = $1
                  AND EXTRACT(YEAR FROM date) = $2
                GROUP BY mes_idx
                ORDER BY mes_idx DESC
            """
            filas = await conn.fetch(query, user_id, filtro_anio)

            for f in filas:
                m_idx = int(f["mes_idx"])
                label = f"{MESES[m_idx]} {filtro_anio}"
                _, último_dia = calendar.monthrange(filtro_anio, m_idx)

                d_desde = date(filtro_anio, m_idx, 1)
                d_hasta = date(filtro_anio, m_idx, último_dia)

                total_ing = float(f["total_ingresos"])
                total_gas = float(f["total_gastos"])

                periodos.append({
                    "label": label,
                    "rango_fechas": {"desde": d_desde.isoformat(), "hasta": d_hasta.isoformat()},
                    "total_ingresos": total_ing,
                    "total_gastos": total_gas,
                    "balance": round(total_ing - total_gas, 2)
                })

    response = {
        "vista": vista,
        "periodos": periodos
    }

    if vista in ("diaria", "semanal"):
        response["mes"] = f"{filtro_anio}-{str(filtro_mes).zfill(2)}"
    else:
        response["anio"] = filtro_anio

    return response


async def obtener_distribucion_categorias(
    user_id: str,
    vista: str,
    tipo: str,
    mes: Optional[str] = None,
    anio: Optional[int] = None,
) -> Dict[str, Any]:
    """
    Obtiene la distribución porcentual por categoría de movimientos (ingresos o gastos).
    """
    pool = obtener_pool()

    if vista not in ("diaria", "semanal", "mensual"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La vista debe ser 'diaria', 'semanal' o 'mensual'.",
        )

    if tipo not in ("income", "expense"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El tipo debe ser 'income' o 'expense'.",
        )

    hoy = date.today()
    filtro_mes = hoy.month
    filtro_anio = hoy.year

    if mes:
        try:
            partes = mes.split("-")
            filtro_anio = int(partes[0])
            filtro_mes = int(partes[1])
        except (ValueError, IndexError):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El formato del mes debe ser YYYY-MM.",
            )

    if anio:
        filtro_anio = anio

    # Definir la condición temporal de la consulta
    if vista in ("diaria", "semanal"):
        # Distribución para el mes completo
        condicion_temporal = "EXTRACT(MONTH FROM m.date) = $3 AND EXTRACT(YEAR FROM m.date) = $4"
        params = [user_id, tipo, filtro_mes, filtro_anio]
    else:
        # Distribución para el año completo
        condicion_temporal = "EXTRACT(YEAR FROM m.date) = $3"
        params = [user_id, tipo, filtro_anio]

    query = f"""
        SELECT
            c.id::text AS category_id,
            c.name AS name,
            c.icon AS icon,
            COALESCE(SUM(m.amount), 0) AS amount
        FROM movements m
        JOIN categories c ON m.category_id = c.id
        WHERE m.user_id = $1
          AND m.type = $2
          AND {condicion_temporal}
        GROUP BY c.id, c.name, c.icon
        HAVING SUM(m.amount) > 0
        ORDER BY amount DESC
    """

    async with pool.acquire() as conn:
        filas = await conn.fetch(query, *params)

    # Calcular monto total y porcentajes
    total_monto = sum(float(f["amount"]) for f in filas)
    categorias = []

    for f in filas:
        amount = float(f["amount"])
        percentage = round((amount / total_monto) * 100, 2) if total_monto > 0 else 0.0
        categorias.append({
            "category_id": f["category_id"],
            "name": f["name"],
            "icon": f["icon"],
            "amount": amount,
            "percentage": percentage
        })

    response = {
        "vista": vista,
        "tipo": tipo,
        "total_monto": round(total_monto, 2),
        "categorias": categorias
    }

    if vista in ("diaria", "semanal"):
        response["mes"] = f"{filtro_anio}-{str(filtro_mes).zfill(2)}"
    else:
        response["anio"] = filtro_anio

    return response
