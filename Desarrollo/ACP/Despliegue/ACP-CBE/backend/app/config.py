"""
Carga las variables de entorno necesarias para Supabase y la base de datos.
"""

import os
from dotenv import load_dotenv

# Cargar variables desde el archivo .env ubicado en la raíz del backend
load_dotenv(dotenv_path=os.path.join(os.path.dirname(os.path.dirname(__file__)), ".env"))

SUPABASE_URL: str = os.getenv("SUPABASE_URL", "")
SUPABASE_ANON_KEY: str = os.getenv("SUPABASE_ANON_KEY", "")
SUPABASE_JWT_SECRET: str = os.getenv("SUPABASE_JWT_SECRET", "")
DATABASE_URL: str = os.getenv("DATABASE_URL", "")
