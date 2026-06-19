# 📱 ACP - Frontend

---

## 🚀 Configuración e Instalación del Entorno

Sigue detalladamente estos pasos para configurar tu entorno y correr la aplicación móvil:

### 1. Requisitos Previos

Asegúrate de contar con lo siguiente instalado y configurado:

- [Android Studio](https://developer.android.com/studio) (Panda 4 2025.3.4 Patch 1 o posterior).
- **Flutter SDK** (Desde Antigravity o VSC, instalas la extensión de flutter y te saldra una ventana para instalar el SDK).

### 2. Configuración en Android Studio

1. Abre Android Studio.
2. Haz clic en los tres puntos de la esquina superior derecha ➔ **SDK Manager** ➔ **SDK Tools**.
3. Marca la casilla **"Android SDK Command-line Tools (latest)"** y haz clic en **Apply**.
4. Ve a la sección de **Plugins** y descarga el plugin oficial de **Flutter**.

### 3. Instalar Dependencias

Abre una terminal en la ruta de la carpeta `frontend/` y ejecuta:

```bash
flutter pub get
```

### 4. Aceptar Licencias de Android

Ejecuta el siguiente comando en la terminal para aceptar todos los acuerdos de licencia de Android (presiona `y` y luego `Enter` para cada una cuando se te solicite):

```bash
flutter doctor --android-licenses
```

### 5. Verificar Estado del Entorno

Para confirmar que tu SDK de Flutter y herramientas de compilación están completamente configurados, ejecuta:

```bash
flutter doctor
```

### 6. Configuración de Credenciales en Android Studio

1. En la barra de herramientas superior de Android Studio (al lado del botón verde de **Play**), haz clic en el menú desplegable que dice **`main.dart`** y selecciona **`Edit Configurations...`**.
2. En la ventana que se abre, asegúrate de que esté seleccionado **Flutter ➔ main.dart** a la izquierda.
3. A la derecha, en el campo de texto **`Additional run args`**, escribe exactamente:
   ```text
   --dart-define-from-file=config.json
   ```
4. Haz clic en **Apply** (Aplicar) y luego en **OK**.

> ⚠️ **IMPORTANTE:** Asegúrate de que el archivo `config.json` con las variables de entorno de Supabase esté presente en la raíz de la carpeta `frontend/`.

---

## 📱 Configurar y Lanzar el Emulador

Para poder visualizar e interactuar con la aplicación, debes crear un dispositivo virtual:

1. En Android Studio, abre el **Device Manager** (Administrador de dispositivos) en el panel lateral derecho y presiona el botón **"+"** (Create device).
2. Elige la categoría _Phone_, selecciona el modelo **Pixel 8** y presiona _Next_.
3. Selecciona la imagen del sistema **API 34** (descárgala si no la tienes en tu equipo) y finaliza la creación.
4. Lanza el emulador recién creado haciendo clic en el botón de **Play (Run)**.

> **⚠️ IMPORTANTE:** Dentro de la configuración de Android del propio emulador Pixel 8, ve a _Settings ➔ System ➔ Date & Time_ y asegúrate de **configurar la zona horaria en la de Perú** (GMT-5).

---

## 🏃‍♂️ Cómo Ejecutar la Aplicación

En Android Studio, desde la carpeta `frontend/`::

1. Abre el **Device Manager** y lanza el emulador **Pixel 8** haciendo clic en el ícono de "Run" (Play).
2. En la barra de herramientas superior, asegúrate de que el **Pixel 8** esté seleccionado como dispositivo objetivo.
3. Haz clic en el botón verde de **Run** (Play) ubicado en la parte superior para compilar y lanzar la app en el emulador.

---

## 📂 Estructura del frontend

El frontend adopta un enfoque modular basado en "features" (características):

```text
frontend/
├── assets/               # imágenes, fuentes, etc.
├── android/              # Archivos de configuración nativa de la plataforma Android
├── lib/
│   ├── app.dart          # Configuración de rutas globales, temas y providers de inicio
│   ├── main.dart         # Punto de entrada de la aplicación de Flutter
│   ├── core/             # Constantes globales, estilos de texto y paleta de colores
│   ├── shared/           # Widgets compartidos
│   └── features/         # Módulos de ACP
│       ├── auth/         # Registro, Login y estado de sesión
│       ├── home/         # Panel principal y navegación inferior
│       ├── movimientos/  # Registro, detalle y edición de movimientos
│       ├── presupuestos/ # Gestión, asignación y estado de alertas de presupuesto
│       ├── reportes/     # Reportes
│       └── grupos/       # Grupos y gastos compartidos
├── config.json           # Variables de entorno locales
├── pubspec.yaml          # Lista de dependencias de Flutter
└── analysis_options.yaml # Reglas del linter
```
