/// Provider de Movimientos con Riverpod.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/movimientos_repository.dart';

final movimientosRepositoryProvider = Provider<MovimientosRepository>((ref) {
  return MovimientosRepository();
});

/// Provider para la lista de movimientos (se invalida al crear/editar/eliminar)
final movimientosProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final repositorio = ref.read(movimientosRepositoryProvider);
  return await repositorio.listarMovimientos();
});

/// Caché global de todas las categorías — se cargan una sola vez desde el backend.
final _todasCategoriasProvider = FutureProvider<List<dynamic>>((ref) async {
  final repositorio = ref.read(movimientosRepositoryProvider);
  return await repositorio.listarCategorias();
});

/// Provider para obtener categorías filtradas por tipo.
/// Lee del caché global
final categoriasProvider = Provider.family<AsyncValue<List<dynamic>>, String?>((
  ref,
  tipo,
) {
  final todas = ref.watch(_todasCategoriasProvider);
  return todas.whenData((lista) {
    if (tipo == null) return lista;
    return lista.where((c) => c['type'] == tipo).toList();
  });
});
