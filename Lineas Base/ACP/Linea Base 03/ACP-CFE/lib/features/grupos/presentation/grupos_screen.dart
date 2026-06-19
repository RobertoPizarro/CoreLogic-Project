/// Pantalla de lista de Grupos del usuario.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colores.dart';
import '../../../core/constants/app_estilos.dart';
import '../../../core/constants/app_rutas.dart';
import '../../../shared/widgets/boton_notificacion.dart';
import '../providers/grupos_provider.dart';

class GruposScreen extends ConsumerStatefulWidget {
  const GruposScreen({super.key});

  @override
  ConsumerState<GruposScreen> createState() => GruposScreenState();
}

class GruposScreenState extends ConsumerState<GruposScreen> {
  final _busquedaController = TextEditingController();
  List<dynamic> _grupos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarGrupos();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarGrupos() async {
    setState(() => _cargando = _grupos.isEmpty);
    try {
      final repo = ref.read(gruposRepositoryProvider);
      final grupos = await repo.listarGrupos(
        busqueda: _busquedaController.text.trim().isEmpty
            ? null
            : _busquedaController.text.trim(),
      );
      if (mounted)
        setState(() {
          _grupos = grupos;
          _cargando = false;
        });
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void recargar() => _cargarGrupos();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColores.fondo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppEstilos.paddingPantalla),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Grupos', style: AppEstilos.textoTituloPantalla),
                  const BotonNotificacion(),
                ],
              ),
              const SizedBox(height: 16),
              // Búsqueda de grupos
              TextField(
                controller: _busquedaController,
                onSubmitted: (_) => _cargarGrupos(),
                decoration: InputDecoration(
                  hintText: 'Buscar grupo...',
                  hintStyle: AppEstilos.textoSecundario,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColores.textoSecundario,
                  ),
                  suffixIcon: _busquedaController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: AppColores.textoSecundario,
                          ),
                          onPressed: () {
                            _busquedaController.clear();
                            _cargarGrupos();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColores.superficie,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppEstilos.radioInput),
                    borderSide: const BorderSide(color: AppColores.borde),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppEstilos.radioInput),
                    borderSide: const BorderSide(color: AppColores.borde),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppEstilos.radioInput),
                    borderSide: const BorderSide(color: AppColores.borde),
                  ),
                ),
                onChanged: (text) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _cargando
                    ? _buildSkeleton()
                    : _grupos.isEmpty
                    ? _buildVacio()
                    : _buildLista(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: () async {
        final resultado = await Navigator.pushNamed(
          context,
          AppRutas.crearGrupo,
        );
        if (resultado == true) _cargarGrupos();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColores.primario,
          borderRadius: BorderRadius.circular(AppEstilos.radioBoton),
          boxShadow: [AppEstilos.sombraFAB],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Nuevo grupo', style: AppEstilos.textoBoton),
          ],
        ),
      ),
    );
  }

  Widget _buildVacio() {
    final esBusqueda = _busquedaController.text.trim().isNotEmpty;
    return RefreshIndicator(
      color: AppColores.primario,
      onRefresh: _cargarGrupos,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group_outlined,
                  size: 64,
                  color: AppColores.textoSecundario,
                ),
                const SizedBox(height: 16),
                Text(
                  esBusqueda ? 'No se encontraron grupos' : 'Sin grupos',
                  style: AppEstilos.textoCuerpoMedio,
                ),
                if (!esBusqueda) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Crea un grupo para empezar a dividir gastos',
                    style: AppEstilos.textoSecundario,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    return RefreshIndicator(
      color: AppColores.primario,
      onRefresh: _cargarGrupos,
      child: ListView.separated(
        itemCount: _grupos.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppEstilos.espacioEntreCards),
        itemBuilder: (context, index) => _buildCardGrupo(_grupos[index]),
      ),
    );
  }

  Widget _buildCardGrupo(Map<String, dynamic> grupo) {
    final miembros = grupo['members'] as List<dynamic>? ?? [];
    final balance = grupo['my_balance_summary'] as Map<String, dynamic>? ?? {};
    final esPendiente = balance['status'] == 'pendiente_invitacion';
    final nombre = grupo['name'] ?? '';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: esPendiente
          ? null
          : () async {
              await Navigator.pushNamed(
                context,
                AppRutas.detalleGrupo,
                arguments: {'id': grupo['id'], 'name': grupo['name']},
              );
              _cargarGrupos();
            },
      child: Container(
        padding: const EdgeInsets.all(AppEstilos.paddingCard),
        decoration: BoxDecoration(
          color: AppColores.superficie,
          borderRadius: BorderRadius.circular(AppEstilos.radioCard),
          boxShadow: [AppEstilos.sombraCard],
        ),
        child: Row(
          children: [
            // Avatar grande con inicial del grupo
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColores.colorParaGrupo(grupo['id'] ?? ''),
              child: Text(
                inicial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Nombre y avatares de miembros
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: AppEstilos.textoCuerpoMedio,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _buildAvataresPequenos(miembros),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Balance o botón unirse
            esPendiente
                ? _buildBotonUnirse(grupo['id'])
                : _buildBalanceTexto(balance),
          ],
        ),
      ),
    );
  }

  Widget _buildAvataresPequenos(List<dynamic> miembros) {
    final maxMostrar = miembros.length > 4 ? 4 : miembros.length;
    return SizedBox(
      height: 22,
      child: Stack(
        children: List.generate(maxMostrar, (i) {
          final uid = miembros[i]['user_id'] as String? ?? '';
          final nombre = miembros[i]['name'] ?? '';
          final iniciales = nombre
              .split(' ')
              .take(2)
              .map((p) => p.isNotEmpty ? p[0] : '')
              .join()
              .toUpperCase();
          final color = AppColores.colorParaUsuario(uid);
          return Positioned(
            left: i * 18.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: CircleAvatar(
                radius: 10,
                backgroundColor: color,
                child: Text(
                  iniciales,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBalanceTexto(Map<String, dynamic> balance) {
    final estado = balance['status'];
    final monto = (balance['amount'] as num?)?.toDouble();

    if (estado == 'debes') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '-S/. ${monto?.toStringAsFixed(2)}',
            style: AppEstilos.textoCuerpoMedio.copyWith(
              color: AppColores.gasto,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'debes',
            style: AppEstilos.textoSecundario.copyWith(fontSize: 12),
          ),
        ],
      );
    } else if (estado == 'te_deben') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '+S/. ${monto?.toStringAsFixed(2)}',
            style: AppEstilos.textoCuerpoMedio.copyWith(
              color: AppColores.primario,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'te deben',
            style: AppEstilos.textoSecundario.copyWith(fontSize: 12),
          ),
        ],
      );
    } else {
      return Text('Saldado', style: AppEstilos.textoSecundario);
    }
  }

  Widget _buildBotonUnirse(String grupoId) {
    return GestureDetector(
      onTap: () async {
        try {
          final repo = ref.read(gruposRepositoryProvider);
          await repo.unirseAGrupo(grupoId);
          _cargarGrupos();
        } catch (e) {
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error al unirse al grupo.')),
            );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColores.primario,
          borderRadius: BorderRadius.circular(AppEstilos.radioBoton),
        ),
        child: Text(
          'Unirse',
          style: AppEstilos.textoBoton.copyWith(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColores.skeletonBase,
      highlightColor: AppColores.skeletonHighlight,
      child: ListView.separated(
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppEstilos.radioCard),
          ),
        ),
      ),
    );
  }
}
