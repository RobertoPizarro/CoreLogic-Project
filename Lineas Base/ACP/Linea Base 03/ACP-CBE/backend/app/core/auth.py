"""
Validación del JWT de Supabase.
Dependencia de FastAPI que se inyecta en todos los endpoints protegidos.
Extrae el user_id  y el email del token usando JWKS.
"""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
import jwt
from jwt import PyJWKClient

from app.config import SUPABASE_URL

# Esquema de seguridad Bearer
esquema_seguridad = HTTPBearer()

# Cliente JWKS para obtener las claves públicas de Supabase automáticamente
jwks_url = f"{SUPABASE_URL}/auth/v1/.well-known/jwks.json"
jwks_client = PyJWKClient(jwks_url)

class DatosUsuario:
    """Datos extraídos del JWT validado."""

    def __init__(self, user_id: str, email: str):
        self.user_id = user_id
        self.email = email


async def obtener_usuario_actual(
    credenciales: HTTPAuthorizationCredentials = Depends(esquema_seguridad),
) -> DatosUsuario:
    """
    Dependencia de FastAPI que valida el JWT de Supabase.
    Obtiene la clave pública
    """
    token = credenciales.credentials

    try:
        # Obtener la clave de firma correspondiente desde el JWKS de Supabase
        signing_key = jwks_client.get_signing_key_from_jwt(token)
        
        # Decodificar y validar el JWT
        payload = jwt.decode(
            token,
            signing_key.key,
            algorithms=["ES256", "HS256"],
            audience="authenticated",
        )

        user_id = payload.get("sub")
        email = payload.get("email", "")

        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token inválido: no contiene user_id.",
            )

        return DatosUsuario(user_id=user_id, email=email)

    except jwt.PyJWKClientError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Error conectando con Supabase para validar el token.",
        )
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="El token ha expirado. Inicia sesión nuevamente.",
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido.",
        )
