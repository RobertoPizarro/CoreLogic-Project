/// Barra de navegación

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colores.dart';
import '../../../core/constants/app_estilos.dart';
import '../../movimientos/presentation/movimientos_screen.dart';
import '../../presupuestos/presentation/presupuestos_screen.dart';
import '../../perfil/presentation/perfil_screen.dart';
import '../../grupos/presentation/grupos_screen.dart';
import 'home_screen.dart';

final navegacionIndexProvider = StateProvider<int>((ref) => 0);

class NavegadorPrincipal extends ConsumerStatefulWidget {
  const NavegadorPrincipal({super.key});

  @override
  ConsumerState<NavegadorPrincipal> createState() => _NavegadorPrincipalState();
}

class _NavegadorPrincipalState extends ConsumerState<NavegadorPrincipal> {
  /// Key global para poder llamar a recargar en MovimientosScreen
  final _movimientosKey = GlobalKey<MovimientosScreenState>();

  /// Key global para poder llamar a recargar en PresupuestosScreen
  final _presupuestosKey = GlobalKey<PresupuestosScreenState>();

  /// Key global para poder llamar a recargar en GruposScreen
  final _gruposKey = GlobalKey<GruposScreenState>();

  late final List<Widget> _pantallas;

  @override
  void initState() {
    super.initState();
    _pantallas = [
      const HomeScreen(),
      MovimientosScreen(key: _movimientosKey),
      PresupuestosScreen(key: _presupuestosKey),
      GruposScreen(key: _gruposKey),
      const PerfilScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final indiceActual = ref.watch(navegacionIndexProvider);

    ref.listen<int>(navegacionIndexProvider, (anterior, nuevo) {
      final ant = anterior ?? 0;
      if (nuevo == 1 && ant != 1) {
        _movimientosKey.currentState?.recargar();
      }
      if (nuevo == 2 && ant != 2) {
        _presupuestosKey.currentState?.recargar();
      }
      if (nuevo == 3 && ant != 3) {
        _gruposKey.currentState?.recargar();
      }
    });

    return Scaffold(
      body: IndexedStack(index: indiceActual, children: _pantallas),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColores.superficie,
          border: Border(top: BorderSide(color: AppColores.borde, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: indiceActual,
          onTap: (indice) => ref.read(navegacionIndexProvider.notifier).state = indice,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColores.superficie,
          selectedItemColor: AppColores.primario,
          unselectedItemColor: AppColores.textoSecundario,
          selectedLabelStyle: AppEstilos.textoNavBar,
          unselectedLabelStyle: AppEstilos.textoNavBar,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz_outlined),
              activeIcon: Icon(Icons.swap_horiz),
              label: 'Movimientos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline),
              activeIcon: Icon(Icons.pie_chart),
              label: 'Presupuestos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group),
              label: 'Grupos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
