/// Widget raíz de la aplicación ACP.
/// Configura el tema global, las rutas y el ProviderScope de Riverpod.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_colores.dart';
import 'core/constants/app_rutas.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/registro_screen.dart';
import 'features/home/presentation/navegador_principal.dart';
import 'features/movimientos/presentation/nuevo_movimiento_screen.dart';
import 'features/movimientos/presentation/detalle_movimiento_screen.dart';
import 'features/movimientos/presentation/editar_movimiento_screen.dart';
import 'features/presupuestos/presentation/crear_presupuesto_screen.dart';
import 'features/presupuestos/presentation/detalle_presupuesto_screen.dart';
import 'features/presupuestos/presentation/editar_presupuesto_screen.dart';
import 'features/grupos/presentation/crear_grupo_screen.dart';
import 'features/grupos/presentation/detalle_grupo_screen.dart';
import 'features/grupos/presentation/nuevo_gasto_compartido_screen.dart';
import 'features/grupos/presentation/detalle_gasto_compartido_screen.dart';
import 'features/grupos/presentation/editar_gasto_compartido_screen.dart';
import 'features/grupos/presentation/registrar_pago_screen.dart';
import 'features/reportes/presentation/reportes_screen.dart';

class AcpApp extends StatelessWidget {
  const AcpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ACP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColores.fondo,
        textTheme: GoogleFonts.interTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColores.primario,
          surface: AppColores.superficie,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColores.fondo,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      initialRoute: AppRutas.splash,
      routes: {
        AppRutas.splash: (context) => const SplashScreen(),
        AppRutas.login: (context) => const LoginScreen(),
        AppRutas.registro: (context) => const RegistroScreen(),
        AppRutas.principal: (context) => const NavegadorPrincipal(),
        AppRutas.nuevoMovimiento: (context) => const NuevoMovimientoScreen(),
        AppRutas.crearPresupuesto: (context) => const CrearPresupuestoScreen(),
        AppRutas.crearGrupo: (context) => const CrearGrupoScreen(),
        AppRutas.reportes: (context) => const ReportesScreen(),
      },
      // Rutas que requieren argumentos se manejan con onGenerateRoute
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRutas.detalleMovimiento:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => DetalleMovimientoScreen(movimientoId: args['id']),
            );
          case AppRutas.editarMovimiento:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => EditarMovimientoScreen(movimiento: args),
            );
          case AppRutas.detallePresupuesto:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => DetallePresupuestoScreen(presupuestoId: args['id']),
            );
          case AppRutas.editarPresupuesto:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => EditarPresupuestoScreen(presupuesto: args),
            );
          case AppRutas.detalleGrupo:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => DetalleGrupoScreen(grupoId: args['id'], grupoNombre: args['name']),
            );
          case AppRutas.nuevoGastoCompartido:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => NuevoGastoCompartidoScreen(grupoId: args['group_id'], miembros: args['members'] as List<dynamic>),
            );
          case AppRutas.detalleGastoCompartido:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => DetalleGastoCompartidoScreen(grupoId: args['group_id'], gastoId: args['gasto_id'], miembros: args['members'] as List<dynamic>),
            );
          case AppRutas.editarGastoCompartido:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => EditarGastoCompartidoScreen(grupoId: args['group_id'], gasto: args['gasto'], miembros: args['members'] as List<dynamic>),
            );
          case AppRutas.registrarPago:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => RegistrarPagoScreen(
                grupoId: args['group_id'], toUserId: args['to_user_id'],
                toName: args['to_name'], maxAmount: (args['max_amount'] as num).toDouble()),
            );
          default:
            return null;
        }
      },
    );
  }
}

