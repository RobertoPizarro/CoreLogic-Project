/// Punto de entrada de la aplicación ACP.
/// Envuelve la app en ProviderScope de Riverpod.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar datos de localización para fechas en español
  await initializeDateFormatting('es', null);

  runApp(const ProviderScope(child: AcpApp()));
}
