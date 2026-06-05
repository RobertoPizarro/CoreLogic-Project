/// Cliente HTTP Dio con interceptores para JWT automático y manejo de errores.

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DioClient {
  static final DioClient _instancia = DioClient._interno();
  late final Dio dio;

  factory DioClient() => _instancia;

  DioClient._interno() {
    dio = Dio(
      BaseOptions(
        // Para el emulador Android. apunta al localhost de la máquina host
        baseUrl: 'http://10.0.2.2:8000',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Interceptor para adjuntar JWT automáticamente
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (opciones, handler) async {
          // Obtener el token de la sesión activa de Supabase
          final sesion = Supabase.instance.client.auth.currentSession;
          if (sesion != null) {
            opciones.headers['Authorization'] = 'Bearer ${sesion.accessToken}';
          }
          handler.next(opciones);
        },
        onError: (error, handler) {
          // Si recibe 401, el token expiró y el frontend debe redirigir al login
          if (error.response?.statusCode == 401) {
            // El manejo de redirección se hace en el auth provider
            // que escucha los cambios de sesión de Supabase
          }
          handler.next(error);
        },
      ),
    );
  }
}
