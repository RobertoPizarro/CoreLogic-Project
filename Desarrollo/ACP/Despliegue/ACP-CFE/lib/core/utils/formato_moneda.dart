/// Utilidad para formatear montos en soles peruanos
/// Formato: S/ #,###.##
import 'package:intl/intl.dart';

class FormatoMoneda {
  static final NumberFormat _formato = NumberFormat('#,##0.00', 'es_PE');

  /// Formatea un monto numérico a string con formato S/ #,###.##
  static String formatear(double monto) {
    return 'S/ ${_formato.format(monto)}';
  }

  /// Formatea con signo: +S/ para ingresos, -S/ para gastos
  static String formatearConSigno(double monto, String tipo) {
    final signo = tipo == 'income' ? '+' : '-';
    return '$signo S/ ${_formato.format(monto.abs())}';
  }
}
