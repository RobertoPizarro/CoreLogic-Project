/// Pantalla de Perfil de usuario.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colores.dart';
import '../../../core/constants/app_estilos.dart';
import '../../../core/constants/app_rutas.dart';
import '../../../shared/widgets/boton_notificacion.dart';
import '../../auth/providers/auth_provider.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});
  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  String _nombre = '';
  String _email = '';
  bool _cargando = true;
  bool _notificaciones = true;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    setState(() {
      _nombre = 'Usuario Prueba';
      _email = 'usuario.prueba@corelogic.com';
      _cargando = false;
    });
  }

  Future<void> _cerrarSesion() async {
    await ref.read(authProvider.notifier).cerrarSesion();
    if (mounted)
      Navigator.pushNamedAndRemoveUntil(context, AppRutas.login, (r) => false);
  }

  /// Genera las iniciales del nombre (máximo 2 letras)
  String _obtenerIniciales(String nombre) {
    if (nombre.isEmpty) return 'U';
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nombre[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColores.fondo,
      body: SafeArea(
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(color: AppColores.primario),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppEstilos.paddingPantalla),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Perfil', style: AppEstilos.textoTituloPantalla),
                        const BotonNotificacion(),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Card: Avatar + nombre + email
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColores.superficie,
                        borderRadius: BorderRadius.circular(
                          AppEstilos.radioCard,
                        ),
                        boxShadow: [AppEstilos.sombraCard],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColores.primario,
                            child: Text(
                              _obtenerIniciales(_nombre),
                              style: AppEstilos.textoCuerpoMedio.copyWith(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nombre,
                                  style: AppEstilos.textoCuerpoMedio,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(_email, style: AppEstilos.textoSecundario),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sección: Cuenta
                    Text(
                      'Cuenta',
                      style: AppEstilos.textoSecundario.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColores.superficie,
                        borderRadius: BorderRadius.circular(
                          AppEstilos.radioCard,
                        ),
                        boxShadow: [AppEstilos.sombraCard],
                      ),
                      child: Column(
                        children: [
                          _opcionItem(
                            Icons.settings_outlined,
                            'Editar perfil',
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: AppColores.textoSecundario,
                              size: 22,
                            ),
                          ),
                          const Divider(
                            color: AppColores.borde,
                            height: 1,
                            indent: 52,
                          ),
                          _opcionItem(
                            Icons.lock_outline,
                            'Cambiar contraseña',
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: AppColores.textoSecundario,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sección: Preferencias
                    Text(
                      'Preferencias',
                      style: AppEstilos.textoSecundario.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColores.superficie,
                        borderRadius: BorderRadius.circular(
                          AppEstilos.radioCard,
                        ),
                        boxShadow: [AppEstilos.sombraCard],
                      ),
                      child: _opcionItem(
                        Icons.notifications_outlined,
                        'Notificaciones',
                        trailing: Switch(
                          value: _notificaciones,
                          onChanged: (v) => setState(() => _notificaciones = v),
                          activeColor: AppColores.primario,
                          activeTrackColor: AppColores.primarioSuave,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sección: App
                    Text(
                      'App',
                      style: AppEstilos.textoSecundario.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColores.superficie,
                        borderRadius: BorderRadius.circular(
                          AppEstilos.radioCard,
                        ),
                        boxShadow: [AppEstilos.sombraCard],
                      ),
                      child: Column(
                        children: [
                          _opcionItem(
                            Icons.info_outline,
                            'Acerca de',
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: AppColores.textoSecundario,
                              size: 22,
                            ),
                          ),
                          const Divider(
                            color: AppColores.borde,
                            height: 1,
                            indent: 52,
                          ),
                          _opcionItem(
                            Icons.shield_outlined,
                            'Política de privacidad',
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: AppColores.textoSecundario,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón cerrar sesión
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _cerrarSesion,
                        icon: const Icon(Icons.logout, size: 20),
                        label: Text(
                          'Cerrar sesión',
                          style: AppEstilos.textoBoton,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColores.gasto,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppEstilos.radioBoton,
                            ),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _opcionItem(IconData icono, String titulo, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColores.primarioSuave,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: AppColores.primario, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(titulo, style: AppEstilos.textoCuerpoMedio)),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
