/// Repositorio de Movimientos Personales.

import '../../../core/network/dio_client.dart';

class MovimientosRepository {
  final _dio = DioClient().dio;

  /// Lista movimientos con filtros opcionales y paginación.
  Future<List<dynamic>> listarMovimientos({
    String? tipo,
    String? busqueda,
    int? mes,
    int? anio,
    String? categoryId,
    int limit = 10,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{'limit': limit, 'offset': offset};
    if (tipo != null) params['type'] = tipo;
    if (busqueda != null && busqueda.isNotEmpty) params['busqueda'] = busqueda;
    if (mes != null) params['mes'] = mes;
    if (anio != null) params['anio'] = anio;
    if (categoryId != null) params['category_id'] = categoryId;

    final respuesta = await _dio.get('/movimientos', queryParameters: params);
    return respuesta.data as List<dynamic>;
  }

  /// Obtiene el detalle de un movimiento por ID.
  Future<Map<String, dynamic>> obtenerMovimiento(String id) async {
    final respuesta = await _dio.get('/movimientos/$id');
    return respuesta.data;
  }

  /// Crea un nuevo movimiento.
  Future<Map<String, dynamic>> crearMovimiento(
    Map<String, dynamic> datos,
  ) async {
    final respuesta = await _dio.post('/movimientos', data: datos);
    return respuesta.data;
  }

  /// Edita un movimiento existente.
  Future<Map<String, dynamic>> editarMovimiento(
    String id,
    Map<String, dynamic> datos,
  ) async {
    final respuesta = await _dio.put('/movimientos/$id', data: datos);
    return respuesta.data;
  }

  /// Elimina un movimiento.
  Future<void> eliminarMovimiento(String id) async {
    await _dio.delete('/movimientos/$id');
  }

  /// Evalúa si un gasto excede algún presupuesto activo.
  Future<Map<String, dynamic>> evaluarPresupuesto(
    Map<String, dynamic> datos,
  ) async {
    final respuesta = await _dio.post(
      '/movimientos/evaluar-presupuesto',
      data: datos,
    );
    return respuesta.data;
  }

  /// Lista categorías, opcionalmente filtradas por tipo.
  Future<List<dynamic>> listarCategorias({String? tipo}) async {
    final params = <String, dynamic>{};
    if (tipo != null) params['type'] = tipo;
    final respuesta = await _dio.get('/categorias', queryParameters: params);
    return respuesta.data['categorias'] as List<dynamic>;
  }
}
