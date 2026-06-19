"""
Manejadores globales de errores HTTP.
Todos los errores del backend devuelven JSON con formato estándar:
{"error": "descripcion_del_error", "detalle": "Mensaje legible"}
"""

from fastapi import Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError


async def manejador_validacion(request: Request, exc: RequestValidationError):
    """Maneja errores de validación de Pydantic (datos inválidos en el request)."""
    errores = exc.errors()
    primer_error = errores[0] if errores else {}
    campo = " → ".join(str(loc) for loc in primer_error.get("loc", []))
    mensaje = primer_error.get("msg", "Error de validación")

    return JSONResponse(
        status_code=400,
        content={
            "error": "datos_invalidos",
            "detalle": f"Campo '{campo}': {mensaje}",
        },
    )


async def manejador_error_general(request: Request, exc: Exception):
    """Maneja cualquier error no capturado."""
    return JSONResponse(
        status_code=500,
        content={
            "error": "error_interno",
            "detalle": "Error interno del servidor. Intenta de nuevo más tarde.",
        },
    )
