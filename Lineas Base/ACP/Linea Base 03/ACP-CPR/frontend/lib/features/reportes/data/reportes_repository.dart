import '../../../core/network/dio_client.dart';

/// Repositorio del Módulo de Reportes.

class ReportesRepository {
  final _dio = DioClient().dio;

  /// Obtiene el resumen financiero agrupado por períodos.
  Future<Map<String, dynamic>> obtenerResumen({
    required String vista,
    String? mes,
    int? anio,
  }) async {
    final params = <String, dynamic>{'vista': vista};
    if (mes != null) params['mes'] = mes;
    if (anio != null) params['anio'] = anio;

    final respuesta = await _dio.get('/reportes', queryParameters: params);
    return respuesta.data as Map<String, dynamic>;
  }

  /// Obtiene la distribución porcentual y montos por categoría.
  Future<Map<String, dynamic>> obtenerDistribucionCategorias({
    required String vista,
    required String tipo,
    String? mes,
    int? anio,
  }) async {
    final params = <String, dynamic>{'vista': vista, 'tipo': tipo};
    if (mes != null) params['mes'] = mes;
    if (anio != null) params['anio'] = anio;

    final respuesta = await _dio.get(
      '/reportes/categorias',
      queryParameters: params,
    );
    return respuesta.data as Map<String, dynamic>;
  }
}
