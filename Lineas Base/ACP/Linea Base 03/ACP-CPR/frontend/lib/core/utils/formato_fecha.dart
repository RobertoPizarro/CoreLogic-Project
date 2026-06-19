/// Utilidades para formateo de fechas en español.
import 'package:intl/intl.dart';

class FormatoFecha {
  static DateTime _parsearFecha(String fechaIso) {
    if (fechaIso.contains('T')) {
      return DateTime.parse(fechaIso).toLocal();
    }
    final parts = fechaIso.split('-');
    if (parts.length == 3) {
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }
    return DateTime.parse(fechaIso);
  }

  /// Formato: "10 jul 2025"
  static String formatearCorta(String fechaIso) {
    final fecha = _parsearFecha(fechaIso);
    return DateFormat('d MMM yyyy', 'es').format(fecha);
  }

  /// Formato: "10 de julio de 2025"
  static String formatearLarga(String fechaIso) {
    final fecha = _parsearFecha(fechaIso);
    return DateFormat("d 'de' MMMM 'de' yyyy", 'es').format(fecha);
  }

  /// Formato: "julio 2025"
  static String formatearMesAnio(String fechaIso) {
    final fecha = _parsearFecha(fechaIso);
    return DateFormat('MMMM yyyy', 'es').format(fecha);
  }

  /// Convierte DateTime a string ISO (YYYY-MM-DD) para enviar al backend
  static String aIso(DateTime fecha) {
    return DateFormat('yyyy-MM-dd').format(fecha);
  }
}
