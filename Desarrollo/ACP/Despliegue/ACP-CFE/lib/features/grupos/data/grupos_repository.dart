/// Repositorio de Grupos y Gastos Compartidos.
import 'dart:async';

class GruposRepository {
  /// Lista de miembros y grupos.
  static final List<Map<String, dynamic>> miembrosMock = [
    {'user_id': 'me', 'name': 'Usuario', 'status': 'activo'},
    {'user_id': 'lucia', 'name': 'Lucía Torres', 'status': 'activo'},
    {'user_id': 'carlos', 'name': 'Carlos Mendoza', 'status': 'activo'},
    {'user_id': 'andres', 'name': 'Andrés Salas', 'status': 'activo'},
    {'user_id': 'diana', 'name': 'Diana Ríos', 'status': 'pendiente'},
  ];

  static final List<Map<String, dynamic>> gruposMock = [
    {
      'id': 'viaje-cusco',
      'name': 'Viaje a Cusco',
      'members': [
        miembrosMock[0], // yo
        miembrosMock[1], // lucia
        miembrosMock[2], // carlos
        miembrosMock[3], // andres
      ],
      'my_balance_summary': {
        'status': 'debes',
        'amount': 70.0,
        'to': 'Lucía Torres',
      }
    }
  ];

  /// Lista de gastos compartidos en memoria.
  static final List<Map<String, dynamic>> gastosMock = [
    {
      'id': 'gasto-1',
      'group_id': 'viaje-cusco',
      'description': 'Hotel 2 noches',
      'total_amount': 480.0,
      'paid_by': {'user_id': 'lucia', 'name': 'Lucía Torres'},
      'date': '2026-05-28',
      'split_type': 'igual',
      'splits': [
        {'user_id': 'me', 'name': 'Usuario', 'amount_owed': 120.0},
        {'user_id': 'lucia', 'name': 'Lucía Torres', 'amount_owed': 120.0},
        {'user_id': 'carlos', 'name': 'Carlos Mendoza', 'amount_owed': 120.0},
        {'user_id': 'andres', 'name': 'Andrés Salas', 'amount_owed': 120.0},
      ],
    },
    {
      'id': 'gasto-2',
      'group_id': 'viaje-cusco',
      'description': 'Cena bienvenida',
      'total_amount': 220.0,
      'paid_by': {'user_id': 'carlos', 'name': 'Carlos Mendoza'},
      'date': '2026-05-29',
      'split_type': 'igual',
      'splits': [
        {'user_id': 'me', 'name': 'Usuario', 'amount_owed': 55.0},
        {'user_id': 'lucia', 'name': 'Lucía Torres', 'amount_owed': 55.0},
        {'user_id': 'carlos', 'name': 'Carlos Mendoza', 'amount_owed': 55.0},
        {'user_id': 'andres', 'name': 'Andrés Salas', 'amount_owed': 55.0},
      ],
    }
  ];

  /// Lista de pagos/saldos manuales realizados.
  static final List<Map<String, dynamic>> pagosMock = [];

  // ─── Grupos ───

  /// Lista los grupos locales.
  Future<List<dynamic>> listarGrupos({String? busqueda}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var filtrados = List<Map<String, dynamic>>.from(gruposMock);

    if (busqueda != null && busqueda.trim().isNotEmpty) {
      final query = busqueda.trim().toLowerCase();
      filtrados = filtrados.where((g) => g['name'].toString().toLowerCase().contains(query)).toList();
    }

    // Actualizar el resumen del balance de cada grupo dinámicamente antes de retornarlo
    return filtrados.map((g) {
      final bal = _calcularMisBalances(g['id']);
      final netValue = bal['my_net'] as double;
      final Map<String, dynamic> summary = {};

      if (netValue == 0) {
        summary['status'] = 'saldado';
      } else if (netValue > 0) {
        summary['status'] = 'te_deben';
        summary['amount'] = netValue;
      } else {
        summary['status'] = 'debes';
        summary['amount'] = netValue.abs();
        // Buscar a quién le debes más (como aproximación)
        summary['to'] = 'un miembro';
        final debts = bal['my_debts'] as List<dynamic>;
        if (debts.isNotEmpty) {
          summary['to'] = debts[0]['to_name'];
        }
      }

      return {
        ...g,
        'my_balance_summary': summary,
      };
    }).toList();
  }

  /// Crea un nuevo grupo.
  Future<Map<String, dynamic>> crearGrupo(Map<String, dynamic> datos) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final nuevoId = 'grupo-${DateTime.now().millisecondsSinceEpoch}';

    final listMiembros = [
      miembrosMock[0], // el usuario actual creador
    ];

    // Agregar correos invitados
    final invitedEmails = List<String>.from(datos['emails'] ?? []);
    for (final email in invitedEmails) {
      final name = email.split('@')[0];
      listMiembros.add({
        'user_id': 'user-${DateTime.now().millisecondsSinceEpoch}-$name',
        'name': name[0].toUpperCase() + name.substring(1),
        'status': 'pendiente',
      });
    }

    final nuevoGrupo = {
      'id': nuevoId,
      'name': datos['name'],
      'members': listMiembros,
      'my_balance_summary': {'status': 'saldado'},
    };

    gruposMock.add(nuevoGrupo);
    return nuevoGrupo;
  }

  /// Invita a un miembro al grupo.
  Future<void> invitarMiembro(String grupoId, String email) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = gruposMock.indexWhere((g) => g['id'] == grupoId);
    if (index == -1) return;

    final name = email.split('@')[0];
    final nuevoMiembro = {
      'user_id': 'user-${DateTime.now().millisecondsSinceEpoch}-$name',
      'name': name[0].toUpperCase() + name.substring(1),
      'status': 'pendiente',
    };

    final list = List<Map<String, dynamic>>.from(gruposMock[index]['members']);
    list.add(nuevoMiembro);
    gruposMock[index]['members'] = list;
  }

  /// Acepta unirse a un grupo.
  Future<void> unirseAGrupo(String grupoId) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  // ─── Gastos Compartidos ───

  /// Lista los gastos de un grupo de forma local.
  Future<Map<String, dynamic>> listarGastos(String grupoId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final deEsteGrupo = gastosMock.where((g) => g['group_id'] == grupoId).toList();
    // Ordenar de más reciente a más antiguo
    deEsteGrupo.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));

    return {
      'group_id': grupoId,
      'gastos': deEsteGrupo,
    };
  }

  /// Crea un gasto compartido de forma local.
  Future<Map<String, dynamic>> crearGasto(String grupoId, Map<String, dynamic> datos) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final nuevoId = 'gasto-${DateTime.now().millisecondsSinceEpoch}';

    final paidByUid = datos['paid_by'];
    final paidByMember = miembrosMock.firstWhere((m) => m['user_id'] == paidByUid, orElse: () => {'name': 'Miembro'});

    final total = (datos['total_amount'] as num).toDouble();
    final splitType = datos['split_type'];
    final participants = List<String>.from(datos['participants']);

    final List<Map<String, dynamic>> splits = [];
    if (splitType == 'igual') {
      final part = total / participants.length;
      for (final p in participants) {
        final m = miembrosMock.firstWhere((mb) => mb['user_id'] == p, orElse: () => {'name': 'Miembro'});
        splits.add({
          'user_id': p,
          'name': m['name'],
          'amount_owed': part,
        });
      }
    } else {
      final inputSplits = datos['splits'] as List<dynamic>;
      for (final s in inputSplits) {
        final p = s['user_id'];
        final m = miembrosMock.firstWhere((mb) => mb['user_id'] == p, orElse: () => {'name': 'Miembro'});
        splits.add({
          'user_id': p,
          'name': m['name'],
          'amount_owed': (s['amount_owed'] as num).toDouble(),
        });
      }
    }

    final nuevoGasto = {
      'id': nuevoId,
      'group_id': grupoId,
      'description': datos['description'] ?? '',
      'total_amount': total,
      'paid_by': {'user_id': paidByUid, 'name': paidByMember['name']},
      'date': datos['date'],
      'split_type': splitType,
      'splits': splits,
    };

    gastosMock.add(nuevoGasto);
    return nuevoGasto;
  }

  /// Obtiene el detalle de un gasto.
  Future<Map<String, dynamic>> obtenerGasto(String grupoId, String gastoId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return gastosMock.firstWhere((g) => g['id'] == gastoId);
  }

  /// Edita un gasto de forma local.
  Future<Map<String, dynamic>> editarGasto(String grupoId, String gastoId, Map<String, dynamic> datos) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = gastosMock.indexWhere((g) => g['id'] == gastoId);
    if (index == -1) throw Exception('Gasto no encontrado.');

    final paidByUid = datos['paid_by'] ?? gastosMock[index]['paid_by']['user_id'];
    final paidByMember = miembrosMock.firstWhere((m) => m['user_id'] == paidByUid, orElse: () => {'name': 'Miembro'});

    final total = datos['total_amount'] != null ? (datos['total_amount'] as num).toDouble() : gastosMock[index]['total_amount'] as double;
    final splitType = datos['split_type'] ?? gastosMock[index]['split_type'];
    final participants = datos['participants'] != null ? List<String>.from(datos['participants']) : null;

    List<Map<String, dynamic>> splits = [];
    if (participants != null) {
      if (splitType == 'igual') {
        final part = total / participants.length;
        for (final p in participants) {
          final m = miembrosMock.firstWhere((mb) => mb['user_id'] == p, orElse: () => {'name': 'Miembro'});
          splits.add({
            'user_id': p,
            'name': m['name'],
            'amount_owed': part,
          });
        }
      } else {
        final inputSplits = datos['splits'] as List<dynamic>;
        for (final s in inputSplits) {
          final p = s['user_id'];
          final m = miembrosMock.firstWhere((mb) => mb['user_id'] == p, orElse: () => {'name': 'Miembro'});
          splits.add({
            'user_id': p,
            'name': m['name'],
            'amount_owed': (s['amount_owed'] as num).toDouble(),
          });
        }
      }
    } else {
      splits = List<Map<String, dynamic>>.from(gastosMock[index]['splits']);
    }

    final editado = {
      ...gastosMock[index],
      'description': datos['description'] ?? gastosMock[index]['description'],
      'total_amount': total,
      'paid_by': {'user_id': paidByUid, 'name': paidByMember['name']},
      'date': datos['date'] ?? gastosMock[index]['date'],
      'split_type': splitType,
      'splits': splits,
    };

    gastosMock[index] = editado;
    return editado;
  }

  /// Elimina un gasto grupal.
  Future<void> eliminarGasto(String grupoId, String gastoId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    gastosMock.removeWhere((g) => g['id'] == gastoId);
  }

  // ─── Balances ───

  /// Calcula dinámicamente los balances del grupo y los retornos del deudor/acreedor.
  static Map<String, dynamic> _calcularMisBalances(String grupoId) {
    final deEsteGrupo = gastosMock.where((g) => g['group_id'] == grupoId).toList();

    // 1. Obtener la lista de miembros activos del grupo
    final grupo = gruposMock.firstWhere((g) => g['id'] == grupoId, orElse: () => {});
    final List<dynamic> members = grupo['members'] ?? miembrosMock.sublist(0, 4);

    final Map<String, double> pagadoPorMiembro = {};
    final Map<String, double> debeCadaMiembro = {};

    // Inicializar
    for (final m in members) {
      final uid = m['user_id'];
      pagadoPorMiembro[uid] = 0.0;
      debeCadaMiembro[uid] = 0.0;
    }

    // Sumar gastos
    double totalGrupo = 0.0;
    for (final g in deEsteGrupo) {
      final paidBy = g['paid_by']['user_id'];
      final total = (g['total_amount'] as num).toDouble();
      totalGrupo += total;

      pagadoPorMiembro[paidBy] = (pagadoPorMiembro[paidBy] ?? 0.0) + total;

      final splits = g['splits'] as List<dynamic>? ?? [];
      for (final s in splits) {
        final uid = s['user_id'];
        final owed = (s['amount_owed'] as num).toDouble();
        debeCadaMiembro[uid] = (debeCadaMiembro[uid] ?? 0.0) + owed;
      }
    }

    // Tomar en cuenta los pagos registrados manualmente en pagosMock para saldar las cuentas
    for (final p in pagosMock) {
      if (p['group_id'] == grupoId) {
        final from = p['from_user_id'];
        final to = p['to_user_id'];
        final amt = (p['amount'] as num).toDouble();

        // El que paga salda su deuda (se le asume que "pagó" más)
        pagadoPorMiembro[from] = (pagadoPorMiembro[from] ?? 0.0) + amt;
        // El que recibe el dinero ya lo cobró (se le asume que "debe" más para compensar)
        debeCadaMiembro[to] = (debeCadaMiembro[to] ?? 0.0) + amt;
      }
    }

    // Calcular balances netos (paid - owed)
    final List<Map<String, dynamic>> memberBalances = [];
    double myNet = 0.0;

    for (final m in members) {
      final uid = m['user_id'];
      final name = m['name'];
      final paid = pagadoPorMiembro[uid] ?? 0.0;
      final owed = debeCadaMiembro[uid] ?? 0.0;
      final net = paid - owed;

      if (uid == 'me') {
        myNet = net;
      }

      memberBalances.add({
        'user_id': uid,
        'name': name,
        'paid': paid,
        'net': net,
      });
    }

    // Calcular deudas simplificadas (quién le debe a quién)
    // Usamos un algoritmo simple: separar en deudores (net < 0) y acreedores (net > 0)
    final List<Map<String, dynamic>> deudores = [];
    final List<Map<String, dynamic>> acreedores = [];

    for (final mb in memberBalances) {
      final net = mb['net'] as double;
      if (net < 0) {
        deudores.add({'user_id': mb['user_id'], 'name': mb['name'], 'net': net});
      } else if (net > 0) {
        acreedores.add({'user_id': mb['user_id'], 'name': mb['name'], 'net': net});
      }
    }

    final List<Map<String, dynamic>> myDebts = [];
    final List<Map<String, dynamic>> owedToMe = [];

    int dIdx = 0;
    int aIdx = 0;

    while (dIdx < deudores.length && aIdx < acreedores.length) {
      final deudor = deudores[dIdx];
      final acreedor = acreedores[aIdx];

      final double deudaMonto = deudor['net'].abs();
      final double creditoMonto = acreedor['net'];

      final double minAmount = deudaMonto < creditoMonto ? deudaMonto : creditoMonto;

      // Si yo soy el deudor
      if (deudor['user_id'] == 'me' && minAmount > 0) {
        myDebts.add({
          'to_user_id': acreedor['user_id'],
          'to_name': acreedor['name'],
          'amount': minAmount,
        });
      }
      // Si yo soy el acreedor
      if (acreedor['user_id'] == 'me' && minAmount > 0) {
        owedToMe.add({
          'from_user_id': deudor['user_id'],
          'from_name': deudor['name'],
          'amount': minAmount,
        });
      }

      deudores[dIdx]['net'] = deudor['net'] + minAmount;
      acreedores[aIdx]['net'] = acreedor['net'] - minAmount;

      if (deudores[dIdx]['net'].abs() < 0.01) dIdx++;
      if (acreedores[aIdx]['net'] < 0.01) aIdx++;
    }

    return {
      'group_id': grupoId,
      'total_group': totalGrupo,
      'member_balances': memberBalances,
      'my_debts': myDebts,
      'owed_to_me': owedToMe,
      'my_net': myNet,
    };
  }

  /// Obtiene los balances del grupo calculados dinámicamente.
  Future<Map<String, dynamic>> obtenerBalances(String grupoId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _calcularMisBalances(grupoId);
  }

  // ─── Pagos ───

  /// Registra un pago localmente.
  Future<Map<String, dynamic>> registrarPago(String grupoId, Map<String, dynamic> datos) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final nuevoId = 'pago-${DateTime.now().millisecondsSinceEpoch}';

    final toUid = datos['to_user_id'];
    final toMember = miembrosMock.firstWhere((m) => m['user_id'] == toUid, orElse: () => {'name': 'Miembro'});

    final nuevoPago = {
      'id': nuevoId,
      'group_id': grupoId,
      'from_user_id': 'me',
      'from_name': 'Usuario',
      'to_user_id': toUid,
      'to_name': toMember['name'],
      'amount': (datos['amount'] as num).toDouble(),
      'note': datos['note'] ?? 'Pago registrado',
      'date': datos['date'],
    };

    pagosMock.add(nuevoPago);
    return nuevoPago;
  }
}
