/// Pantalla Splash / Bienvenida.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colores.dart';
import '../../../core/constants/app_estilos.dart';
import '../../../core/constants/app_rutas.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    // Esperar un momento para mostrar el splash
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final sesion = Supabase.instance.client.auth.currentSession;
    if (sesion != null) {
      Navigator.pushReplacementNamed(context, AppRutas.principal);
    } else {
      Navigator.pushReplacementNamed(context, AppRutas.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColores.fondo,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/ACPlogo.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            // Nombre de la app
            Text(
              'ACP',
              style: AppEstilos.textoTituloPantalla.copyWith(
                color: AppColores.textoTitulo,
              ),
            ),
            const SizedBox(height: 8),
            // Subtítulo
            Text(
              'Toma el control de cada sol.',
              style: AppEstilos.textoSecundario,
            ),
          ],
        ),
      ),
    );
  }
}
