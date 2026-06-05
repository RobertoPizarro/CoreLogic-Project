/// Provider de Presupuestos con Riverpod.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/presupuestos_repository.dart';

/// Provider para instanciar el repositorio de presupuestos.
final presupuestosRepositoryProvider = Provider<PresupuestosRepository>((ref) {
  return PresupuestosRepository();
});

/// Provider de la lista de presupuestos
final presupuestosProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final repo = ref.read(presupuestosRepositoryProvider);
  return await repo.listarPresupuestos();
});
