/// Pantalla de Detalle de Gasto Compartido.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colores.dart';
import '../../../core/constants/app_estilos.dart';
import '../../../core/constants/app_rutas.dart';
import '../../../core/utils/formato_fecha.dart';
import '../providers/grupos_provider.dart';

class DetalleGastoCompartidoScreen extends ConsumerStatefulWidget {
  final String grupoId;
  final String gastoId;
  final List<dynamic> miembros;
  const DetalleGastoCompartidoScreen({
    super.key,
    required this.grupoId,
    required this.gastoId,
    required this.miembros,
  });

  @override
  ConsumerState<DetalleGastoCompartidoScreen> createState() =>
      _DetalleGastoCompartidoScreenState();
}

class _DetalleGastoCompartidoScreenState
    extends ConsumerState<DetalleGastoCompartidoScreen> {
  Map<String, dynamic>? _gasto;
  bool _cargando = true;
  bool _datoCambiado = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final repo = ref.read(gruposRepositoryProvider);
      final gasto = await repo.obtenerGasto(widget.grupoId, widget.gastoId);
      if (mounted)
        setState(() {
          _gasto = gasto;
          _cargando = false;
        });
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _eliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (c) => Dialog(
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
                  onTap: () => Navigator.pop(c, false),
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
                '¿Eliminar este gasto?',
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
                  onPressed: () => Navigator.pop(c, true),
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
                  onPressed: () => Navigator.pop(c, false),
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
    if (confirmar != true) return;
    try {
      final repo = ref.read(gruposRepositoryProvider);
      await repo.eliminarGasto(widget.grupoId, widget.gastoId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al eliminar.')));
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
            onTap: () => Navigator.pop(context, _datoCambiado),
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
          'Detalle de gasto',
          style: AppEstilos.textoTituloPantalla.copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) Navigator.pop(context, _datoCambiado);
        },
        child: _cargando
            ? _buildSkeleton()
            : _gasto == null
            ? const Center(child: Text('No se encontró el gasto.'))
            : _buildDetalle(),
      ),
    );
  }

  Widget _buildDetalle() {
    final g = _gasto!;
    final monto = (g['total_amount'] as num).toDouble();
    final paidBy = g['paid_by'] as Map<String, dynamic>? ?? {};
    final splits = g['splits'] as List<dynamic>? ?? [];
    final splitType = g['split_type'] ?? 'igual';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppEstilos.paddingPantalla),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Monto grande centrado con label
                Center(
                  child: Column(
                    children: [
                      Text('Monto (S/.)', style: AppEstilos.textoSecundario),
                      const SizedBox(height: 4),
                      Text(
                        monto.toStringAsFixed(2),
                        style: AppEstilos.textoDisplay.copyWith(
                          fontSize: 40,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Info agrupada en un contenedor
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColores.superficie,
                    borderRadius: BorderRadius.circular(AppEstilos.radioCard),
                    border: Border.all(color: AppColores.borde),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        'Fecha',
                        FormatoFecha.formatearCorta(g['date']),
                      ),
                      Divider(height: 1, color: AppColores.borde),
                      _buildInfoRow('Descripción', g['description'] ?? ''),
                      Divider(height: 1, color: AppColores.borde),
                      _buildInfoRow('Pagado por', paidBy['name'] ?? ''),
                      Divider(height: 1, color: AppColores.borde),
                      _buildInfoRow(
                        'Tipo de división',
                        _labelDivision(splitType),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // División del gasto
                Text('División del gasto', style: AppEstilos.textoSubtitulo),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColores.superficie,
                    borderRadius: BorderRadius.circular(AppEstilos.radioCard),
                    boxShadow: [AppEstilos.sombraCard],
                  ),
                  child: Column(
                    children: splits.asMap().entries.map((e) {
                      final s = e.value;
                      final i = e.key;
                      final nombre = s['name'] ?? '';
                      final iniciales = nombre
                          .split(' ')
                          .take(2)
                          .map((p) => p.isNotEmpty ? p[0] : '')
                          .join()
                          .toUpperCase();
                      final color = AppColores.colorParaUsuario(
                        s['user_id'] as String? ?? '',
                      );
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: color,
                                  child: Text(
                                    iniciales,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    nombre,
                                    style: AppEstilos.textoCuerpoMedio,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  'S/. ${(s['amount_owed'] as num).toStringAsFixed(2)}',
                                  style: AppEstilos.textoSecundario.copyWith(
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (i < splits.length - 1)
                            Divider(
                              height: 1,
                              color: AppColores.borde,
                              indent: 14,
                              endIndent: 14,
                            ),
                        ],
                      );
                    }).toList(),
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
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final resultado = await Navigator.pushNamed(
                        context,
                        AppRutas.editarGastoCompartido,
                        arguments: {
                          'group_id': widget.grupoId,
                          'gasto': _gasto,
                          'members': widget.miembros,
                        },
                      );
                      if (resultado == true) {
                        _datoCambiado = true;
                        _cargar();
                      }
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

  Widget _buildInfoRow(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppEstilos.textoSecundario),
          ),
          Expanded(
            child: Text(
              valor,
              style: AppEstilos.textoCuerpoMedio,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _labelDivision(String tipo) {
    switch (tipo) {
      case 'igual':
        return 'Igual';
      case 'porcentaje':
        return 'Por porcentaje';
      case 'personalizado':
        return 'Personalizado';
      default:
        return tipo;
    }
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColores.skeletonBase,
      highlightColor: AppColores.skeletonHighlight,
      child: Padding(
        padding: const EdgeInsets.all(AppEstilos.paddingPantalla),
        child: Column(
          children: [
            Container(
              height: 60,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
