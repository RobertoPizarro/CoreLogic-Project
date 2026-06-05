/// Provider de autenticación con Riverpod.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../data/auth_repository.dart';

// Provider del repositorio
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Estado de autenticación
enum EstadoAuth { inicial, cargando, autenticado, noAutenticado, error }

class AuthState {
  final EstadoAuth estado;
  final String? mensajeError;

  AuthState({required this.estado, this.mensajeError});

  AuthState copyWith({EstadoAuth? estado, String? mensajeError}) {
    return AuthState(estado: estado ?? this.estado, mensajeError: mensajeError);
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repositorio;
  StreamSubscription<supabase.AuthState>? _authSubscription;

  AuthNotifier(this._repositorio)
    : super(
        AuthState(
          estado: _repositorio.sesionActiva
              ? EstadoAuth.autenticado
              : EstadoAuth.noAutenticado,
        ),
      ) {
    // Escucha cambios de autenticación para detectar el retorno del Deep Link
    // de Google OAuth. Cuando el usuario completa la autenticación en el navegador
    // y regresa a la app, Supabase emite un evento signedIn.
    _authSubscription = _repositorio.estadoAuth.listen((event) async {
      if (event.event == supabase.AuthChangeEvent.signedIn &&
          state.estado != EstadoAuth.autenticado) {
        try {
          await _repositorio.asegurarPerfilExiste();
        } catch (_) {
          // Si falla la creación del perfil, no bloquear el login
        }
        state = AuthState(estado: EstadoAuth.autenticado);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> registrar({
    required String nombreCompleto,
    required String email,
    required String password,
  }) async {
    state = AuthState(estado: EstadoAuth.cargando);
    try {
      await _repositorio.registrar(
        nombreCompleto: nombreCompleto,
        email: email,
        password: password,
      );
      state = AuthState(estado: EstadoAuth.autenticado);
    } catch (e) {
      String mensaje = _traducirError(e.toString());
      state = AuthState(estado: EstadoAuth.error, mensajeError: mensaje);
    }
  }

  Future<void> iniciarSesion({
    required String email,
    required String password,
  }) async {
    state = AuthState(estado: EstadoAuth.cargando);
    try {
      await _repositorio.iniciarSesion(email: email, password: password);
      state = AuthState(estado: EstadoAuth.autenticado);
    } catch (e) {
      String mensaje = _traducirError(e.toString());
      state = AuthState(estado: EstadoAuth.error, mensajeError: mensaje);
    }
  }

  /// Inicia el flujo de autenticación con Google OAuth.
  /// Abre el navegador del dispositivo. El estado se actualiza automáticamente
  /// cuando el Deep Link retorna gracias al listener de onAuthStateChange.
  Future<void> loginConGoogle() async {
    state = AuthState(estado: EstadoAuth.cargando);
    try {
      await _repositorio.iniciarSesionConGoogle();
      // No cambia a autenticado: el navegador se abre y la app
      // queda en segundo plano. El listener de onAuthStateChange
      // detectará el retorno y actualizará el estado.
      state = AuthState(estado: EstadoAuth.noAutenticado);
    } catch (e) {
      String mensaje = _traducirError(e.toString());
      state = AuthState(estado: EstadoAuth.error, mensajeError: mensaje);
    }
  }

  Future<void> cerrarSesion() async {
    await _repositorio.cerrarSesion();
    state = AuthState(estado: EstadoAuth.noAutenticado);
  }

  void limpiarError() {
    if (state.estado == EstadoAuth.error) {
      state = AuthState(estado: EstadoAuth.noAutenticado);
    }
  }

  /// Traduce errores de Supabase a mensajes en español para el usuario.
  String _traducirError(String error) {
    final errorLower = error.toLowerCase();
    if (errorLower.contains('user already registered') ||
        errorLower.contains('already been registered')) {
      return 'Este correo ya está en uso.';
    }
    if (errorLower.contains('invalid login credentials') ||
        errorLower.contains('invalid email or password')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (errorLower.contains('email not confirmed')) {
      return 'Debes confirmar tu correo electrónico.';
    }
    if (errorLower.contains('password') && errorLower.contains('6')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (errorLower.contains('invalid email')) {
      return 'Correo electrónico inválido.';
    }
    if (errorLower.contains('network') || errorLower.contains('socket')) {
      return 'Error de conexión. Verifica tu internet.';
    }
    return 'Ocurrió un error. Intenta de nuevo.';
  }
}

// Provider del notifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repositorio = ref.read(authRepositoryProvider);
  return AuthNotifier(repositorio);
});
