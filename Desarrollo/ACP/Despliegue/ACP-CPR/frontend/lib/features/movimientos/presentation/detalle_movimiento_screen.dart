/// Pantalla de Detalle de Movimiento.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colores.dart';
import '../../../core/constants/app_estilos.dart';
import '../../../core/constants/app_rutas.dart';
import '../../../core/utils/formato_fecha.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import '../../../shared/widgets/iconos_categorias.dart';
import '../providers/movimientos_provider.dart';

class DetalleMovimientoScreen extends ConsumerStatefulWidget {
  final String movimientoId;
  const DetalleMovimientoScreen({super.key, required this.movimientoId});
  @override
  ConsumerState<DetalleMovimientoScreen> createState() =>
      _DetalleMovimientoScreenState();
}

class _DetalleMovimientoScreenState
    extends ConsumerState<DetalleMovimientoScreen> {
  Map<String, dynamic>? _movimiento;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final repo = ref.read(movimientosRepositoryProvider);
      final datos = await repo.obtenerMovimiento(widget.movimientoId);
      setState(() {
        _movimiento = datos;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _eliminar() async {
    final confirmar = await showDialog<bool>(
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
                '¿Eliminar este movimiento?',
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
    if (confirmar == true) {
      try {
        final repo = ref.read(movimientosRepositoryProvider);
        await repo.eliminarMovimiento(widget.movimientoId);
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
          'Detalle del movimiento',
          style: AppEstilos.textoTituloPantalla.copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: _cargando
          ? Padding(
              padding: const EdgeInsets.all(AppEstilos.paddingPantalla),
              child: Column(
                children: [
                  const SkeletonLoading(height: 200, borderRadius: 16),
                ],
              ),
            )
          : _movimiento == null
          ? const Center(child: Text('No se encontró el movimiento.'))
          : _buildDetalle(),
    );
  }

  Widget _buildDetalle() {
    final m = _movimiento!;
    final esIngreso = m['type'] == 'income';
    final colorActivo = esIngreso ? AppColores.primario : AppColores.gasto;
    final colorSuave = esIngreso
        ? AppColores.primarioSuave
        : AppColores.gastoSuave;
    final metodo = m['payment_method'] == 'efectivo'
        ? 'Efectivo'
        : m['payment_method'] == 'tarjeta'
        ? 'Tarjeta'
        : 'Transferencia';
    final monto = (m['amount'] as num).toDouble();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppEstilos.paddingPantalla),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Monto grande
                Text('Monto (S/.)', style: AppEstilos.textoSecundario),
                const SizedBox(height: 4),
                Text(
                  _formatearMonto(monto),
                  style: AppEstilos.textoDisplay.copyWith(
                    color: colorActivo,
                    fontSize: 40,
                  ),
                ),
                const SizedBox(height: 20),

                // Card con ícono + descripción + categoría
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
                          IconosCategorias.obtenerIcono(m['icon'] ?? ''),
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
                              m['description'] ?? m['category'] ?? '',
                              style: AppEstilos.textoCuerpoMedio,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m['category'] ?? '',
                              style: AppEstilos.textoSecundario,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Card con detalles: categoría, fecha, método de pago
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
                      _filaDetalle(
                        Icons.label_outline,
                        'Categoría',
                        m['category'] ?? '-',
                        colorActivo,
                      ),
                      const Divider(color: AppColores.borde, height: 24),
                      _filaDetalle(
                        Icons.calendar_today,
                        'Fecha',
                        FormatoFecha.formatearCorta(m['date']),
                        colorActivo,
                      ),
                      const Divider(color: AppColores.borde, height: 24),
                      _filaDetalle(
                        Icons.credit_card,
                        'Método de pago',
                        metodo,
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
                      final resultado = await Navigator.pushNamed(
                        context,
                        AppRutas.editarMovimiento,
                        arguments: m,
                      );
                      if (resultado == true) _cargar();
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

  Widget _filaDetalle(IconData icono, String label, String valor, Color color) {
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

  String _formatearMonto(double monto) {
    final partes = monto.toStringAsFixed(2).split('.');
    final entero = partes[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$entero.${partes[1]}';
  }
}
