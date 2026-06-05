/// Provider de Home con Riverpod.
/// Maneja la carga de datos del dashboard.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository();
});

/// Provider que carga los datos del Home automáticamente
final homeProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repositorio = ref.read(homeRepositoryProvider);
  return await repositorio.obtenerDatosHome();
});
