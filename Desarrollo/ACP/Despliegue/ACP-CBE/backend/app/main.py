"""
Registra routers, manejadores de errores, eventos y CORS.
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware

from app.core.database import crear_pool, cerrar_pool
from app.core.errors import manejador_validacion, manejador_error_general
from app.routers import auth, home, movimientos, presupuestos, categorias, grupos, reportes


@asynccontextmanager
async def ciclo_de_vida(app: FastAPI):
    """Maneja el inicio y cierre de recursos del servidor."""
    # Startup: crear pool de conexiones a la BD
    await crear_pool()
    print("✅ Pool de conexiones a PostgreSQL creado.")
    yield
    # Shutdown: cerrar pool
    await cerrar_pool()
    print("🛑 Pool de conexiones cerrado.")


app = FastAPI(
    title="ACP — API de Control Presupuestal",
    description="Backend para la aplicación móvil ACP de control presupuestal personal y compartido.",
    version="1.0.0",
    lifespan=ciclo_de_vida,
)

# --- CORS ---
# Permitir todas las conexiones en desarrollo (Flutter se conecta desde emulador)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Manejadores de errores ---
app.add_exception_handler(RequestValidationError, manejador_validacion)
app.add_exception_handler(Exception, manejador_error_general)

# --- Routers ---
app.include_router(auth.router)
app.include_router(home.router)
app.include_router(movimientos.router)
app.include_router(presupuestos.router)
app.include_router(categorias.router)
app.include_router(grupos.router)
app.include_router(reportes.router)


@app.get("/")
async def raiz():
    """Endpoint de verificación de que el servidor está corriendo."""
    return {"mensaje": "ACP Backend activo"}
