"""
Conexión asíncrona a PostgreSQL usando asyncpg.
Maneja el pool de conexiones para todo el backend.
Supabase requiere SSL para conexiones externas.
"""

import ssl
import asyncpg
from urllib.parse import urlparse, unquote
from app.config import DATABASE_URL

# Pool global de conexiones
_pool: asyncpg.Pool | None = None


def _parsear_url_bd():
    """
    Parsea la DATABASE_URL manualmente para evitar problemas con
    caracteres especiales en la contraseña (como '!').
    """
    parsed = urlparse(DATABASE_URL)
    return {
        "user": unquote(parsed.username or "postgres"),
        "password": unquote(parsed.password or ""),
        "host": parsed.hostname or "localhost",
        "port": parsed.port or 5432,
        "database": (parsed.path or "/postgres").lstrip("/"),
    }


async def crear_pool():
    """Crea el pool de conexiones a PostgreSQL. Se llama al iniciar la app."""
    global _pool

    params = _parsear_url_bd()

    # Crear contexto SSL para Supabase
    contexto_ssl = ssl.create_default_context()
    contexto_ssl.check_hostname = False
    contexto_ssl.verify_mode = ssl.CERT_NONE

    _pool = await asyncpg.create_pool(
        user=params["user"],
        password=params["password"],
        host=params["host"],
        port=params["port"],
        database=params["database"],
        ssl=contexto_ssl,
        min_size=2,
        max_size=10,
        statement_cache_size=0,
    )


async def cerrar_pool():
    """Cierra el pool de conexiones. Se llama al apagar la app."""
    global _pool
    if _pool:
        await _pool.close()
        _pool = None


async def obtener_conexion() -> asyncpg.Connection:
    """
    Obtiene una conexión del pool.
    Uso: async with await obtener_conexion() as conn: ...
    NOTA: Se debe usar con pool.acquire() para gestión automática.
    """
    if _pool is None:
        raise RuntimeError("El pool de conexiones no está inicializado.")
    return await _pool.acquire()


def obtener_pool() -> asyncpg.Pool:
    """Devuelve el pool global. Útil para usar pool.acquire() como context manager."""
    if _pool is None:
        raise RuntimeError("El pool de conexiones no está inicializado.")
    return _pool
