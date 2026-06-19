/// Pantalla de Detalle de Grupo.
/// Dos secciones: Gastos del grupo y Balances.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colores.dart';
import '../../../core/constants/app_estilos.dart';
import '../../../core/constants/app_rutas.dart';
import '../../../core/utils/formato_fecha.dart';
import '../providers/grupos_provider.dart';

class DetalleGrupoScreen extends ConsumerStatefulWidget {
  final String grupoId;
  final String grupoNombre;
  const DetalleGrupoScreen({
    super.key,
    required this.grupoId,
    required this.grupoNombre,
  });

  @override
  ConsumerState<DetalleGrupoScreen> createState() => _DetalleGrupoScreenState();
}

class _DetalleGrupoScreenState extends ConsumerState<DetalleGrupoScreen> {
  int _seccion = 0; // 0 = Gastos, 1 = Balances
  Map<String, dynamic>? _datosGastos;
  Map<String, dynamic>? _datosBalances;
  bool _cargandoGastos = true;
  bool _cargandoBalances = false;
  bool _navegando = false;

  @override
  void initState() {
    super.initState();
    _cargarGastos();
  }

  Future<void> _cargarGastos() async {
    setState(() => _cargandoGastos = true);
    try {
      final repo = ref.read(gruposRepositoryProvider);
      final gastos = await repo.listarGastos(widget.grupoId);
      if (mounted)
        setState(() {
          _datosGastos = gastos;
          _cargandoGastos = false;
        });
    } catch (e) {
      if (mounted) setState(() => _cargandoGastos = false);
    }
  }

  Future<void> _cargarBalances() async {
    setState(() => _cargandoBalances = true);
    try {
      final repo = ref.read(gruposRepositoryProvider);
      final balances = await repo.obtenerBalances(widget.grupoId);
      if (mounted)
        setState(() {
          _datosBalances = balances;
          _cargandoBalances = false;
        });
    } catch (e) {
      if (mounted) setState(() => _cargandoBalances = false);
    }
  }

  Future<void> _recargarSeccionActual() async {
    if (_seccion == 0) {
      await _cargarGastos();
    } else {
      await _cargarBalances();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cargandoActual = _seccion == 0 ? _cargandoGastos : _cargandoBalances;
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
          widget.grupoNombre,
          style: AppEstilos.textoTituloPantalla.copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Toggle Gastos / Balances
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppEstilos.paddingPantalla,
                  vertical: 8,
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColores.fondo,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColores.borde),
                  ),
                  child: Row(
                    children: [
                      _buildToggle('Gastos', 0),
                      _buildToggle('Balances', 1),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: cargandoActual
                    ? _buildSkeleton()
                    : _seccion == 0
                    ? _buildGastos()
                    : _buildBalances(),
              ),
            ],
          ),
          // Botón para agregar nuevo gasto
          if (_seccion == 0)
            Positioned(right: 16, bottom: 16, child: _buildFAB()),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, int indice) {
    final activo = _seccion == indice;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _seccion = indice);
          if (indice == 1 && _datosBalances == null && !_cargandoBalances) {
            _cargarBalances();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: activo ? AppColores.primario : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: AppEstilos.textoCuerpoMedio.copyWith(
                color: activo ? Colors.white : AppColores.textoSecundario,
                fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: _navegando
          ? null
          : () async {
              setState(() => _navegando = true);
              try {
                if (_datosBalances == null) {
                  await _cargarBalances();
                }
                if (mounted) {
                  final miembros =
                      _datosBalances?['member_balances'] as List<dynamic>? ??
                      [];
                  final resultado = await Navigator.pushNamed(
                    context,
                    AppRutas.nuevoGastoCompartido,
                    arguments: {
                      'group_id': widget.grupoId,
                      'members': miembros,
                    },
                  );
                  if (resultado == true) {
                    _cargarGastos();
                    _cargarBalances();
                  }
                }
              } finally {
                if (mounted) setState(() => _navegando = false);
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: _navegando
              ? AppColores.primario.withOpacity(0.8)
              : AppColores.primario,
          borderRadius: BorderRadius.circular(AppEstilos.radioBoton),
          boxShadow: [AppEstilos.sombraFAB],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _navegando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Nuevo gasto', style: AppEstilos.textoBoton),
          ],
        ),
      ),
    );
  }

  // ─── Sección Gastos ───

  Widget _buildGastos() {
    final gastos = _datosGastos?['gastos'] as List<dynamic>? ?? [];
    if (gastos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColores.textoSecundario,
            ),
            const SizedBox(height: 16),
            Text('Sin gastos', style: AppEstilos.textoCuerpoMedio),
            const SizedBox(height: 8),
            Text(
              'Registra el primer gasto del grupo',
              style: AppEstilos.textoSecundario,
            ),
          ],
        ),
      );
    }
    final elementos = _agruparGastos(gastos);
    return RefreshIndicator(
      color: AppColores.primario,
      onRefresh: _recargarSeccionActual,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppEstilos.paddingPantalla),
        itemCount: elementos.length,
        itemBuilder: (context, i) {
          final el = elementos[i];
          if (el.cabecera != null) {
            return _cabeceraSeccion(el.cabecera!);
          }
          return _buildCardGasto(el.gasto, i);
        },
      ),
    );
  }

  Widget _buildCardGasto(Map<String, dynamic> gasto, int index) {
    final paidBy = gasto['paid_by'] as Map<String, dynamic>? ?? {};
    final nombre = paidBy['name'] ?? '';
    final iniciales = nombre
        .split(' ')
        .take(2)
        .map((p) => p.isNotEmpty ? p[0] : '')
        .join()
        .toUpperCase();
    final color = AppColores.colorParaUsuario(
      paidBy['user_id'] as String? ?? '',
    );

    return GestureDetector(
      onTap: _navegando
          ? null
          : () async {
              setState(() => _navegando = true);
              try {
                if (_datosBalances == null) {
                  await _cargarBalances();
                }
                if (mounted) {
                  final resultado = await Navigator.pushNamed(
                    context,
                    AppRutas.detalleGastoCompartido,
                    arguments: {
                      'group_id': widget.grupoId,
                      'gasto_id': gasto['id'],
                      'members': _datosBalances?['member_balances'] ?? [],
                    },
                  );
                  if (resultado == true) {
                    _cargarGastos();
                    _cargarBalances();
                  }
                }
              } finally {
                if (mounted) setState(() => _navegando = false);
              }
            },
      child: Container(
        padding: const EdgeInsets.all(AppEstilos.paddingCard),
        margin: const EdgeInsets.only(bottom: AppEstilos.espacioEntreCards),
        decoration: BoxDecoration(
          color: AppColores.superficie,
          borderRadius: BorderRadius.circular(AppEstilos.radioCard),
          boxShadow: [AppEstilos.sombraCard],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color,
              child: Text(
                iniciales,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gasto['description'] ?? '',
                    style: AppEstilos.textoCuerpoMedio,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    FormatoFecha.formatearCorta(gasto['date']),
                    style: AppEstilos.textoSecundario,
                  ),
                ],
              ),
            ),
            Text(
              'S/.  ${(gasto['total_amount'] as num).toStringAsFixed(2)}',
              style: AppEstilos.textoCuerpoMedio.copyWith(fontSize: 17),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Sección Balances ───

  Widget _buildBalances() {
    if (_datosBalances == null) return const SizedBox();
    final totalGrupo =
        (_datosBalances!['total_group'] as num?)?.toDouble() ?? 0;
    final memberBalances =
        _datosBalances!['member_balances'] as List<dynamic>? ?? [];
    final misDeudas = _datosBalances!['my_debts'] as List<dynamic>? ?? [];
    final meDeben = _datosBalances!['owed_to_me'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      color: AppColores.primario,
      onRefresh: _recargarSeccionActual,
      child: ListView(
        padding: const EdgeInsets.all(AppEstilos.paddingPantalla),
        children: [
          // Monto total grande
          Center(
            child: Column(
              children: [
                Text('Monto (S/.)', style: AppEstilos.textoSecundario),
                const SizedBox(height: 4),
                Text(
                  _formatearMontoGrande(totalGrupo),
                  style: AppEstilos.textoDisplay.copyWith(
                    fontSize: 40,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Balance por miembro
          Text('Balance por miembro', style: AppEstilos.textoSubtitulo),
          const SizedBox(height: 10),
          ...memberBalances.asMap().entries.map(
            (e) => _buildFilaMiembro(e.value, e.key),
          ),
          const SizedBox(height: 20),
          // Mis deudas
          Text('Mis deudas', style: AppEstilos.textoSubtitulo),
          const SizedBox(height: 10),
          if (misDeudas.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'No tienes deudas pendientes',
                style: AppEstilos.textoSecundario,
              ),
            ),
          ...misDeudas.asMap().entries.map(
            (e) => _buildFilaDeuda(e.value, e.key),
          ),
          const SizedBox(height: 20),
          // Mis deudores
          Text('Mis deudores', style: AppEstilos.textoSubtitulo),
          const SizedBox(height: 10),
          if (meDeben.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Nadie te debe nada',
                style: AppEstilos.textoSecundario,
              ),
            ),
          ...meDeben.asMap().entries.map(
            (e) => _buildFilaDeudor(e.value, e.key),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildFilaMiembro(Map<String, dynamic> m, int index) {
    final nombre = m['name'] ?? '';
    final iniciales = nombre
        .split(' ')
        .take(2)
        .map((p) => p.isNotEmpty ? p[0] : '')
        .join()
        .toUpperCase();
    final net = (m['net'] as num?)?.toDouble() ?? 0;
    final pagado = (m['paid'] as num?)?.toDouble() ?? 0;
    final color = AppColores.colorParaUsuario(m['user_id'] as String? ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColores.superficie,
          borderRadius: BorderRadius.circular(AppEstilos.radioCard),
          boxShadow: [AppEstilos.sombraCard],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color,
              child: Text(
                iniciales,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: AppEstilos.textoCuerpoMedio,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'S/.  ${pagado.toStringAsFixed(2)}',
                    style: AppEstilos.textoSecundario,
                  ),
                ],
              ),
            ),
            Text(
              net > 0
                  ? '+S/. ${net.toStringAsFixed(2)}'
                  : net < 0
                  ? '-S/. ${net.abs().toStringAsFixed(2)}'
                  : 'S/. 0.00',
              style: AppEstilos.textoCuerpoMedio.copyWith(
                color: net > 0
                    ? AppColores.primario
                    : net < 0
                    ? AppColores.gasto
                    : AppColores.textoTitulo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaDeuda(Map<String, dynamic> d, int index) {
    final nombre = d['to_name'] ?? '';
    final iniciales = nombre
        .split(' ')
        .take(2)
        .map((p) => p.isNotEmpty ? p[0] : '')
        .join()
        .toUpperCase();
    final monto = (d['amount'] as num?)?.toDouble() ?? 0;
    final color = AppColores.colorParaUsuario(d['to_user_id'] as String? ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColores.superficie,
          borderRadius: BorderRadius.circular(AppEstilos.radioCard),
          boxShadow: [AppEstilos.sombraCard],
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color,
                  child: Text(
                    iniciales,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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
                  'S/. ${monto.toStringAsFixed(2)}',
                  style: AppEstilos.textoCuerpoMedio.copyWith(
                    color: AppColores.gasto,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () async {
                  final resultado = await Navigator.pushNamed(
                    context,
                    AppRutas.registrarPago,
                    arguments: {
                      'group_id': widget.grupoId,
                      'to_user_id': d['to_user_id'],
                      'to_name': nombre,
                      'max_amount': monto,
                    },
                  );
                  if (resultado == true) {
                    _cargarGastos();
                    _cargarBalances();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColores.primario,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppEstilos.radioBoton),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Registrar pago',
                  style: AppEstilos.textoBoton.copyWith(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaDeudor(Map<String, dynamic> d, int index) {
    final nombre = d['from_name'] ?? '';
    final iniciales = nombre
        .split(' ')
        .take(2)
        .map((p) => p.isNotEmpty ? p[0] : '')
        .join()
        .toUpperCase();
    final monto = (d['amount'] as num?)?.toDouble() ?? 0;
    final color = AppColores.colorParaUsuario(
      d['from_user_id'] as String? ?? '',
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColores.superficie,
          borderRadius: BorderRadius.circular(AppEstilos.radioCard),
          boxShadow: [AppEstilos.sombraCard],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color,
              child: Text(
                iniciales,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
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
              'S/. ${monto.toStringAsFixed(2)}',
              style: AppEstilos.textoCuerpoMedio.copyWith(
                color: AppColores.primario,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearMontoGrande(double monto) {
    final partes = monto.toStringAsFixed(2).split('.');
    final entero = partes[0];
    // Agregar separador de miles
    final buffer = StringBuffer();
    int contador = 0;
    for (int i = entero.length - 1; i >= 0; i--) {
      buffer.write(entero[i]);
      contador++;
      if (contador % 3 == 0 && i != 0) buffer.write(',');
    }
    return '${buffer.toString().split('').reversed.join()}.${partes[1]}';
  }


  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColores.skeletonBase,
      highlightColor: AppColores.skeletonHighlight,
      child: ListView(
        padding: const EdgeInsets.all(AppEstilos.paddingPantalla),
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_ElementoListaGasto> _agruparGastos(List<dynamic> lista) {
    if (lista.isEmpty) return [];
    final List<_ElementoListaGasto> resultado = [];
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    String? ultimaCabecera;

    for (final g in lista) {
      if (g['date'] == null) continue;
      final parts = g['date'].toString().split('-');
      final fechaNormalizada = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final diferenciaDias = hoy.difference(fechaNormalizada).inDays;

      String cabeceraActual;
      if (diferenciaDias == 0) {
        cabeceraActual = 'Hoy';
      } else if (diferenciaDias == 1) {
        cabeceraActual = 'Ayer';
      } else if (diferenciaDias >= 2 && diferenciaDias <= 7) {
        cabeceraActual = 'Esta semana';
      } else if (diferenciaDias >= 8 && diferenciaDias <= 14) {
        cabeceraActual = 'Hace 1 semana';
      } else if (fechaNormalizada.year == hoy.year &&
          fechaNormalizada.month == hoy.month) {
        cabeceraActual = 'Este mes';
      } else {
        final mesPasado = hoy.month == 1 ? 12 : hoy.month - 1;
        final anioMesPasado = hoy.month == 1 ? hoy.year - 1 : hoy.year;
        if (fechaNormalizada.year == anioMesPasado &&
            fechaNormalizada.month == mesPasado) {
          cabeceraActual = 'El mes pasado';
        } else {
          cabeceraActual = 'Más antiguo';
        }
      }

      if (ultimaCabecera != cabeceraActual) {
        ultimaCabecera = cabeceraActual;
        resultado.add(_ElementoListaGasto(cabecera: cabeceraActual));
      }
      resultado.add(_ElementoListaGasto(gasto: g));
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
}

class _ElementoListaGasto {
  final String? cabecera;
  final dynamic gasto;
  _ElementoListaGasto({this.cabecera, this.gasto});
}
