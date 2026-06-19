# 💻 ACP - Backend

---

## 🚀 Configuración e Instalación del Entorno

Sigue estos pasos detallados para configurar y levantar el servidor local en tu entorno de desarrollo:

### 1. Requisitos Previos

Asegúrate de contar con:

- [PyCharm](https://www.jetbrains.com/pycharm/) (2026.1.1 o versión similar) como IDE recomendado.
- Python 3.10 o superior instalado en tu sistema.

### 2. Abrir el Proyecto e Inicializar Entorno Virtual

1. Abre la carpeta `backend/` del proyecto directamente desde **PyCharm**.
2. El IDE debería detectar la estructura y crear/asociar automáticamente el entorno virtual (`.venv`).
3. Si lo haces manualmente por terminal:
   ```bash
   python -m venv .venv
   # Activar en Windows (PowerShell):
   .venv\Scripts\Activate.ps1
   # Activar en Linux/macOS:
   source .venv/bin/activate
   ```

### 3. Instalar Dependencias

Abre la terminal integrada de PyCharm en la ruta `backend/` y ejecuta:

```bash
pip install -r requirements.txt
```

### 4. Configurar Variables de Entorno

> ⚠️ **IMPORTANTE:** Debes tener un archivo `.env` configurado en la raíz de la carpeta `backend/`. Este archivo es indispensable para conectar la API con los servicios de base de datos y Supabase.

---

## 🏃‍♂️ Cómo Ejecutar el Servidor

Para levantar el backend de manera local:

Desde la terminal en el directorio `backend/`, ejecuta el siguiente comando con **Uvicorn**:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

---

## 📂 Estructura del backend

El backend se organiza siguiendo patrones limpios de modularidad:

```text
backend/
├── app/
│   ├── core/           # Configuración global, seguridad, JWT y middleware CORS
│   ├── models/         # Modelos de dominio y definición de estructuras
│   ├── routers/        # Controladores de la API
│   │   ├── auth.py
│   │   ├── movimientos.py
│   │   ├── presupuestos.py
│   │   ├── reportes.py
│   │   └── grupos.py
│   ├── schemas/        # Modelos Pydantic (esquemas de validación entrada/salida)
│   ├── services/       # Lógica de negocio y consultas SQL directas
│   └── main.py         # Punto de entrada de la aplicación FastAPI
├── .env                # Variables de entorno locales
└── requirements.txt    # Lista de dependencias del servidor Python
```
