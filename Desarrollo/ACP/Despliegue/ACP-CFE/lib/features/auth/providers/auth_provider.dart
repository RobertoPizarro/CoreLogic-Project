/// Provider de autenticación de usuario.
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  StreamSubscription<SimulatedAuthState>? _authSubscription;

  AuthNotifier(this._repositorio)
    : super(
        AuthState(
          estado: _repositorio.sesionActiva
              ? EstadoAuth.autenticado
              : EstadoAuth.noAutenticado,
        ),
      ) {
    // Escucha cambios del estado de la sesión para actualizar el estado del provider.
    _authSubscription = _repositorio.estadoAuth.listen((event) async {
      if (event.event == SimulatedAuthChangeEvent.signedIn &&
          state.estado != EstadoAuth.autenticado) {
        try {
          await _repositorio.asegurarPerfilExiste();
        } catch (_) {
          // Si falla la verificación, no bloquear el acceso
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

  /// Registra un nuevo usuario con correo y contraseña.
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

  /// Inicia sesión con correo y contraseña.
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

  /// Inicia sesión utilizando Google.
  Future<void> loginConGoogle() async {
    state = AuthState(estado: EstadoAuth.cargando);
    try {
      await _repositorio.iniciarSesionConGoogle();
      state = AuthState(estado: EstadoAuth.autenticado);
    } catch (e) {
      String mensaje = _traducirError(e.toString());
      state = AuthState(estado: EstadoAuth.error, mensajeError: mensaje);
    }
  }

  /// Cierra la sesión activa.
  Future<void> cerrarSesion() async {
    await _repositorio.cerrarSesion();
    state = AuthState(estado: EstadoAuth.noAutenticado);
  }

  /// Limpia los estados de error de autenticación.
  void limpiarError() {
    if (state.estado == EstadoAuth.error) {
      state = AuthState(estado: EstadoAuth.noAutenticado);
    }
  }

  /// Convierte excepciones de autenticación en mensajes legibles en español.
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

