/// Pantalla de Registro.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colores.dart';
import '../../../core/constants/app_estilos.dart';
import '../../../core/constants/app_rutas.dart';
import '../providers/auth_provider.dart';

class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _ocultarPassword = true;
  bool _ocultarConfirmacion = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authProvider.notifier)
        .registrar(
          nombreCompleto: _nombreController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Redirigir al home si se registró exitosamente
    ref.listen<AuthState>(authProvider, (anterior, nuevo) {
      if (nuevo.estado == EstadoAuth.autenticado) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRutas.principal,
          (route) => false,
        );
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
                const SizedBox(height: 40),
                // Título
                Text(
                  'Crear cuenta',
                  style: AppEstilos.textoTituloPantalla,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Completa tus datos para comenzar',
                  style: AppEstilos.textoSecundario,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Campo: Nombres completos
                Text('Nombres completos', style: AppEstilos.textoLabel),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 50,
                  buildCounter:
                      (
                        _, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                  decoration: _decoracionInput('Nombre y Apellidos'),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Ingresa tu nombre completo.';
                    }
                    final nombreLimpio = valor.trim();
                    final regexLetras = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ ]+$');
                    if (!regexLetras.hasMatch(nombreLimpio)) {
                      return 'El nombre solo debe contener letras y espacios.';
                    }
                    final palabras = nombreLimpio.split(RegExp(r'\s+'));
                    if (palabras.length < 2) {
                      return 'Ingresa al menos un nombre y un apellido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

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
                    final regex = RegExp(
                      r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                    );
                    if (!regex.hasMatch(valor.trim())) {
                      return 'Correo electrónico inválido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo: Contraseña
                Text('Contraseña', style: AppEstilos.textoLabel),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _ocultarPassword,
                  decoration: _decoracionInput('Mínimo 6 caracteres').copyWith(
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
                      return 'Ingresa una contraseña.';
                    }
                    if (valor.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo: Confirmar contraseña
                Text('Confirmar contraseña', style: AppEstilos.textoLabel),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmarController,
                  obscureText: _ocultarConfirmacion,
                  decoration: _decoracionInput('Repite tu contraseña').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarConfirmacion
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColores.textoSecundario,
                      ),
                      onPressed: () {
                        setState(
                          () => _ocultarConfirmacion = !_ocultarConfirmacion,
                        );
                      },
                    ),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.isEmpty) {
                      return 'Confirma tu contraseña.';
                    }
                    if (valor != _passwordController.text) {
                      return 'Las contraseñas no coinciden.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

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

                // Botón: Crear cuenta
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: authState.estado == EstadoAuth.cargando
                        ? null
                        : _registrar,
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
                        : Text('Crear cuenta', style: AppEstilos.textoBoton),
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
                      side: const BorderSide(color: AppColores.borde),
                      backgroundColor: AppColores.superficie,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppEstilos.radioBoton,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Link: ¿Ya tienes cuenta?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Ya tienes cuenta? ',
                      style: AppEstilos.textoSecundario,
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(authProvider.notifier).limpiarError();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Inicia sesión',
                        style: AppEstilos.textoCuerpoMedio.copyWith(
                          color: AppColores.enlace,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
