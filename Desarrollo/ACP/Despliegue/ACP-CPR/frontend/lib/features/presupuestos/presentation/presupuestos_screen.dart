/// Pantalla de Presupuestos

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colores.dart';
import '../../../core/constants/app_estilos.dart';
import '../../../core/constants/app_rutas.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import '../../../shared/widgets/iconos_categorias.dart';
import '../../../shared/widgets/boton_notificacion.dart';
import '../providers/presupuestos_provider.dart';

class PresupuestosScreen extends ConsumerStatefulWidget {
  const PresupuestosScreen({super.key});

  @override
  ConsumerState<PresupuestosScreen> createState() => PresupuestosScreenState();
}

class PresupuestosScreenState extends ConsumerState<PresupuestosScreen> {
  final _busquedaController = TextEditingController();
  List<dynamic> _presupuestos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPresupuestos();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarPresupuestos() async {
    setState(() => _cargando = _presupuestos.isEmpty);
    try {
      final repo = ref.read(presupuestosRepositoryProvider);
      final datos = await repo.listarPresupuestos(
        busqueda: _busquedaController.text.trim().isEmpty
            ? null
            : _busquedaController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _presupuestos = datos;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void recargar() => _cargarPresupuestos();

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
                  Text('Presupuestos', style: AppEstilos.textoTituloPantalla),
                  const BotonNotificacion(),
                ],
              ),
              const SizedBox(height: 16),
              // Búsqueda de presupuestos
              TextField(
                controller: _busquedaController,
                onSubmitted: (_) => _cargarPresupuestos(),
                decoration: InputDecoration(
                  hintText: 'Buscar presupuesto...',
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
                            _cargarPresupuestos();
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
                    ? ListView(
                        children: List.generate(
                          4,
                          (_) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SkeletonLoading(
                              height: 100,
                              borderRadius: AppEstilos.radioCard,
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColores.primario,
                        onRefresh: _cargarPresupuestos,
                        child: _presupuestos.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.2,
                                  ),
                                  Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.pie_chart_outline,
                                          size: 64,
                                          color: AppColores.textoSecundario,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _busquedaController.text
                                                  .trim()
                                                  .isNotEmpty
                                              ? 'No se encontraron presupuestos'
                                              : 'Sin presupuestos',
                                          style: AppEstilos.textoCuerpoMedio,
                                        ),
                                        if (_busquedaController.text
                                            .trim()
                                            .isEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Crea tu primer presupuesto',
                                            style: AppEstilos.textoSecundario,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                itemCount: _presupuestos.length,
                                itemBuilder: (c, i) => _itemPresupuesto(
                                  context,
                                  ref,
                                  _presupuestos[i],
                                ),
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: () async {
          await Navigator.pushNamed(context, AppRutas.crearPresupuesto);
          _cargarPresupuestos();
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
              Text('Nuevo presupuesto', style: AppEstilos.textoBoton),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemPresupuesto(BuildContext context, WidgetRef ref, dynamic p) {
    final monto = (p['amount'] as num).toDouble();
    final consumido = (p['consumed'] as num).toDouble();
    final porcentaje = (p['percentage_used'] as num).toDouble();
    final estado = p['status'] as String;
    final excedido = consumido > monto;

    Color colorBarra;
    Color colorBadge;
    Color colorIconoFondo;
    Color colorIcono;

    if (excedido) {
      colorBarra = AppColores.gasto;
      colorBadge = AppColores.gasto;
      colorIconoFondo = AppColores.gastoSuave;
      colorIcono = AppColores.gasto;
    } else if (estado == 'vencido') {
      colorBarra = AppColores.vencido;
      colorBadge = AppColores.vencido;
      colorIconoFondo = const Color(0xFFF0F0F0);
      colorIcono = AppColores.vencido;
    } else if (estado == 'proximo') {
      colorBarra = AppColores.borde;
      colorBadge = AppColores.vencido;
      colorIconoFondo = const Color(0xFFF0F0F0);
      colorIcono = AppColores.vencido;
    } else {
      colorBarra = AppColores.primario;
      colorBadge = AppColores.primario;
      colorIconoFondo = AppColores.primarioSuave;
      colorIcono = AppColores.primario;
    }

    final badgeTexto = estado == 'activo'
        ? 'Activo'
        : estado == 'proximo'
        ? 'Próximo'
        : 'Vencido';

    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(
          context,
          AppRutas.detallePresupuesto,
          arguments: {'id': p['id']},
        );
        _cargarPresupuestos();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: AppEstilos.espacioEntreCards),
        decoration: BoxDecoration(
          color: AppColores.superficie,
          borderRadius: BorderRadius.circular(AppEstilos.radioCard),
          boxShadow: [AppEstilos.sombraCard],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorIconoFondo,
                    borderRadius: BorderRadius.circular(
                      AppEstilos.radioIconoCategoria,
                    ),
                  ),
                  child: Icon(
                    IconosCategorias.obtenerIcono(p['icon'] ?? ''),
                    size: 22,
                    color: colorIcono,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    p['description'] ?? '',
                    style: AppEstilos.textoCuerpoMedio,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorBadge,
                    borderRadius: BorderRadius.circular(AppEstilos.radioBadge),
                  ),
                  child: Text(badgeTexto, style: AppEstilos.textoBadge),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'S/. ${consumido.toStringAsFixed(0)}  de  S/. ${monto.toStringAsFixed(0)}',
              style: AppEstilos.textoSecundario.copyWith(
                color: excedido ? AppColores.gasto : null,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (porcentaje / 100).clamp(0.0, 1.0),
                backgroundColor: AppColores.borde,
                color: colorBarra,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
