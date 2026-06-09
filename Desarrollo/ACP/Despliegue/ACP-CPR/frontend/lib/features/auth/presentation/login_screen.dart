/// Pantalla de Inicio de Sesión.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colores.dart';
import '../../../core/constants/app_estilos.dart';
import '../../../core/constants/app_rutas.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _ocultarPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authProvider.notifier)
        .iniciarSesion(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Redirigir al home si se autenticó
    ref.listen<AuthState>(authProvider, (anterior, nuevo) {
      if (nuevo.estado == EstadoAuth.autenticado) {
        Navigator.pushReplacementNamed(context, AppRutas.principal);
      }
    });

    return Scaffold(
      backgroundColor: AppColores.fondo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppEstilos.paddingPantalla),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                // Título
                Text(
                  'Iniciar sesión',
                  style: AppEstilos.textoTituloPantalla,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresa tus datos para continuar',
                  style: AppEstilos.textoSecundario,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Campo: Correo electrónico
                Text('Correo electrónico', style: AppEstilos.textoLabel),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decoracionInput('ejemplo@correo.com'),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Ingresa tu correo electrónico.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Campo: Contraseña
                Text('Contraseña', style: AppEstilos.textoLabel),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _ocultarPassword,
                  decoration: _decoracionInput('••••••••').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColores.textoSecundario,
                      ),
                      onPressed: () {
                        setState(() => _ocultarPassword = !_ocultarPassword);
                      },
                    ),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.isEmpty) {
                      return 'Ingresa tu contraseña.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Link: ¿Olvidaste tu contraseña?
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Funcionalidad futura
                    },
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: AppEstilos.textoSecundario.copyWith(
                        color: AppColores.enlace,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Mensaje de error
                if (authState.estado == EstadoAuth.error &&
                    authState.mensajeError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      authState.mensajeError!,
                      style: AppEstilos.textoSecundario.copyWith(
                        color: AppColores.gasto,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Botón: Iniciar sesión
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: authState.estado == EstadoAuth.cargando
                        ? null
                        : _iniciarSesion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColores.primario,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppEstilos.radioBoton,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: authState.estado == EstadoAuth.cargando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text('Iniciar sesión', style: AppEstilos.textoBoton),
                  ),
                ),
                const SizedBox(height: 20),

                // Separador
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColores.borde)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('o', style: AppEstilos.textoSecundario),
                    ),
                    Expanded(child: Divider(color: AppColores.borde)),
                  ],
                ),
                const SizedBox(height: 20),

                // Botón: Google
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: authState.estado == EstadoAuth.cargando
                        ? null
                        : () {
                            ref.read(authProvider.notifier).loginConGoogle();
                          },
                    icon: Image.asset('assets/Googlelogo.png', height: 24),
                    label: Text(
                      'Continuar con Google',
                      style: AppEstilos.textoCuerpoMedio,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColores.textoTitulo,
                      backgroundColor: AppColores.superficie,
                      side: const BorderSide(color: AppColores.borde),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppEstilos.radioBoton,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Link: ¿No tienes cuenta?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿No tienes cuenta? ',
                      style: AppEstilos.textoSecundario,
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(authProvider.notifier).limpiarError();
                        Navigator.pushNamed(context, AppRutas.registro);
                      },
                      child: Text(
                        'Regístrate',
                        style: AppEstilos.textoCuerpoMedio.copyWith(
                          color: AppColores.enlace,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Decoración para inputs del formulario.
  InputDecoration _decoracionInput(String placeholder) {
    return InputDecoration(
      hintText: placeholder,
      hintStyle: AppEstilos.textoSecundario,
      filled: true,
      fillColor: AppColores.superficie,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppEstilos.radioInput),
        borderSide: const BorderSide(color: AppColores.borde),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppEstilos.radioInput),
        borderSide: const BorderSide(color: AppColores.borde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppEstilos.radioInput),
        borderSide: const BorderSide(color: AppColores.borde),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppEstilos.radioInput),
        borderSide: const BorderSide(color: AppColores.borde),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppEstilos.radioInput),
        borderSide: const BorderSide(color: AppColores.borde),
      ),
      errorStyle: AppEstilos.textoSecundario.copyWith(color: AppColores.gasto),
    );
  }
}
