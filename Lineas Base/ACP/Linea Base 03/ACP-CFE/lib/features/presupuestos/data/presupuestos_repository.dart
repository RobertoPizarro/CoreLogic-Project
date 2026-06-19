/// Repositorio de Presupuestos Personales.
import 'dart:async';
import '../../movimientos/data/movimientos_repository.dart';

class PresupuestosRepository {
  /// Lista de presupuestos registrados.
  static final List<Map<String, dynamic>> presupuestosMock = [
    {
      'id': 'pre-1',
      'category_id': 'alimentacion',
      'category': 'Alimentación',
      'icon': 'restaurant',
      'amount': 600.0,
      'description': 'Presupuesto de comida mensual',
      'start_date': '2026-05-01',
      'end_date': '2026-06-01',
      'status': 'activo',
    },
    {
      'id': 'pre-2',
      'category_id': 'entretenimiento',
      'category': 'Entretenimiento',
      'icon': 'movie',
      'amount': 200.0,
      'description': 'Presupuesto diversión',
      'start_date': '2026-05-01',
      'end_date': '2026-06-01',
      'status': 'activo',
    },
  ];

  /// Calcula el monto consumido por un presupuesto sumando los gastos realizados en su periodo.
  static double calcularMontoConsumido(Map<String, dynamic> presupuesto) {
    double total = 0.0;
    final catId = presupuesto['category_id'];
    final inicio = DateTime.parse(presupuesto['start_date']);
    final fin = DateTime.parse(presupuesto['end_date']);

    for (final m in MovimientosRepository.movimientosMock) {
      if (m['type'] == 'expense' && m['category_id'] == catId) {
        final fechaMov = DateTime.parse(m['date']);
        if (fechaMov.isAfter(inicio.subtract(const Duration(seconds: 1))) &&
            fechaMov.isBefore(fin.add(const Duration(seconds: 1)))) {
          total += (m['amount'] as num).toDouble();
        }
      }
    }
    return total;
  }

  /// Inyecta los campos calculados de progreso en el mapa de presupuesto para consumo en la UI.
  static Map<String, dynamic> _inyectarCalculos(Map<String, dynamic> p) {
    final spent = calcularMontoConsumido(p);
    final limit = (p['amount'] as num).toDouble();
    final percentage = limit > 0 ? (spent / limit) * 100 : 0.0;
    final remaining = limit - spent;

    return {
      ...p,
      'spent': spent,
      'percentage': percentage,
      'consumed': spent,
      'percentage_used': percentage,
      'remaining': remaining,
    };
  }

  /// Obtiene la lista de presupuestos con sus respectivos cálculos de progreso.
  Future<List<dynamic>> listarPresupuestos({String? busqueda}) async {
    await Future.delayed(const Duration(milliseconds: 200));

    var filtrados = List<Map<String, dynamic>>.from(presupuestosMock);

    if (busqueda != null && busqueda.trim().isNotEmpty) {
      final query = busqueda.trim().toLowerCase();
      filtrados = filtrados.where((p) {
        final desc = (p['description'] ?? '').toString().toLowerCase();
        final cat = (p['category'] ?? '').toString().toLowerCase();
        return desc.contains(query) || cat.contains(query);
      }).toList();
    }

    return filtrados.map((p) => _inyectarCalculos(p)).toList();
  }

  /// Obtiene los detalles de un presupuesto específico por su ID.
  Future<Map<String, dynamic>> obtenerPresupuesto(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final p = presupuestosMock.firstWhere(
      (p) => p['id'] == id,
      orElse: () => throw Exception('Presupuesto no encontrado.'),
    );
    return _inyectarCalculos(p);
  }

  /// Crea un nuevo presupuesto.
  Future<Map<String, dynamic>> crearPresupuesto(Map<String, dynamic> datos) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final catId = datos['category_id'];
    final catInfo = MovimientosRepository.categoriasMock.firstWhere(
      (c) => c['id'] == catId,
      orElse: () => {},
    );

    final nuevoPresupuesto = {
      'id': 'pre-${DateTime.now().millisecondsSinceEpoch}',
      'category_id': catId,
      'category': catInfo['name'] ?? 'Otros',
      'icon': catInfo['icon'] ?? 'more_horiz',
      'amount': (datos['amount'] as num).toDouble(),
      'description': datos['description'] ?? '',
      'start_date': datos['start_date'],
      'end_date': datos['end_date'],
      'status': 'activo',
    };

    presupuestosMock.add(nuevoPresupuesto);
    return _inyectarCalculos(nuevoPresupuesto);
  }

  /// Edita un presupuesto existente.
  Future<Map<String, dynamic>> editarPresupuesto(String id, Map<String, dynamic> datos) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = presupuestosMock.indexWhere((p) => p['id'] == id);
    if (index == -1) throw Exception('Presupuesto no encontrado.');

    final catId = datos['category_id'];
    final catInfo = MovimientosRepository.categoriasMock.firstWhere(
      (c) => c['id'] == catId,
      orElse: () => {},
    );

    final editado = {
      ...presupuestosMock[index],
      if (catId != null) 'category_id': catId,
      if (catId != null) 'category': catInfo['name'] ?? presupuestosMock[index]['category'],
      if (catId != null) 'icon': catInfo['icon'] ?? presupuestosMock[index]['icon'],
      if (datos['amount'] != null) 'amount': (datos['amount'] as num).toDouble(),
      if (datos['description'] != null) 'description': datos['description'],
      if (datos['start_date'] != null) 'start_date': datos['start_date'],
      if (datos['end_date'] != null) 'end_date': datos['end_date'],
    };

    presupuestosMock[index] = editado;
    return _inyectarCalculos(editado);
  }

  /// Elimina un presupuesto específico.
  Future<void> eliminarPresupuesto(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    presupuestosMock.removeWhere((p) => p['id'] == id);
  }
}

