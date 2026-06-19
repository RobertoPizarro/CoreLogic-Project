/// Repositorio de Grupos y Gastos Compartidos.

import '../../../core/network/dio_client.dart';

class GruposRepository {
  final _dio = DioClient().dio;

  // ─── Grupos ───

  /// Lista los grupos del usuario.
  Future<List<dynamic>> listarGrupos({String? busqueda}) async {
    final respuesta = await _dio.get(
      '/grupos',
      queryParameters: busqueda != null && busqueda.trim().isNotEmpty
          ? {'busqueda': busqueda.trim()}
          : null,
    );
    return respuesta.data['grupos'] as List<dynamic>;
  }

  /// Crea un nuevo grupo.
  Future<Map<String, dynamic>> crearGrupo(Map<String, dynamic> datos) async {
    final respuesta = await _dio.post('/grupos', data: datos);
    return respuesta.data;
  }

  /// Invita a un miembro por correo.
  Future<void> invitarMiembro(String grupoId, String email) async {
    await _dio.post('/grupos/$grupoId/invitar', data: {'email': email});
  }

  /// Acepta la invitación a un grupo.
  Future<void> unirseAGrupo(String grupoId) async {
    await _dio.post('/grupos/$grupoId/unirse');
  }

  // ─── Gastos Compartidos ───

  /// Lista los gastos de un grupo.
  Future<Map<String, dynamic>> listarGastos(String grupoId) async {
    final respuesta = await _dio.get('/grupos/$grupoId/gastos');
    return respuesta.data;
  }

  /// Crea un gasto compartido.
  Future<Map<String, dynamic>> crearGasto(
    String grupoId,
    Map<String, dynamic> datos,
  ) async {
    final respuesta = await _dio.post('/grupos/$grupoId/gastos', data: datos);
    return respuesta.data;
  }

  /// Obtiene el detalle de un gasto compartido.
  Future<Map<String, dynamic>> obtenerGasto(
    String grupoId,
    String gastoId,
  ) async {
    final respuesta = await _dio.get('/grupos/$grupoId/gastos/$gastoId');
    return respuesta.data;
  }

  /// Edita un gasto compartido.
  Future<Map<String, dynamic>> editarGasto(
    String grupoId,
    String gastoId,
    Map<String, dynamic> datos,
  ) async {
    final respuesta = await _dio.put(
      '/grupos/$grupoId/gastos/$gastoId',
      data: datos,
    );
    return respuesta.data;
  }

  /// Elimina un gasto compartido.
  Future<void> eliminarGasto(String grupoId, String gastoId) async {
    await _dio.delete('/grupos/$grupoId/gastos/$gastoId');
  }

  // ─── Balances ───

  /// Obtiene los balances del grupo.
  Future<Map<String, dynamic>> obtenerBalances(String grupoId) async {
    final respuesta = await _dio.get('/grupos/$grupoId/balances');
    return respuesta.data;
  }

  // ─── Pagos ───

  /// Registra un pago entre miembros.
  Future<Map<String, dynamic>> registrarPago(
    String grupoId,
    Map<String, dynamic> datos,
  ) async {
    final respuesta = await _dio.post('/grupos/$grupoId/pagos', data: datos);
    return respuesta.data;
  }
}
