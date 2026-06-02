import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/constants/app_colores.dart';
import '../../../core/constants/app_estilos.dart';
import '../../../core/utils/formato_moneda.dart';
import '../../../core/utils/formato_fecha.dart';
import '../../../shared/widgets/iconos_categorias.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import '../providers/reportes_provider.dart';

class ReportesScreen extends ConsumerStatefulWidget {
  const ReportesScreen({super.key});

  @override
  ConsumerState<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends ConsumerState<ReportesScreen> {
  String _vista = 'mensual'; // 'diaria', 'semanal', 'mensual'
  DateTime _fechaSeleccionada = DateTime.now();
  String _tipoDistribucion = 'expense'; // 'expense', 'income'

  Future<Map<String, dynamic>>? _futuroResumen;
  Future<Map<String, dynamic>>? _futuroDistribucion;

  final List<Color> _chartColors = [
    const Color(0xFF1A7A7A), // Primario
    const Color(0xFF7B68EE), // Medium Slate Blue
    const Color(0xFFFFA726), // Orange
    const Color(0xFF26A69A), // Teal Accent
    const Color(0xFFEC407A), // Pink Accent
    const Color(0xFFAB47BC), // Purple Accent
    const Color(0xFF42A5F5), // Light Blue
    const Color(0xFF26C6DA), // Cyan Accent
    const Color(0xFF8D6E63), // Brown
    const Color(0xFF78909C), // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() {
    final repo = ref.read(reportesRepositoryProvider);
    final mesStr =
        '${_fechaSeleccionada.year}-${_fechaSeleccionada.month.toString().padLeft(2, '0')}';
    final anioInt = _fechaSeleccionada.year;

    setState(() {
      _futuroResumen = repo.obtenerResumen(
        vista: _vista,
        mes: _vista == 'mensual' ? null : mesStr,
        anio: _vista == 'mensual' ? anioInt : null,
      );

      _futuroDistribucion = repo.obtenerDistribucionCategorias(
        vista: _vista,
        tipo: _tipoDistribucion,
        mes: _vista == 'mensual' ? null : mesStr,
        anio: _vista == 'mensual' ? anioInt : null,
      );
    });
  }

  String _obtenerLabelFecha() {
    if (_vista == 'mensual') {
      return '${_fechaSeleccionada.year}';
    } else {
      final mesesEsp = [
        '',
        'Enero',
        'Febrero',
        'Marzo',
        'Abril',
        'Mayo',
        'Junio',
        'Julio',
        'Agosto',
        'Septiembre',
        'Octubre',
        'Noviembre',
        'Diciembre',
      ];
      return '${mesesEsp[_fechaSeleccionada.month]} ${_fechaSeleccionada.year}';
    }
  }

  String _formatearRango(String desde, String hasta) {
    if (desde == hasta) {
      return FormatoFecha.formatearLarga(desde);
    } else {
      return '${FormatoFecha.formatearCorta(desde)} - ${FormatoFecha.formatearCorta(hasta)}';
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
          'Resumen',
          style: AppEstilos.textoTituloPantalla.copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppEstilos.paddingPantalla,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Selector de Vista
              Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColores.borde,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    _buildVistaTab('diaria', 'Diaria'),
                    _buildVistaTab('semanal', 'Semanal'),
                    _buildVistaTab('mensual', 'Mensual'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Navegación temporal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: AppColores.primario,
                      size: 28,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_vista == 'mensual') {
                          _fechaSeleccionada = DateTime(
                            _fechaSeleccionada.year - 1,
                            _fechaSeleccionada.month,
                          );
                        } else {
                          _fechaSeleccionada = DateTime(
                            _fechaSeleccionada.year,
                            _fechaSeleccionada.month - 1,
                          );
                        }
                        _cargarDatos();
                      });
                    },
                  ),
                  Text(
                    _obtenerLabelFecha(),
                    style: AppEstilos.textoSubtitulo.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_right,
                      color: AppColores.primario,
                      size: 28,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_vista == 'mensual') {
                          _fechaSeleccionada = DateTime(
                            _fechaSeleccionada.year + 1,
                            _fechaSeleccionada.month,
                          );
                        } else {
                          _fechaSeleccionada = DateTime(
                            _fechaSeleccionada.year,
                            _fechaSeleccionada.month + 1,
                          );
                        }
                        _cargarDatos();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Contenido Principal (Resumen y Lista de Periodos)
              FutureBuilder<Map<String, dynamic>>(
                future: _futuroResumen,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildResumenSkeleton();
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState('Error al cargar el resumen.');
                  }

                  final data = snapshot.data;
                  if (data == null ||
                      data['periodos'] == null ||
                      (data['periodos'] as List).isEmpty) {
                    return _buildEmptyState(
                      'No hay movimientos en este período.',
                      '¡Ingresa un movimiento para ver tus reportes!',
                    );
                  }

                  final periodos = data['periodos'] as List<dynamic>;

                  // Calcular totales generales para la Card de Resumen General
                  double totalIngresos = 0;
                  double totalGastos = 0;
                  for (final p in periodos) {
                    totalIngresos += (p['total_ingresos'] as num).toDouble();
                    totalGastos += (p['total_gastos'] as num).toDouble();
                  }
                  final balanceGeneral = totalIngresos - totalGastos;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card de Resumen General
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColores.superficie,
                          borderRadius: BorderRadius.circular(
                            AppEstilos.radioCard,
                          ),
                          boxShadow: [AppEstilos.sombraCard],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Balance del Período',
                              style: AppEstilos.textoSecundario.copyWith(
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              FormatoMoneda.formatear(balanceGeneral),
                              style: AppEstilos.textoTituloCard.copyWith(
                                fontSize: 28,
                                color: balanceGeneral >= 0
                                    ? AppColores.ingreso
                                    : AppColores.gasto,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: AppColores.ingreso,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Ingresos',
                                            style: AppEstilos.textoSecundario
                                                .copyWith(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        FormatoMoneda.formatear(totalIngresos),
                                        style: AppEstilos.textoCuerpoMedio
                                            .copyWith(
                                              color: AppColores.ingreso,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 36,
                                  color: AppColores.borde,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: AppColores.gasto,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Gastos',
                                            style: AppEstilos.textoSecundario
                                                .copyWith(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        FormatoMoneda.formatear(totalGastos),
                                        style: AppEstilos.textoCuerpoMedio
                                            .copyWith(
                                              color: AppColores.gasto,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppEstilos.espacioEntreSecciones),

                      // Lista de Períodos Agrupados
                      Text(
                        'Desglose del Período',
                        style: AppEstilos.textoSubtitulo,
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: periodos.length,
                        itemBuilder: (context, i) {
                          final p = periodos[i];
                          final balance = (p['balance'] as num).toDouble();
                          final totalIng = (p['total_ingresos'] as num)
                              .toDouble();
                          final totalGas = (p['total_gastos'] as num)
                              .toDouble();

                          return Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(
                              bottom: AppEstilos.espacioEntreCards,
                            ),
                            decoration: BoxDecoration(
                              color: AppColores.superficie,
                              borderRadius: BorderRadius.circular(
                                AppEstilos.radioCard,
                              ),
                              boxShadow: [AppEstilos.sombraCard],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p['label'],
                                        style: AppEstilos.textoCuerpoMedio
                                            .copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatearRango(
                                          p['rango_fechas']['desde'],
                                          p['rango_fechas']['hasta'],
                                        ),
                                        style: AppEstilos.textoSecundario
                                            .copyWith(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      FormatoMoneda.formatear(balance),
                                      style: AppEstilos.textoCuerpoMedio
                                          .copyWith(
                                            color: balance >= 0
                                                ? AppColores.ingreso
                                                : AppColores.gasto,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          '+${FormatoMoneda.formatear(totalIng)}',
                                          style: AppEstilos.textoLabel.copyWith(
                                            color: AppColores.ingreso,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '-${FormatoMoneda.formatear(totalGas)}',
                                          style: AppEstilos.textoLabel.copyWith(
                                            color: AppColores.gasto,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppEstilos.espacioEntreSecciones),
                    ],
                  );
                },
              ),

              // Sección de Distribución por Categoría — título y chips en la misma fila
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Distribución', style: AppEstilos.textoSubtitulo),
                  Row(
                    children: [
                      _buildTipoChip('expense', 'Gastos'),
                      const SizedBox(width: 8),
                      _buildTipoChip('income', 'Ingresos'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Gráfico y Lista de Distribución
              FutureBuilder<Map<String, dynamic>>(
                future: _futuroDistribucion,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildDistribucionSkeleton();
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState('Error al cargar la distribución.');
                  }

                  final data = snapshot.data;
                  if (data == null ||
                      data['categorias'] == null ||
                      (data['categorias'] as List).isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          '¡Ingresa un movimiento para ver tus reportes!',
                          style: AppEstilos.textoSecundario,
                        ),
                      ),
                    );
                  }

                  final categorias = data['categorias'] as List<dynamic>;

                  return Column(
                    children: [
                      // Leyenda dinámica: layout según cantidad de categorías
                      if (categorias.length <= 4)
                        // <= 4 categorías: donut a la izquierda + leyenda a la derecha, centrado
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Donut
                              SizedBox(
                                width: 110,
                                height: 110,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 28,
                                    sections: _generarSecciones(categorias),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 50),
                              // Leyenda
                              IntrinsicWidth(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(categorias.length, (
                                    i,
                                  ) {
                                    final cat = categorias[i];
                                    final color =
                                        _chartColors[i % _chartColors.length];
                                    final pct = (cat['percentage'] as num)
                                        .toDouble();
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: color,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              cat['name'],
                                              style: AppEstilos.textoSecundario
                                                  .copyWith(fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '${pct.toStringAsFixed(0)}%',
                                            style: AppEstilos.textoCuerpoMedio
                                                .copyWith(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        // >= 5 categorías: donut centrado arriba + leyenda en Wrap abajo
                        Column(
                          children: [
                            Container(
                              height: 130,
                              width: 130,
                              margin: const EdgeInsets.symmetric(vertical: 16),
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 32,
                                  sections: _generarSecciones(categorias),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: 7,
                              crossAxisSpacing: 12,
                              children: List.generate(categorias.length, (i) {
                                final cat = categorias[i];
                                final color =
                                    _chartColors[i % _chartColors.length];
                                final pct = (cat['percentage'] as num)
                                    .toDouble();
                                return Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        cat['name'],
                                        style: AppEstilos.textoSecundario
                                            .copyWith(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${pct.toStringAsFixed(0)}%',
                                      style: AppEstilos.textoCuerpoMedio
                                          .copyWith(fontSize: 12),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // Lista Detallada de Categorías
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categorias.length,
                        itemBuilder: (context, i) {
                          final cat = categorias[i];
                          final color = _chartColors[i % _chartColors.length];
                          final amount = (cat['amount'] as num).toDouble();
                          final pct = (cat['percentage'] as num).toDouble();

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 14,
                            ),
                            margin: const EdgeInsets.only(
                              bottom: AppEstilos.espacioEntreCards,
                            ),
                            decoration: BoxDecoration(
                              color: AppColores.superficie,
                              borderRadius: BorderRadius.circular(
                                AppEstilos.radioCard,
                              ),
                              boxShadow: [AppEstilos.sombraCard],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: color.withAlpha(30),
                                        borderRadius: BorderRadius.circular(
                                          AppEstilos.radioIconoCategoria,
                                        ),
                                      ),
                                      child: Icon(
                                        IconosCategorias.obtenerIcono(
                                          cat['icon'] ?? '',
                                        ),
                                        color: color,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cat['name'],
                                            style: AppEstilos.textoCuerpoMedio
                                                .copyWith(fontSize: 14),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${pct.toStringAsFixed(1)}% del total',
                                            style: AppEstilos.textoSecundario
                                                .copyWith(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      FormatoMoneda.formatear(amount),
                                      style: AppEstilos.textoCuerpoMedio
                                          .copyWith(
                                            color: AppColores.textoTitulo,
                                            fontSize: 14,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct / 100,
                                    backgroundColor: AppColores.borde,
                                    color: color,
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVistaTab(String vistaKey, String label) {
    final select = _vista == vistaKey;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_vista != vistaKey) {
            setState(() {
              _vista = vistaKey;
              _cargarDatos();
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: select ? AppColores.primario : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: AppEstilos.textoSecundario.copyWith(
              color: select ? Colors.white : AppColores.textoSecundario,
              fontWeight: select ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipoChip(String type, String label) {
    final selected = _tipoDistribucion == type;
    return ChoiceChip(
      showCheckmark: false,
      label: Text(label),
      selected: selected,
      selectedColor: AppColores.primario,
      backgroundColor: Colors.transparent,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColores.textoSecundario,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? Colors.transparent : AppColores.borde,
        ),
      ),
      onSelected: (val) {
        if (val) {
          setState(() {
            _tipoDistribucion = type;
            _cargarDatos();
          });
        }
      },
    );
  }

  List<PieChartSectionData> _generarSecciones(List<dynamic> categorias) {
    return List.generate(categorias.length, (i) {
      final cat = categorias[i];
      final color = _chartColors[i % _chartColors.length];
      final pct = (cat['percentage'] as num).toDouble();

      return PieChartSectionData(
        color: color,
        value: pct,
        title: '',
        radius: 40,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildResumenSkeleton() {
    return Column(
      children: [
        const SkeletonLoading(height: 160, borderRadius: 16),
        const SizedBox(height: 24),
        ...List.generate(3, (_) => const SkeletonListItem()),
      ],
    );
  }

  Widget _buildDistribucionSkeleton() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Center(
          child: SkeletonLoading(width: 140, height: 140, borderRadius: 70),
        ),
        const SizedBox(height: 24),
        ...List.generate(3, (_) => const SkeletonListItem()),
      ],
    );
  }

  Widget _buildEmptyState(String titulo, String subtitulo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(AppEstilos.radioCard),
        boxShadow: [AppEstilos.sombraCard],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.analytics_outlined,
            size: 60,
            color: AppColores.textoSecundario,
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            style: AppEstilos.textoCuerpoMedio,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitulo,
            style: AppEstilos.textoSecundario,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColores.gasto),
            const SizedBox(height: 8),
            Text(mensaje, style: AppEstilos.textoSecundario),
          ],
        ),
      ),
    );
  }
}
