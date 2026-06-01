/// Provider de Grupos con Riverpod.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/grupos_repository.dart';

final gruposRepositoryProvider = Provider<GruposRepository>((ref) {
  return GruposRepository();
});

/// Provider para la lista de grupos (se invalida al crear/unirse)
final gruposProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repositorio = ref.read(gruposRepositoryProvider);
  return await repositorio.listarGrupos();
});
