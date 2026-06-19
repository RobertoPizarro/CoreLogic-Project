/// Pantalla de Detalle de Presupuesto.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colores.dart';
import '../../../core/constants/app_estilos.dart';
import '../../../core/constants/app_rutas.dart';
import '../../../core/utils/formato_fecha.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import '../../../shared/widgets/iconos_categorias.dart';
import '../providers/presupuestos_provider.dart';

class DetallePresupuestoScreen extends ConsumerStatefulWidget {
  final String presupuestoId;
  const DetallePresupuestoScreen({super.key, required this.presupuestoId});
  @override
  ConsumerState<DetallePresupuestoScreen> createState() =>
      _DetallePresupuestoScreenState();
}

class _DetallePresupuestoScreenState
    extends ConsumerState<DetallePresupuestoScreen> {
  Map<String, dynamic>? _p;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final repo = ref.read(presupuestosRepositoryProvider);
      final datos = await repo.obtenerPresupuesto(widget.presupuestoId);
      setState(() {
        _p = datos;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _eliminar() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppEstilos.radioModal),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, false),
                  child: const Icon(Icons.close),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColores.gastoSuave,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColores.gasto,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '¿Eliminar este presupuesto?',
                style: AppEstilos.textoSubtitulo,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Esta acción no se puede deshacer.',
                style: AppEstilos.textoSecundario,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
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
                  child: Text('Eliminar', style: AppEstilos.textoBoton),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColores.borde),
                    backgroundColor: AppColores.superficie,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppEstilos.radioBoton,
                      ),
                    ),
                  ),
                  child: Text('Cancelar', style: AppEstilos.textoCuerpoMedio),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) {
      try {
        final repo = ref.read(presupuestosRepositoryProvider);
        await repo.eliminarPresupuesto(widget.presupuestoId);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Error al eliminar.')));
      }
    }
  }

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
          'Detalle del presupuesto',
          style: AppEstilos.textoTituloPantalla.copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: _cargando
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: SkeletonLoading(height: 300, borderRadius: 16),
            )
          : _p == null
          ? const Center(child: Text('No se encontró.'))
          : _buildDetalle(),
    );
  }

  Widget _buildDetalle() {
    final monto = (_p!['amount'] as num).toDouble();
    final consumido = (_p!['consumed'] as num).toDouble();
    final restante = (_p!['remaining'] as num).toDouble();
    final porcentaje = (_p!['percentage_used'] as num).toDouble();
    final excedido = consumido > monto;
    final estado = _p!['status'] as String;

    // Colores dinámicos
    final colorActivo = excedido ? AppColores.gasto : AppColores.primario;
    final colorSuave = excedido
        ? AppColores.gastoSuave
        : AppColores.primarioSuave;
    final colorBarra = excedido
        ? AppColores.gasto
        : estado == 'vencido'
        ? AppColores.vencido
        : AppColores.primario;

    // Badge: estado real, color rojo si excedido
    Color colorBadge;
    if (excedido) {
      colorBadge = AppColores.gasto;
    } else if (estado == 'vencido' || estado == 'proximo') {
      colorBadge = AppColores.vencido;
    } else {
      colorBadge = AppColores.primario;
    }
    final badgeTexto = estado == 'activo'
        ? 'Activo'
        : estado == 'proximo'
        ? 'Próximo'
        : 'Vencido';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppEstilos.paddingPantalla),
            child: Column(
              children: [
                // Card 1: Ícono + nombre + categoría + badge
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColores.superficie,
                    borderRadius: BorderRadius.circular(AppEstilos.radioCard),
                    boxShadow: [AppEstilos.sombraCard],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorSuave,
                          borderRadius: BorderRadius.circular(
                            AppEstilos.radioIconoCategoria,
                          ),
                        ),
                        child: Icon(
                          IconosCategorias.obtenerIcono(_p!['icon'] ?? ''),
                          color: colorActivo,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _p!['description'] ?? '',
                              style: AppEstilos.textoCuerpoMedio,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _p!['category'] ?? '',
                              style: AppEstilos.textoSecundario,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorBadge,
                          borderRadius: BorderRadius.circular(
                            AppEstilos.radioBadge,
                          ),
                        ),
                        child: Text(badgeTexto, style: AppEstilos.textoBadge),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Card 2: Monto objetivo + barra de progreso + restante/usado
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColores.superficie,
                    borderRadius: BorderRadius.circular(AppEstilos.radioCard),
                    boxShadow: [AppEstilos.sombraCard],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monto Objetivo', style: AppEstilos.textoSecundario),
                      const SizedBox(height: 4),
                      Text(
                        'S/.  ${monto.toStringAsFixed(2)}',
                        style: AppEstilos.textoTituloCard,
                      ),
                      const SizedBox(height: 16),
                      // Barra de progreso
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (porcentaje / 100).clamp(0.0, 1.0),
                          backgroundColor: AppColores.borde,
                          color: colorBarra,
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Restante y Usado
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColores.fondo,
                                borderRadius: BorderRadius.circular(
                                  AppEstilos.radioInput,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Restante',
                                    style: AppEstilos.textoSecundario.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'S/. ${restante.toStringAsFixed(2)}',
                                    style: AppEstilos.textoCuerpoMedio.copyWith(
                                      color: excedido
                                          ? AppColores.gasto
                                          : AppColores.primario,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColores.fondo,
                                borderRadius: BorderRadius.circular(
                                  AppEstilos.radioInput,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Usado',
                                    style: AppEstilos.textoSecundario.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${porcentaje.toStringAsFixed(0)}%',
                                    style: AppEstilos.textoCuerpoMedio,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Card 3: Fechas inicio y fin
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColores.superficie,
                    borderRadius: BorderRadius.circular(AppEstilos.radioCard),
                    boxShadow: [AppEstilos.sombraCard],
                  ),
                  child: Column(
                    children: [
                      _filaFecha(
                        Icons.calendar_today,
                        'Inicio',
                        FormatoFecha.formatearCorta(_p!['start_date']),
                        colorActivo,
                      ),
                      const Divider(color: AppColores.borde, height: 24),
                      _filaFecha(
                        Icons.calendar_today,
                        'Fin',
                        FormatoFecha.formatearCorta(_p!['end_date']),
                        colorActivo,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Botones fijos en la parte inferior
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppEstilos.paddingPantalla,
            12,
            AppEstilos.paddingPantalla,
            24,
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _eliminar,
                    icon: const Icon(Icons.close, size: 18),
                    label: Text('Eliminar', style: AppEstilos.textoBoton),
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
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final r = await Navigator.pushNamed(
                        context,
                        AppRutas.editarPresupuesto,
                        arguments: _p,
                      );
                      if (r == true) _cargar();
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text('Editar', style: AppEstilos.textoBoton),
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filaFecha(IconData icono, String label, String valor, Color color) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icono, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppEstilos.textoSecundario.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(valor, style: AppEstilos.textoCuerpoMedio),
            ],
          ),
        ),
      ],
    );
  }
}
