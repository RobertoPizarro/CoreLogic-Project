/// Repositorio de Home.
/// Obtiene saldo, totales y movimientos recientes del backend.
import '../../../core/network/dio_client.dart';

class HomeRepository {
  final _dio = DioClient().dio;

  /// Obtiene los datos del Home: saldo, totales, movimientos recientes.
  Future<Map<String, dynamic>> obtenerDatosHome() async {
    final respuesta = await _dio.get('/home');
    return respuesta.data;
  }
}
