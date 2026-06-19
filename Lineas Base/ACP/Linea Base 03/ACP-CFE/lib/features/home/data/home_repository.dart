/// Repositorio de Home.
import 'dart:async';
import '../../movimientos/data/movimientos_repository.dart';

class HomeRepository {
  /// Obtiene los datos del Home calculados a partir de los movimientos.
  Future<Map<String, dynamic>> obtenerDatosHome() async {
    await Future.delayed(const Duration(milliseconds: 200));

    double totalIngresos = 0.0;
    double totalGastos = 0.0;

    for (final m in MovimientosRepository.movimientosMock) {
      final amt = (m['amount'] as num).toDouble();
      if (m['type'] == 'income') {
        totalIngresos += amt;
      } else {
        totalGastos += amt;
      }
    }

    final saldoTotal = totalIngresos - totalGastos;

    // Obtener movimientos recientes (los últimos 5 ordenados por fecha)
    final copia = List<Map<String, dynamic>>.from(MovimientosRepository.movimientosMock);
    copia.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
    final recientes = copia.take(5).toList();

    return {
      'saldo_total': saldoTotal,
      'total_ingresos': totalIngresos,
      'total_gastos': totalGastos,
      'movimientos_recientes': recientes,
    };
  }
}
