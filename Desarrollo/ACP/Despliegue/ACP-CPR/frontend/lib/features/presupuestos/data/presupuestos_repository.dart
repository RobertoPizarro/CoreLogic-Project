/// Repositorio de Presupuestos Personales.

import '../../../core/network/dio_client.dart';

class PresupuestosRepository {
  final _dio = DioClient().dio;

  /// Obtiene la lista de presupuestos con opción de filtrado por búsqueda.
  Future<List<dynamic>> listarPresupuestos({String? busqueda}) async {
    final r = await _dio.get(
      '/presupuestos',
      queryParameters: busqueda != null && busqueda.trim().isNotEmpty
          ? {'busqueda': busqueda.trim()}
          : null,
    );
    return r.data as List<dynamic>;
  }

  /// Obtiene los detalles de un presupuesto específico por su ID.
  Future<Map<String, dynamic>> obtenerPresupuesto(String id) async {
    final r = await _dio.get('/presupuestos/$id');
    return r.data;
  }

  /// Crea un nuevo presupuesto en el sistema.
  Future<Map<String, dynamic>> crearPresupuesto(
    Map<String, dynamic> datos,
  ) async {
    final r = await _dio.post('/presupuestos', data: datos);
    return r.data;
  }

  /// Edita un presupuesto existente identificado por su ID.
  Future<Map<String, dynamic>> editarPresupuesto(
    String id,
    Map<String, dynamic> datos,
  ) async {
    final r = await _dio.put('/presupuestos/$id', data: datos);
    return r.data;
  }

  /// Elimina un presupuesto específico del sistema.
  Future<void> eliminarPresupuesto(String id) async {
    await _dio.delete('/presupuestos/$id');
  }
}
