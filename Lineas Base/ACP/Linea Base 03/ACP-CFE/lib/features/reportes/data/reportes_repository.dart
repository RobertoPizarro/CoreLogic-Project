/// Repositorio de Reportes.
import 'dart:async';
import '../../movimientos/data/movimientos_repository.dart';

class ReportesRepository {
  /// Obtiene el resumen financiero acumulado basándose dinámicamente en los movimientos de memoria.
  Future<Map<String, dynamic>> obtenerResumen({
    required String vista,
    String? mes,
    int? anio,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

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

    return {
      'vista': vista,
      'mes': mes,
      'anio': anio,
      'periodos': [
        {
          'label': mes != null ? 'Este mes' : 'Este año',
          'rango_fechas': {
            'desde': '2026-05-01',
            'hasta': '2026-05-31',
          },
          'total_ingresos': totalIngresos,
          'total_gastos': totalGastos,
          'balance': totalIngresos - totalGastos,
        }
      ]
    };
  }

  /// Obtiene la distribución por categorías calculada en tiempo real sobre los movimientos locales.
  Future<Map<String, dynamic>> obtenerDistribucionCategorias({
    required String vista,
    required String tipo,
    String? mes,
    int? anio,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    final Map<String, double> sumasCategorias = {};
    double totalMonto = 0.0;

    for (final m in MovimientosRepository.movimientosMock) {
      if (m['type'] == tipo) {
        final catId = m['category_id'];
        final amt = (m['amount'] as num).toDouble();
        sumasCategorias[catId] = (sumasCategorias[catId] ?? 0.0) + amt;
        totalMonto += amt;
      }
    }

    final List<Map<String, dynamic>> categorias = [];
    sumasCategorias.forEach((catId, suma) {
      final catInfo = MovimientosRepository.categoriasMock.firstWhere(
        (c) => c['id'] == catId,
        orElse: () => {},
      );
      final name = catInfo['name'] ?? 'Otros';
      final icon = catInfo['icon'] ?? 'more_horiz';
      final pct = totalMonto > 0 ? (suma / totalMonto) * 100 : 0.0;

      categorias.add({
        'category_id': catId,
        'name': name,
        'icon': icon,
        'amount': suma,
        'percentage': pct,
      });
    });

    // Ordenar por monto descendente (mayor a menor)
    categorias.sort((a, b) => b['amount'].compareTo(a['amount']));

    return {
      'vista': vista,
      'mes': mes,
      'anio': anio,
      'tipo': tipo,
      'total_monto': totalMonto,
      'categorias': categorias,
    };
  }
}
