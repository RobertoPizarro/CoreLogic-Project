import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reportes_repository.dart';

/// Provider para obtener la instancia única del repositorio de reportes.
final reportesRepositoryProvider = Provider<ReportesRepository>((ref) {
  return ReportesRepository();
});
