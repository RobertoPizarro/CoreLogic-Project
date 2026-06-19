/// Repositorio de autenticación.
/// Maneja el registro, login y logout usando Supabase Auth directamente

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/dio_client.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;
  final _dio = DioClient().dio;

  /// Registra un nuevo usuario en Supabase Auth y crea su perfil en el backend.
  Future<void> registrar({
    required String nombreCompleto,
    required String email,
    required String password,
  }) async {
    // 1. Registrar en Supabase Auth
    final respuesta = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (respuesta.user == null) {
      throw Exception('Error al crear la cuenta.');
    }

    // 2. Crear perfil en el backend (el JWT ya está disponible)
    await _dio.post('/auth/registro', data: {'full_name': nombreCompleto});
  }

  /// Inicia sesión con email y contraseña.
  Future<void> iniciarSesion({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  /// Cierra la sesión activa.
  Future<void> cerrarSesion() async {
    await _supabase.auth.signOut();
  }

  /// Inicia sesión o registra al usuario con Google usando OAuth Web Flow.
  /// Abre el navegador del dispositivo con la pantalla de selección de Google.
  Future<void> iniciarSesionConGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.example.frontend://login-callback',
    );
  }

  /// Verifica si el perfil del usuario existe en la tabla `profiles`.
  /// Si no existe (usuario nuevo de Google), lo crea automáticamente
  /// usando el nombre completo que Google proporcionó a Supabase.
  Future<void> asegurarPerfilExiste() async {
    try {
      // Intentar obtener el perfil existente
      await _dio.get('/perfil');
    } catch (e) {
      // Si no existe, crear el perfil con los datos de Google
      final usuario = _supabase.auth.currentUser;
      final nombreGoogle =
          usuario?.userMetadata?['full_name'] ??
          usuario?.userMetadata?['name'] ??
          'Usuario';
      await _dio.post('/auth/registro', data: {'full_name': nombreGoogle});
    }
  }

  /// Verifica si hay una sesión activa.
  bool get sesionActiva => _supabase.auth.currentSession != null;

  /// Obtiene el stream de cambios de estado de autenticación.
  Stream<AuthState> get estadoAuth => _supabase.auth.onAuthStateChange;
}
