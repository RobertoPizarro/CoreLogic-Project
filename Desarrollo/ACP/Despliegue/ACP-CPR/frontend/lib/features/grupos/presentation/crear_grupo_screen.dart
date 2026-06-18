/// Pantalla de Creación de Grupo.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colores.dart';
import '../../../core/constants/app_estilos.dart';
import '../providers/grupos_provider.dart';

class CrearGrupoScreen extends ConsumerStatefulWidget {
  const CrearGrupoScreen({super.key});

  @override
  ConsumerState<CrearGrupoScreen> createState() => _CrearGrupoScreenState();
}

class _CrearGrupoScreenState extends ConsumerState<CrearGrupoScreen> {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final List<String> _emails = [];
  bool _guardando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _agregarEmail() {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      _snack('Ingresa un correo válido.');
      return;
    }
    // Verificar que no se invite a sí mismo
    final miEmail = Supabase.instance.client.auth.currentUser?.email?.toLowerCase();
    if (miEmail != null && email == miEmail) {
      _snack('No puedes invitarte a ti mismo.');
      return;
    }
    if (_emails.contains(email)) {
      _snack('Ese correo ya fue agregado.');
      return;
    }
    setState(() {
      _emails.add(email);
      _emailController.clear();
    });
  }

  Future<void> _guardar() async {
    if (_nombreController.text.trim().isEmpty) {
      _snack('Ingresa el nombre del grupo.');
      return;
    }
    if (_emails.isEmpty) {
      _snack('Debes agregar al menos a un miembro.');
      return;
    }
    setState(() => _guardando = true);
    try {
      final repo = ref.read(gruposRepositoryProvider);
      await repo.crearGrupo({
        'name': _nombreController.text.trim(),
        'emails': _emails,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('Error al crear el grupo.');
    }
    if (mounted) setState(() => _guardando = false);
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: AppEstilos.textoSecundario,
    filled: true,
    fillColor: AppColores.superficie,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppEstilos.radioInput),
      borderSide: BorderSide(color: AppColores.borde),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppEstilos.radioInput),
      borderSide: BorderSide(color: AppColores.borde),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppEstilos.radioInput),
      borderSide: BorderSide(color: AppColores.borde),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColores.fondo,
      appBar: AppBar(
        backgroundColor: AppColores.fondo,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: AppColores.superficie,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [AppEstilos.sombraBotonBack],
              ),
              child: const Icon(
                Icons.chevron_left,
                color: AppColores.textoTitulo,
              ),
            ),
          ),
        ),
        title: Text(
          'Nuevo grupo',
          style: AppEstilos.textoTituloPantalla.copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppEstilos.paddingPantalla),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  Text('Nombre del grupo', style: AppEstilos.textoLabel),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nombreController,
                    decoration: _deco('Viaje a Cusco'),
                  ),
                  const SizedBox(height: 24),
                  // Invitar miembros
                  Text('Agregar miembros', style: AppEstilos.textoLabel),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _deco('a@example.com'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _agregarEmail,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColores.primario,
                            borderRadius: BorderRadius.circular(
                              AppEstilos.radioInput,
                            ),
                          ),
                          child: Text(
                            'Invitar',
                            style: AppEstilos.textoBoton.copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La invitación se enviará por correo.',
                    style: AppEstilos.textoSecundario.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  // Lista de emails agregados
                  ..._emails.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColores.superficie,
                          borderRadius: BorderRadius.circular(
                            AppEstilos.radioCard,
                          ),
                          border: Border.all(color: AppColores.borde),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColores.colorParaUsuario(
                                e.value,
                              ),
                              child: Text(
                                _iniciales(e.value),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                e.value,
                                style: AppEstilos.textoCuerpo,
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _emails.removeAt(e.key)),
                              child: const Icon(
                                Icons.close,
                                size: 20,
                                color: AppColores.textoSecundario,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Botones fijos abajo
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppEstilos.paddingPantalla,
              0,
              AppEstilos.paddingPantalla,
              24,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColores.borde),
                        backgroundColor: AppColores.superficie,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppEstilos.radioBoton,
                          ),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: AppEstilos.textoCuerpoMedio,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _guardando ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColores.primario,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppEstilos.radioBoton,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: _guardando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Crear Grupo', style: AppEstilos.textoBoton),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _iniciales(String email) {
    final partes = email.split('@').first.split('.');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return email.substring(0, email.length >= 2 ? 2 : 1).toUpperCase();
  }
}
