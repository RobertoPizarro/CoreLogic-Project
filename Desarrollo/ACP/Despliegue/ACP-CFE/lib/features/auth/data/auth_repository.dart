/// Repositorio de autenticación de usuario.
import 'dart:async';

enum SimulatedAuthChangeEvent {
  signedIn,
  signedOut,
}

class SimulatedAuthState {
  final SimulatedAuthChangeEvent event;
  SimulatedAuthState(this.event);
}

class AuthRepository {
  static bool _sesionActiva = false;
  static final _controller = StreamController<SimulatedAuthState>.broadcast();

  /// Registra un nuevo usuario.
  Future<void> registrar({
    required String nombreCompleto,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _sesionActiva = true;
    _controller.add(SimulatedAuthState(SimulatedAuthChangeEvent.signedIn));
  }

  /// Inicia sesión.
  Future<void> iniciarSesion({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _sesionActiva = true;
    _controller.add(SimulatedAuthState(SimulatedAuthChangeEvent.signedIn));
  }

  /// Cierra la sesión del usuario.
  Future<void> cerrarSesion() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _sesionActiva = false;
    _controller.add(SimulatedAuthState(SimulatedAuthChangeEvent.signedOut));
  }

  /// Inicia sesión utilizando Google.
  Future<void> iniciarSesionConGoogle() async {
    await Future.delayed(const Duration(milliseconds: 800));
    _sesionActiva = true;
    _controller.add(SimulatedAuthState(SimulatedAuthChangeEvent.signedIn));
  }

  /// Verifica la existencia del perfil del usuario.
  Future<void> asegurarPerfilExiste() async {
    // Operación local de verificación
  }

  /// Obtiene si hay una sesión activa en la aplicación.
  bool get sesionActiva => _sesionActiva;

  /// Stream para propagar eventos de cambios de autenticación.
  Stream<SimulatedAuthState> get estadoAuth => _controller.stream;
}

