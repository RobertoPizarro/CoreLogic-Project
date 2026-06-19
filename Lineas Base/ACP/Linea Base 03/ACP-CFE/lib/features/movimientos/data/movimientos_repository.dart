/// Repositorio de Movimientos Personales.
import 'dart:async';
import '../../presupuestos/data/presupuestos_repository.dart'; // Importamos el mock de presupuestos

class MovimientosRepository {
  /// Lista de movimientos registrados de forma consistente.
  static final List<Map<String, dynamic>> movimientosMock = [
    {
      'id': 'mov-1',
      'type': 'income',
      'amount': 4500.0,
      'category_id': 'salario',
      'category': 'Sueldo',
      'icon': 'attach_money',
      'date': '2026-05-28',
      'description': 'Sueldo mensual CoreLogic',
      'payment_method': 'transferencia',
    },
    {
      'id': 'mov-2',
      'type': 'expense',
      'amount': 450.0,
      'category_id': 'vivienda',
      'category': 'Vivienda',
      'icon': 'home',
      'date': '2026-05-29',
      'description': 'Mantenimiento departamento',
      'payment_method': 'tarjeta_debito',
    },
    {
      'id': 'mov-3',
      'type': 'expense',
      'amount': 120.0,
      'category_id': 'alimentacion',
      'category': 'Alimentación',
      'icon': 'restaurant',
      'date': '2026-05-30',
      'description': 'Compras supermercado Wong',
      'payment_method': 'tarjeta_credito',
    },
    {
      'id': 'mov-4',
      'type': 'expense',
      'amount': 55.0,
      'category_id': 'entretenimiento',
      'category': 'Entretenimiento',
      'icon': 'movie',
      'date': '2026-05-30',
      'description': 'Suscripción Netflix & Spotify',
      'payment_method': 'tarjeta_credito',
    },
    {
      'id': 'mov-5',
      'type': 'expense',
      'amount': 15.0,
      'category_id': 'transporte',
      'category': 'Transporte',
      'icon': 'directions_car',
      'date': '2026-05-31',
      'description': 'Pasaje taxi Uber',
      'payment_method': 'efectivo',
    },
  ];

  static final List<Map<String, dynamic>> categoriasMock = [
    {'id': 'salario', 'name': 'Sueldo', 'type': 'income', 'icon': 'attach_money'},
    {'id': 'freelance', 'name': 'Freelance', 'type': 'income', 'icon': 'work'},
    {'id': 'inversiones', 'name': 'Inversiones', 'type': 'income', 'icon': 'trending_up'},
    {'id': 'otros_ingresos', 'name': 'Otros', 'type': 'income', 'icon': 'more_horiz'},
    {'id': 'alimentacion', 'name': 'Alimentación', 'type': 'expense', 'icon': 'restaurant'},
    {'id': 'transporte', 'name': 'Transporte', 'type': 'expense', 'icon': 'directions_car'},
    {'id': 'vivienda', 'name': 'Vivienda', 'type': 'expense', 'icon': 'home'},
    {'id': 'servicios', 'name': 'Servicios', 'type': 'expense', 'icon': 'build'},
    {'id': 'entretenimiento', 'name': 'Entretenimiento', 'type': 'expense', 'icon': 'movie'},
    {'id': 'salud', 'name': 'Salud', 'type': 'expense', 'icon': 'local_hospital'},
    {'id': 'educacion', 'name': 'Educación', 'type': 'expense', 'icon': 'school'},
    {'id': 'otros_gastos', 'name': 'Otros', 'type': 'expense', 'icon': 'more_horiz'},
  ];

  /// Lista movimientos de forma local.
  Future<List<dynamic>> listarMovimientos({
    String? tipo,
    String? busqueda,
    int? mes,
    int? anio,
    String? categoryId,
    int limit = 10,
    int offset = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // Copiamos la lista para manipular filtros de manera segura
    var filtrados = List<Map<String, dynamic>>.from(movimientosMock);

    if (tipo != null) {
      filtrados = filtrados.where((m) => m['type'] == tipo).toList();
    }
    if (categoryId != null) {
      filtrados = filtrados.where((m) => m['category_id'] == categoryId).toList();
    }
    if (busqueda != null && busqueda.trim().isNotEmpty) {
      final query = busqueda.trim().toLowerCase();
      filtrados = filtrados.where((m) {
        final desc = (m['description'] ?? '').toString().toLowerCase();
        final catName = (m['category'] ?? '').toString().toLowerCase();
        return desc.contains(query) || catName.contains(query);
      }).toList();
    }

    // Ordenar por fecha descendente (más nuevos primero)
    filtrados.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));

    // Paginación de resultados
    if (offset >= filtrados.length) return [];
    final fin = (offset + limit).clamp(0, filtrados.length);
    return filtrados.sublist(offset, fin);
  }

  /// Obtiene un movimiento específico por su ID.
  Future<Map<String, dynamic>> obtenerMovimiento(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return movimientosMock.firstWhere(
      (m) => m['id'] == id,
      orElse: () => throw Exception('Movimiento no encontrado.'),
    );
  }

  /// Crea un nuevo movimiento local.
  Future<Map<String, dynamic>> crearMovimiento(Map<String, dynamic> datos) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final catId = datos['category_id'];
    final catInfo = categoriasMock.firstWhere((c) => c['id'] == catId, orElse: () => {});

    final nuevoMov = {
      'id': 'mov-${DateTime.now().millisecondsSinceEpoch}',
      'type': datos['type'],
      'amount': (datos['amount'] as num).toDouble(),
      'category_id': catId,
      'category': catInfo['name'] ?? 'Varios',
      'icon': catInfo['icon'] ?? 'more_horiz',
      'date': datos['date'],
      'description': datos['description'] ?? '',
      'payment_method': datos['payment_method'] ?? 'efectivo',
    };

    movimientosMock.add(nuevoMov);
    return nuevoMov;
  }

  /// Edita un movimiento existente de forma local.
  Future<Map<String, dynamic>> editarMovimiento(String id, Map<String, dynamic> datos) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = movimientosMock.indexWhere((m) => m['id'] == id);
    if (index == -1) throw Exception('Movimiento no encontrado.');

    final catId = datos['category_id'];
    final catInfo = categoriasMock.firstWhere((c) => c['id'] == catId, orElse: () => {});

    final editado = {
      ...movimientosMock[index],
      'type': datos['type'] ?? movimientosMock[index]['type'],
      'amount': datos['amount'] != null ? (datos['amount'] as num).toDouble() : movimientosMock[index]['amount'],
      'category_id': catId ?? movimientosMock[index]['category_id'],
      'category': catInfo['name'] ?? movimientosMock[index]['category'],
      'icon': catInfo['icon'] ?? movimientosMock[index]['icon'],
      'date': datos['date'] ?? movimientosMock[index]['date'],
      'description': datos['description'] ?? movimientosMock[index]['description'],
      'payment_method': datos['payment_method'] ?? movimientosMock[index]['payment_method'],
    };

    movimientosMock[index] = editado;
    return editado;
  }

  /// Elimina un movimiento de forma local.
  Future<void> eliminarMovimiento(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    movimientosMock.removeWhere((m) => m['id'] == id);
  }

  /// Evalúa el impacto de un gasto contra los presupuestos en memoria.
  Future<Map<String, dynamic>> evaluarPresupuesto(Map<String, dynamic> datos) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final catId = datos['category_id'];
    final amount = (datos['amount'] as num).toDouble();
    final dateStr = datos['date'];
    final date = DateTime.parse(dateStr);

    // Buscar presupuesto activo que corresponda a esta categoría y rango de fechas
    for (final p in PresupuestosRepository.presupuestosMock) {
      if (p['category_id'] == catId && p['status'] == 'activo') {
        final inicio = DateTime.parse(p['start_date']);
        final fin = DateTime.parse(p['end_date']);

        if (date.isAfter(inicio.subtract(const Duration(seconds: 1))) &&
            date.isBefore(fin.add(const Duration(seconds: 1)))) {
          
          final actualConsumido = PresupuestosRepository.calcularMontoConsumido(p);
          final limite = (p['amount'] as num).toDouble();

          if (actualConsumido + amount > limite) {
            return {
              'excede_presupuesto': true,
              'presupuesto_descripcion': p['description'] ?? '',
              'monto_exceso': (actualConsumido + amount) - limite,
            };
          }
        }
      }
    }

    return {'excede_presupuesto': false};
  }

  /// Lista categorías del mock.
  Future<List<dynamic>> listarCategorias({String? tipo}) async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (tipo == null) return categoriasMock;
    return categoriasMock.where((c) => c['type'] == tipo).toList();
  }
}
