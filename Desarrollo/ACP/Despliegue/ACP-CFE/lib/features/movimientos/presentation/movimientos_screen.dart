import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colores.dart';
import '../../../core/constants/app_estilos.dart';
import '../../../core/constants/app_rutas.dart';
import '../../../core/utils/formato_moneda.dart';
import '../../../core/utils/formato_fecha.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import '../../../shared/widgets/iconos_categorias.dart';
import '../../../shared/widgets/boton_notificacion.dart';
import '../providers/movimientos_provider.dart';

class MovimientosScreen extends ConsumerStatefulWidget {
  const MovimientosScreen({super.key});
  @override
  ConsumerState<MovimientosScreen> createState() => MovimientosScreenState();
}

class MovimientosScreenState extends ConsumerState<MovimientosScreen> {
  final _busquedaController = TextEditingController();
  String? _filtroTipo;
  List<dynamic> _movimientos = [];
  bool _cargando = true;
  bool _cargandoMas = false;
  bool _hayMas = true;
  int _offset = 0;
  final int _limit = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cargarMovimientos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _cargarMas();
    }
  }

  /// Método para recargar desde navegador_principal al cambiar de tab
  void recargar() => _cargarMovimientos();

  List<_ElementoLista> _agruparMovimientos(List<dynamic> lista) {
    if (lista.isEmpty) return [];
    final List<_ElementoLista> resultado = [];
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    String? ultimaCabecera;

    for (final m in lista) {
      if (m['date'] == null) continue;
      final parts = m['date'].toString().split('-');
      final fechaMovNormalizada = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final diferenciaDias = hoy.difference(fechaMovNormalizada).inDays;

      String cabeceraActual;
      if (diferenciaDias == 0) {
        cabeceraActual = 'Hoy';
      } else if (diferenciaDias == 1) {
        cabeceraActual = 'Ayer';
      } else if (diferenciaDias >= 2 && diferenciaDias <= 7) {
        cabeceraActual = 'Esta semana';
      } else if (diferenciaDias >= 8 && diferenciaDias <= 14) {
        cabeceraActual = 'Hace 1 semana';
      } else if (fechaMovNormalizada.year == hoy.year &&
          fechaMovNormalizada.month == hoy.month) {
        cabeceraActual = 'Este mes';
      } else {
        final mesPasado = hoy.month == 1 ? 12 : hoy.month - 1;
        final anioMesPasado = hoy.month == 1 ? hoy.year - 1 : hoy.year;
        if (fechaMovNormalizada.year == anioMesPasado &&
            fechaMovNormalizada.month == mesPasado) {
          cabeceraActual = 'El mes pasado';
        } else {
          cabeceraActual = 'Más antiguo';
        }
      }

      if (ultimaCabecera != cabeceraActual) {
        ultimaCabecera = cabeceraActual;
        resultado.add(_ElementoLista(cabecera: cabeceraActual));
      }
      resultado.add(_ElementoLista(movimiento: m));
    }
    return resultado;
  }

  Widget _cabeceraSeccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
      child: Text(
        titulo,
        style: AppEstilos.textoSecundario.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColores.textoSecundario,
        ),
      ),
    );
  }

  Future<void> _cargarMovimientos() async {
    setState(() {
      _cargando = _movimientos.isEmpty;
      _offset = 0;
      _hayMas = true;
    });
    try {
      final repo = ref.read(movimientosRepositoryProvider);
      final datos = await repo.listarMovimientos(
        tipo: _filtroTipo,
        busqueda: _busquedaController.text.trim().isEmpty
            ? null
            : _busquedaController.text.trim(),
        limit: _limit,
        offset: 0,
      );
      setState(() {
        _movimientos = datos;
        _cargando = false;
        _offset = datos.length;
        _hayMas = datos.length >= _limit;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _cargarMas() async {
    if (_cargandoMas || !_hayMas) return;
    setState(() => _cargandoMas = true);
    try {
      final repo = ref.read(movimientosRepositoryProvider);
      final datos = await repo.listarMovimientos(
        tipo: _filtroTipo,
        busqueda: _busquedaController.text.trim().isEmpty
            ? null
            : _busquedaController.text.trim(),
        limit: _limit,
        offset: _offset,
      );
      setState(() {
        _movimientos.addAll(datos);
        _offset += datos.length;
        _hayMas = datos.length >= _limit;
        _cargandoMas = false;
      });
    } catch (e) {
      setState(() => _cargandoMas = false);
    }
  }

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
                  Text('Movimientos', style: AppEstilos.textoTituloPantalla),
                  const BotonNotificacion(),
                ],
              ),
              const SizedBox(height: 16),
              // Búsqueda
              TextField(
                controller: _busquedaController,
                onSubmitted: (_) => _cargarMovimientos(),
                decoration: InputDecoration(
                  hintText: 'Buscar movimiento...',
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
                            _cargarMovimientos();
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
              const SizedBox(height: 12),
              // Chips de filtro
              Row(
                children: [
                  _chip('Todos', _filtroTipo == null, () {
                    setState(() => _filtroTipo = null);
                    _cargarMovimientos();
                  }),
                  const SizedBox(width: 8),
                  _chip('Ingresos', _filtroTipo == 'income', () {
                    setState(() => _filtroTipo = 'income');
                    _cargarMovimientos();
                  }),
                  const SizedBox(width: 8),
                  _chip('Gastos', _filtroTipo == 'expense', () {
                    setState(() => _filtroTipo = 'expense');
                    _cargarMovimientos();
                  }),
                ],
              ),
              const SizedBox(height: 12),
              // Lista
              Expanded(
                child: _cargando
                    ? ListView(
                        children: List.generate(
                          6,
                          (_) => const SkeletonListItem(),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColores.primario,
                        onRefresh: () async => _cargarMovimientos(),
                        child: _movimientos.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.25,
                                  ),
                                  Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.receipt_long_outlined,
                                          size: 64,
                                          color: AppColores.textoSecundario,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No se encontraron movimientos',
                                          style: AppEstilos.textoCuerpoMedio,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : () {
                                final elementos = _agruparMovimientos(
                                  _movimientos,
                                );
                                return ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  controller: _scrollController,
                                  itemCount:
                                      elementos.length + (_cargandoMas ? 1 : 0),
                                  itemBuilder: (context, i) {
                                    if (i == elementos.length)
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: CircularProgressIndicator(
                                            color: AppColores.primario,
                                          ),
                                        ),
                                      );
                                    final el = elementos[i];
                                    if (el.cabecera != null) {
                                      return _cabeceraSeccion(el.cabecera!);
                                    }
                                    return _itemMov(el.movimiento);
                                  },
                                );
                              }(),
                      ),
              ),
            ],
          ),
        ),
      ),

      //Botón para acceder a reportes
      floatingActionButton: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, AppRutas.reportes);
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
              const Icon(
                Icons.history_toggle_off,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('Ver Resumen', style: AppEstilos.textoBoton),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String t, bool a, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: a ? AppColores.primario : AppColores.superficie,
        borderRadius: BorderRadius.circular(20),
        border: a ? null : Border.all(color: AppColores.borde),
      ),
      child: Text(
        t,
        style: AppEstilos.textoSecundario.copyWith(
          color: a ? Colors.white : AppColores.textoSecundario,
          fontWeight: a ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    ),
  );

  Widget _itemMov(dynamic m) {
    final esI = m['type'] == 'income';
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(
          context,
          AppRutas.detalleMovimiento,
          arguments: {'id': m['id']},
        );
        _cargarMovimientos();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: AppEstilos.espacioEntreCards),
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
                color: esI ? AppColores.primarioSuave : AppColores.gastoSuave,
                borderRadius: BorderRadius.circular(
                  AppEstilos.radioIconoCategoria,
                ),
              ),
              child: Icon(
                IconosCategorias.obtenerIcono(m['icon'] ?? ''),
                color: esI ? AppColores.primario : AppColores.gasto,
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
                    FormatoFecha.formatearCorta(m['date']),
                    style: AppEstilos.textoSecundario,
                  ),
                ],
              ),
            ),
            Text(
              FormatoMoneda.formatearConSigno(
                (m['amount'] as num).toDouble(),
                m['type'],
              ),
              style: AppEstilos.textoCuerpoMedio.copyWith(
                color: esI ? AppColores.ingreso : AppColores.gasto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ElementoLista {
  final String? cabecera;
  final dynamic movimiento;
  _ElementoLista({this.cabecera, this.movimiento});
}
