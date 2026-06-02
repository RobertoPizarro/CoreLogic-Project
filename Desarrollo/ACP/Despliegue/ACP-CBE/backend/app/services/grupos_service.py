"""
Servicio de Grupos y Gastos Compartidos.
Lógica de negocio: CRUD de grupos/gastos, cálculo de balances, registro de pagos.
"""

from datetime import date, datetime
from typing import Optional
from fastapi import HTTPException, status
from app.core.database import obtener_pool


# ─── Helpers ───

async def _validar_miembro_activo(conn, user_id: str, group_id: str):
    """Valida que el usuario sea miembro activo del grupo."""
    miembro = await conn.fetchrow(
        "SELECT status FROM group_members WHERE group_id = $1 AND user_id = $2",
        group_id, user_id,
    )
    if not miembro:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No eres miembro de este grupo.")
    if miembro["status"] != "activo":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Tu invitación aún está pendiente.")


async def _obtener_nombre(conn, user_id: str) -> str:
    """Obtiene el nombre completo de un usuario."""
    perfil = await conn.fetchrow("SELECT full_name FROM profiles WHERE id = $1", user_id)
    return perfil["full_name"] if perfil else "Usuario desconocido"


async def _obtener_miembros(conn, group_id: str) -> list[dict]:
    """Obtiene todos los miembros de un grupo con sus datos."""
    filas = await conn.fetch(
        """SELECT gm.user_id::text, p.full_name, gm.status
           FROM group_members gm
           JOIN profiles p ON p.id = gm.user_id
           WHERE gm.group_id = $1
           ORDER BY gm.joined_at NULLS LAST""",
        group_id,
    )
    return [{"user_id": f["user_id"], "name": f["full_name"], "status": f["status"]} for f in filas]


def _calcular_splits_iguales(total: float, participantes: list[str], paid_by: str) -> list[dict]:
    """Divide en partes iguales. El primer participante absorbe el residuo."""
    n = len(participantes)
    base = round(total / n, 2)
    residuo = round(total - base * n, 2)
    splits = []
    for i, uid in enumerate(participantes):
        monto = base + (residuo if i == 0 else 0)
        splits.append({"user_id": uid, "amount_owed": 0.0 if uid == paid_by else round(monto, 2)})
    return splits


def _calcular_splits_porcentaje(total: float, splits_input: list[dict], paid_by: str) -> list[dict]:
    """Divide por porcentaje. Valida que sumen 100%."""
    suma_pct = sum(s.get("percentage", 0) for s in splits_input)
    if abs(suma_pct - 100.0) > 0.01:
        raise HTTPException(status_code=400, detail=f"Los porcentajes deben sumar 100%. Suma actual: {suma_pct}%")
    splits = []
    for s in splits_input:
        monto = round(total * s["percentage"] / 100, 2)
        splits.append({"user_id": s["user_id"], "amount_owed": 0.0 if s["user_id"] == paid_by else monto})
    return splits


def _calcular_splits_personalizado(total: float, splits_input: list[dict], paid_by: str) -> list[dict]:
    """División personalizada. Valida que la suma iguale al total."""
    suma = sum(s.get("amount_owed", 0) for s in splits_input)
    if abs(suma - total) > 0.01:
        raise HTTPException(status_code=400, detail=f"La suma de montos ({suma}) no coincide con el total ({total}).")
    splits = []
    for s in splits_input:
        splits.append({"user_id": s["user_id"], "amount_owed": 0.0 if s["user_id"] == paid_by else round(s["amount_owed"], 2)})
    return splits


# ─── Grupos ───

async def listar_grupos(user_id: str, busqueda: Optional[str] = None) -> list[dict]:
    """Lista los grupos del usuario con balance resumido y filtro opcional."""
    pool = obtener_pool()
    async with pool.acquire() as conn:
        if busqueda:
            term = f"%{busqueda}%"
            grupos = await conn.fetch(
                """SELECT g.id::text, g.name
                   FROM groups g
                   JOIN group_members gm ON gm.group_id = g.id
                   WHERE gm.user_id = $1
                     AND g.name ILIKE $2
                   ORDER BY g.created_at DESC""",
                user_id,
                term,
            )
        else:
            grupos = await conn.fetch(
                """SELECT g.id::text, g.name
                   FROM groups g
                   JOIN group_members gm ON gm.group_id = g.id
                   WHERE gm.user_id = $1
                   ORDER BY g.created_at DESC""",
                user_id,
            )
        resultado = []
        for g in grupos:
            gid = g["id"]
            miembros = await _obtener_miembros(conn, gid)
            # Verificar si el usuario tiene invitación pendiente
            mi_status = next((m["status"] for m in miembros if m["user_id"] == user_id), None)
            if mi_status == "pendiente":
                balance = {"status": "pendiente_invitacion"}
            else:
                balance = await _calcular_balance_resumen(conn, user_id, gid)
            resultado.append({"id": gid, "name": g["name"], "members": miembros, "my_balance_summary": balance})
        return resultado


async def _calcular_balance_resumen(conn, user_id: str, group_id: str) -> dict:
    """Calcula el resumen de balance del usuario en un grupo para la lista."""
    netos = await _calcular_netos_usuario(conn, user_id, group_id)
    mayor_deuda = None
    mayor_credito = None
    for uid, neto in netos.items():
        if neto < 0 and (mayor_deuda is None or neto < mayor_deuda[1]):
            mayor_deuda = (uid, neto)
        elif neto > 0 and (mayor_credito is None or neto > mayor_credito[1]):
            mayor_credito = (uid, neto)

    if mayor_deuda:
        nombre = await _obtener_nombre(conn, mayor_deuda[0])
        return {"status": "debes", "amount": round(abs(mayor_deuda[1]), 2), "to": nombre}
    elif mayor_credito:
        nombre = await _obtener_nombre(conn, mayor_credito[0])
        return {"status": "te_deben", "amount": round(mayor_credito[1], 2), "to": nombre}
    else:
        return {"status": "saldado"}


async def crear_grupo(user_id: str, name: str, emails: list[str]) -> dict:
    """Crea un nuevo grupo e invita miembros por correo."""
    pool = obtener_pool()
    async with pool.acquire() as conn:
        async with conn.transaction():
            # Crear grupo
            fila = await conn.fetchrow(
                "INSERT INTO groups (name, created_by) VALUES ($1, $2) RETURNING id::text, name, created_at",
                name, user_id,
            )
            gid = fila["id"]
            # Agregar creador como miembro activo
            await conn.execute(
                "INSERT INTO group_members (group_id, user_id, status, joined_at) VALUES ($1, $2, 'activo', now())",
                gid, user_id,
            )
            # Invitar miembros por correo
            for email in emails:
                perfil = await conn.fetchrow(
                    "SELECT p.id::text FROM profiles p JOIN auth.users u ON u.id = p.id WHERE u.email = $1",
                    email.strip().lower(),
                )
                if perfil and perfil["id"] != user_id:
                    existe = await conn.fetchval(
                        "SELECT 1 FROM group_members WHERE group_id = $1 AND user_id = $2", gid, perfil["id"],
                    )
                    if not existe:
                        await conn.execute(
                            "INSERT INTO group_members (group_id, user_id, status) VALUES ($1, $2, 'pendiente')",
                            gid, perfil["id"],
                        )
            miembros = await _obtener_miembros(conn, gid)
            return {"id": gid, "name": fila["name"], "members": miembros, "my_balance_summary": {"status": "saldado"}}


async def invitar_miembro(user_id: str, group_id: str, email: str) -> dict:
    """Invita a un miembro al grupo por correo electrónico."""
    pool = obtener_pool()
    async with pool.acquire() as conn:
        await _validar_miembro_activo(conn, user_id, group_id)
        perfil = await conn.fetchrow(
            "SELECT p.id::text FROM profiles p JOIN auth.users u ON u.id = p.id WHERE u.email = $1",
            email.strip().lower(),
        )
        if not perfil:
            raise HTTPException(status_code=404, detail="No se encontró un usuario con ese correo.")
        ya_miembro = await conn.fetchval(
            "SELECT 1 FROM group_members WHERE group_id = $1 AND user_id = $2", group_id, perfil["id"],
        )
        if ya_miembro:
            raise HTTPException(status_code=400, detail="Ese usuario ya es miembro del grupo.")
        await conn.execute(
            "INSERT INTO group_members (group_id, user_id, status) VALUES ($1, $2, 'pendiente')",
            group_id, perfil["id"],
        )
        return {"mensaje": "Invitación enviada."}


async def unirse_a_grupo(user_id: str, group_id: str) -> dict:
    """Acepta la invitación a un grupo."""
    pool = obtener_pool()
    async with pool.acquire() as conn:
        miembro = await conn.fetchrow(
            "SELECT status FROM group_members WHERE group_id = $1 AND user_id = $2", group_id, user_id,
        )
        if not miembro:
            raise HTTPException(status_code=404, detail="No tienes una invitación a este grupo.")
        if miembro["status"] == "activo":
            raise HTTPException(status_code=400, detail="Ya eres miembro activo de este grupo.")
        await conn.execute(
            "UPDATE group_members SET status = 'activo', joined_at = now() WHERE group_id = $1 AND user_id = $2",
            group_id, user_id,
        )
        return {"mensaje": "Te has unido al grupo."}


# ─── Gastos Compartidos ───

async def listar_gastos(user_id: str, group_id: str) -> dict:
    """Lista los gastos de un grupo."""
    pool = obtener_pool()
    async with pool.acquire() as conn:
        await _validar_miembro_activo(conn, user_id, group_id)
        nombre_grupo = await conn.fetchval("SELECT name FROM groups WHERE id = $1", group_id)
        filas = await conn.fetch(
            """SELECT ge.id::text, ge.description, ge.total_amount, ge.paid_by::text, ge.date, ge.created_at,
                      p.full_name AS paid_by_name
               FROM group_expenses ge
               JOIN profiles p ON p.id = ge.paid_by
               WHERE ge.group_id = $1
               ORDER BY ge.date DESC, ge.created_at DESC""",
            group_id,
        )
        gastos = []
        for f in filas:
            gastos.append({
                "id": f["id"], "description": f["description"], "total_amount": float(f["total_amount"]),
                "paid_by": {"user_id": f["paid_by"], "name": f["paid_by_name"]},
                "date": f["date"], "created_at": f["created_at"],
            })
        return {"group_id": group_id, "group_name": nombre_grupo, "gastos": gastos}


async def crear_gasto(user_id: str, group_id: str, datos: dict) -> dict:
    """Crea un gasto compartido con sus splits."""
    pool = obtener_pool()
    async with pool.acquire() as conn:
        await _validar_miembro_activo(conn, user_id, group_id)
        splits = _generar_splits(datos)
        async with conn.transaction():
            fila = await conn.fetchrow(
                """INSERT INTO group_expenses (group_id, description, total_amount, paid_by, date, split_type)
                   VALUES ($1, $2, $3, $4, $5, $6)
                   RETURNING id::text, group_id::text, description, total_amount, paid_by::text, date, split_type, created_at""",
                group_id, datos["description"], datos["total_amount"], datos["paid_by"], datos["date"], datos.get("split_type", "igual"),
            )
            for s in splits:
                await conn.execute(
                    "INSERT INTO expense_splits (expense_id, user_id, amount_owed) VALUES ($1, $2, $3)",
                    fila["id"], s["user_id"], s["amount_owed"],
                )
            return await _construir_respuesta_gasto(conn, fila)


async def obtener_gasto(user_id: str, group_id: str, gasto_id: str) -> dict:
    """Obtiene el detalle de un gasto compartido."""
    pool = obtener_pool()
    async with pool.acquire() as conn:
        await _validar_miembro_activo(conn, user_id, group_id)
        fila = await conn.fetchrow(
            """SELECT ge.id::text, ge.group_id::text, ge.description, ge.total_amount,
                      ge.paid_by::text, ge.date, ge.split_type, ge.created_at
               FROM group_expenses ge WHERE ge.id = $1 AND ge.group_id = $2""",
            gasto_id, group_id,
        )
        if not fila:
            raise HTTPException(status_code=404, detail="Gasto no encontrado.")
        return await _construir_respuesta_gasto(conn, fila)


async def editar_gasto(user_id: str, group_id: str, gasto_id: str, datos: dict) -> dict:
    """Edita un gasto compartido: actualiza datos y regenera splits."""
    pool = obtener_pool()
    async with pool.acquire() as conn:
        await _validar_miembro_activo(conn, user_id, group_id)
        existe = await conn.fetchval(
            "SELECT 1 FROM group_expenses WHERE id = $1 AND group_id = $2", gasto_id, group_id,
        )
        if not existe:
            raise HTTPException(status_code=404, detail="Gasto no encontrado.")
        splits = _generar_splits(datos)
        async with conn.transaction():
            fila = await conn.fetchrow(
                """UPDATE group_expenses SET description = $1, total_amount = $2, paid_by = $3, date = $4, split_type = $5
                   WHERE id = $6 RETURNING id::text, group_id::text, description, total_amount, paid_by::text, date, split_type, created_at""",
                datos["description"], datos["total_amount"], datos["paid_by"], datos["date"], datos.get("split_type", "igual"), gasto_id,
            )
            await conn.execute("DELETE FROM expense_splits WHERE expense_id = $1", gasto_id)
            for s in splits:
                await conn.execute(
                    "INSERT INTO expense_splits (expense_id, user_id, amount_owed) VALUES ($1, $2, $3)",
                    gasto_id, s["user_id"], s["amount_owed"],
                )
            return await _construir_respuesta_gasto(conn, fila)


async def eliminar_gasto(user_id: str, group_id: str, gasto_id: str):
    """Elimina un gasto compartido y sus splits (CASCADE)."""
    pool = obtener_pool()
    async with pool.acquire() as conn:
        await _validar_miembro_activo(conn, user_id, group_id)
        eliminado = await conn.execute(
            "DELETE FROM group_expenses WHERE id = $1 AND group_id = $2", gasto_id, group_id,
        )
        if eliminado == "DELETE 0":
            raise HTTPException(status_code=404, detail="Gasto no encontrado.")


def _generar_splits(datos: dict) -> list[dict]:
    """Genera los splits según el tipo de división."""
    tipo = datos["split_type"]
    total = datos["total_amount"]
    paid_by = datos["paid_by"]
    if tipo == "igual":
        return _calcular_splits_iguales(total, datos["participants"], paid_by)
    elif tipo == "porcentaje":
        return _calcular_splits_porcentaje(total, datos.get("splits", []), paid_by)
    elif tipo == "personalizado":
        return _calcular_splits_personalizado(total, datos.get("splits", []), paid_by)
    else:
        raise HTTPException(status_code=400, detail="Tipo de división no válido.")


async def _construir_respuesta_gasto(conn, fila) -> dict:
    """Construye la respuesta de un gasto con sus splits y nombre de pagador."""
    nombre_pagador = await _obtener_nombre(conn, fila["paid_by"])
    splits_db = await conn.fetch(
        """SELECT es.user_id::text, p.full_name, es.amount_owed
           FROM expense_splits es JOIN profiles p ON p.id = es.user_id
           WHERE es.expense_id = $1 ORDER BY es.amount_owed DESC""",
        fila["id"],
    )
    return {
        "id": fila["id"], "group_id": fila["group_id"], "description": fila["description"],
        "total_amount": float(fila["total_amount"]),
        "paid_by": {"user_id": fila["paid_by"], "name": nombre_pagador},
        "date": fila["date"], "split_type": fila.get("split_type", "igual"), "created_at": fila["created_at"],
        "splits": [{"user_id": s["user_id"], "name": s["full_name"], "amount_owed": float(s["amount_owed"])} for s in splits_db],
    }


# ─── Balances ───

async def _calcular_netos_usuario(conn, user_id: str, group_id: str) -> dict[str, float]:
    """Calcula el neto entre el usuario y cada otro miembro del grupo."""
    miembros = await conn.fetch(
        "SELECT user_id::text FROM group_members WHERE group_id = $1", group_id,
    )
    otros = [m["user_id"] for m in miembros if m["user_id"] != user_id]
    netos = {}
    for otro_id in otros:
        # Lo que el usuario le debe al otro (splits donde el usuario participa y el otro pagó)
        debe_al_otro = await conn.fetchval(
            """SELECT COALESCE(SUM(es.amount_owed), 0)
               FROM expense_splits es
               JOIN group_expenses ge ON ge.id = es.expense_id
               WHERE ge.group_id = $1 AND es.user_id = $2 AND ge.paid_by = $3""",
            group_id, user_id, otro_id,
        ) or 0
        # Lo que el otro le debe al usuario
        otro_debe = await conn.fetchval(
            """SELECT COALESCE(SUM(es.amount_owed), 0)
               FROM expense_splits es
               JOIN group_expenses ge ON ge.id = es.expense_id
               WHERE ge.group_id = $1 AND es.user_id = $2 AND ge.paid_by = $3""",
            group_id, otro_id, user_id,
        ) or 0
        # Pagos del usuario al otro
        pagos_enviados = await conn.fetchval(
            "SELECT COALESCE(SUM(amount), 0) FROM payments WHERE group_id = $1 AND from_user_id = $2 AND to_user_id = $3",
            group_id, user_id, otro_id,
        ) or 0
        # Pagos del otro al usuario
        pagos_recibidos = await conn.fetchval(
            "SELECT COALESCE(SUM(amount), 0) FROM payments WHERE group_id = $1 AND from_user_id = $2 AND to_user_id = $3",
            group_id, otro_id, user_id,
        ) or 0
        # Neto: positivo = el otro me debe, negativo = yo le debo
        neto = float(otro_debe) - float(debe_al_otro) - float(pagos_recibidos) + float(pagos_enviados)
        if abs(neto) > 0.005:
            netos[otro_id] = round(neto, 2)
    return netos


async def calcular_balances(user_id: str, group_id: str) -> dict:
    """Calcula los balances completos de un grupo, personalizados por usuario."""
    pool = obtener_pool()
    async with pool.acquire() as conn:
        await _validar_miembro_activo(conn, user_id, group_id)
        # Total del grupo
        total = await conn.fetchval(
            "SELECT COALESCE(SUM(total_amount), 0) FROM group_expenses WHERE group_id = $1", group_id,
        )
        # Última actividad
        ultima = await conn.fetchval(
            """SELECT GREATEST(
                 (SELECT MAX(created_at) FROM group_expenses WHERE group_id = $1),
                 (SELECT MAX(created_at) FROM payments WHERE group_id = $1)
               )""",
            group_id,
        )
        # Balance por miembro
        miembros = await _obtener_miembros(conn, group_id)
        member_balances = []
        for m in miembros:
            uid = m["user_id"]
            pagado = await conn.fetchval(
                "SELECT COALESCE(SUM(total_amount), 0) FROM group_expenses WHERE group_id = $1 AND paid_by = $2",
                group_id, uid,
            ) or 0
            su_parte = await conn.fetchval(
                """SELECT COALESCE(SUM(
                       CASE 
                           WHEN ge.paid_by = $2 THEN 
                               ge.total_amount - COALESCE((SELECT SUM(amount_owed) FROM expense_splits WHERE expense_id = ge.id), 0)
                           ELSE 
                               COALESCE((SELECT amount_owed FROM expense_splits WHERE expense_id = ge.id AND user_id = $2), 0)
                       END
                   ), 0)
                   FROM group_expenses ge
                   WHERE ge.group_id = $1""",
                group_id, uid,
            ) or 0
            pagos_enviados = await conn.fetchval(
                "SELECT COALESCE(SUM(amount), 0) FROM payments WHERE group_id = $1 AND from_user_id = $2",
                group_id, uid,
            ) or 0
            pagos_recibidos = await conn.fetchval(
                "SELECT COALESCE(SUM(amount), 0) FROM payments WHERE group_id = $1 AND to_user_id = $2",
                group_id, uid,
            ) or 0
            # Net = lo que pagó - lo que le tocaba (su_parte real) + pagos enviados - pagos recibidos
            net = float(pagado) - float(su_parte) + float(pagos_enviados) - float(pagos_recibidos)
            member_balances.append({"user_id": uid, "name": m["name"], "paid": float(pagado), "net": round(net, 2)})

        # Netos del usuario actual
        netos = await _calcular_netos_usuario(conn, user_id, group_id)
        my_debts = []
        owed_to_me = []
        for otro_id, neto in netos.items():
            nombre = await _obtener_nombre(conn, otro_id)
            if neto < 0:
                my_debts.append({"to_user_id": otro_id, "to_name": nombre, "amount": round(abs(neto), 2)})
            elif neto > 0:
                owed_to_me.append({"from_user_id": otro_id, "from_name": nombre, "amount": round(neto, 2)})

        return {
            "group_id": group_id, "total_group": float(total), "last_updated": ultima,
            "member_balances": member_balances, "my_debts": my_debts, "owed_to_me": owed_to_me,
        }


# ─── Pagos ───

async def registrar_pago(user_id: str, group_id: str, to_user_id: str, amount: float, fecha: date, note: Optional[str]) -> dict:
    """Registra un pago entre miembros. Valida que el monto no exceda la deuda neta."""
    pool = obtener_pool()
    async with pool.acquire() as conn:
        await _validar_miembro_activo(conn, user_id, group_id)
        # Validar que el destinatario sea miembro
        dest = await conn.fetchval(
            "SELECT 1 FROM group_members WHERE group_id = $1 AND user_id = $2", group_id, to_user_id,
        )
        if not dest:
            raise HTTPException(status_code=400, detail="El destinatario no es miembro del grupo.")
        # Calcular deuda neta actual del usuario hacia el destinatario
        netos = await _calcular_netos_usuario(conn, user_id, group_id)
        deuda_neta = abs(netos.get(to_user_id, 0)) if netos.get(to_user_id, 0) < 0 else 0
        if amount > deuda_neta + 0.01:
            raise HTTPException(status_code=400, detail=f"El monto ({amount}) excede tu deuda actual ({deuda_neta}).")
        # Registrar pago
        fila = await conn.fetchrow(
            """INSERT INTO payments (group_id, from_user_id, to_user_id, amount, note, date)
               VALUES ($1, $2, $3, $4, $5, $6)
               RETURNING id::text, group_id::text, from_user_id::text, to_user_id::text, amount, note, date, created_at""",
            group_id, user_id, to_user_id, amount, note, fecha,
        )
        from_name = await _obtener_nombre(conn, user_id)
        to_name = await _obtener_nombre(conn, to_user_id)
        return {
            "id": fila["id"], "group_id": fila["group_id"],
            "from_user_id": fila["from_user_id"], "from_name": from_name,
            "to_user_id": fila["to_user_id"], "to_name": to_name,
            "amount": float(fila["amount"]), "note": fila["note"],
            "date": fila["date"], "created_at": fila["created_at"],
        }
