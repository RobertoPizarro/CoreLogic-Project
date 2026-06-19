/// Pantalla de Nuevo Movimiento
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colores.dart';
import '../../../core/constants/app_estilos.dart';
import '../../../core/utils/formato_fecha.dart';
import '../../../shared/widgets/grilla_categorias.dart';
import '../providers/movimientos_provider.dart';

class NuevoMovimientoScreen extends ConsumerStatefulWidget {
  const NuevoMovimientoScreen({super.key});
  @override
  ConsumerState<NuevoMovimientoScreen> createState() =>
      _NuevoMovimientoScreenState();
}

class _NuevoMovimientoScreenState extends ConsumerState<NuevoMovimientoScreen> {
  String _tipo = 'expense';
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  String? _categoriaId;
  DateTime _fecha = DateTime.now();
  String _metodoPago = 'efectivo';
  bool _guardando = false;
  List<dynamic> _categorias = [];

  /// Color activo según el tipo seleccionado
  Color get _colorActivo =>
      _tipo == 'income' ? AppColores.primario : AppColores.gasto;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: _colorActivo),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _guardar() async {
    final monto = double.tryParse(_montoController.text);
    if (monto == null || monto <= 0) {
      _mostrarSnack('Ingresa un monto válido mayor a 0.');
      return;
    }
    if (_categoriaId == null) {
      _mostrarSnack('Selecciona una categoría.');
      return;
    }
    if (_descripcionController.text.trim().isEmpty) {
      _mostrarSnack('Ingresa una descripción.');
      return;
    }

    setState(() => _guardando = true);
    final repo = ref.read(movimientosRepositoryProvider);

    try {
      // Si es gasto, evaluar presupuesto primero
      if (_tipo == 'expense') {
        final eval = await repo.evaluarPresupuesto({
          'category_id': _categoriaId,
          'amount': monto,
          'date': FormatoFecha.aIso(_fecha),
        });
        if (eval['excede_presupuesto'] == true) {
          final confirmar = await _mostrarModalExcedido(
            eval['presupuesto_descripcion'] ?? '',
            (eval['monto_exceso'] as num).toDouble(),
          );
          if (!confirmar) {
            setState(() => _guardando = false);
            return;
          }
        }
      }

      await repo.crearMovimiento({
        'type': _tipo,
        'amount': monto,
        'category_id': _categoriaId,
        'date': FormatoFecha.aIso(_fecha),
        'description': _descripcionController.text.trim(),
        'payment_method': _metodoPago,
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _mostrarSnack('Error al guardar el movimiento.');
    }
    setState(() => _guardando = false);
  }

  Future<bool> _mostrarModalExcedido(String descripcion, double exceso) async {
    return await showDialog<bool>(
          context: context,
          barrierColor: Colors.black54,
          builder: (context) => Dialog(
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
                      onTap: () => Navigator.pop(context, false),
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
                    'Presupuesto excedido',
                    style: AppEstilos.textoSubtitulo,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    descripcion,
                    style: AppEstilos.textoSecundario,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Exceso: S/ ${exceso.toStringAsFixed(2)}',
                    style: AppEstilos.textoCuerpoMedio.copyWith(
                      color: AppColores.gasto,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
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
                      child: Text(
                        'Confirmar gasto',
                        style: AppEstilos.textoBoton,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
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
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  void _mostrarSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    // Obtener categorías del caché
    final asyncCats = ref.watch(categoriasProvider(_tipo));
    asyncCats.whenData((cats) {
      if (_categorias != cats) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _categorias = cats);
        });
      }
    });

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
          'Nuevo movimiento',
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
                  // Toggle Ingreso / Gasto
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColores.fondo,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColores.borde),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _tipo = 'income';
                              _categoriaId = null;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _tipo == 'income'
                                    ? AppColores.primario
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Ingreso',
                                  style: AppEstilos.textoCuerpoMedio.copyWith(
                                    color: _tipo == 'income'
                                        ? Colors.white
                                        : AppColores.textoSecundario,
                                    fontWeight: _tipo == 'income'
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _tipo = 'expense';
                              _categoriaId = null;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _tipo == 'expense'
                                    ? AppColores.gasto
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Gasto',
                                  style: AppEstilos.textoCuerpoMedio.copyWith(
                                    color: _tipo == 'expense'
                                        ? Colors.white
                                        : AppColores.textoSecundario,
                                    fontWeight: _tipo == 'expense'
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Monto
                  Text('Monto (S/.)', style: AppEstilos.textoLabel),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _montoController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    style: AppEstilos.textoDisplay.copyWith(
                      fontSize: 28,
                      color: AppColores.textoTitulo,
                    ),
                    decoration: _inputDeco(
                      '0.00',
                      hintStyleOverride: AppEstilos.textoSecundario.copyWith(
                        fontSize: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Categoría
                  Text('Categoría', style: AppEstilos.textoLabel),
                  const SizedBox(height: 6),
                  GrillaCategorias(
                    categorias: _categorias,
                    categoriaSeleccionada: _categoriaId,
                    colorActivo: _colorActivo,
                    onSeleccionar: (id) => setState(() {
                      _categoriaId = id;
                    }),
                  ),
                  const SizedBox(height: 16),
                  // Fecha
                  Text('Fecha', style: AppEstilos.textoLabel),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _seleccionarFecha,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColores.superficie,
                        borderRadius: BorderRadius.circular(
                          AppEstilos.radioInput,
                        ),
                        border: Border.all(color: AppColores.borde),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            FormatoFecha.formatearLarga(
                              FormatoFecha.aIso(_fecha),
                            ),
                            style: AppEstilos.textoCuerpo,
                          ),
                          const Icon(
                            Icons.calendar_today,
                            color: AppColores.textoSecundario,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Descripción
                  Text('Descripción', style: AppEstilos.textoLabel),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descripcionController,
                    maxLines: 2,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _inputDeco('Descripción del movimiento'),
                  ),
                  const SizedBox(height: 16),
                  // Método de pago
                  Text('Método de pago', style: AppEstilos.textoLabel),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _metodoPagoBtn('Efectivo', 'efectivo', Icons.money),
                      const SizedBox(width: 8),
                      _metodoPagoBtn('Tarjeta', 'tarjeta', Icons.credit_card),
                      const SizedBox(width: 8),
                      _metodoPagoBtn(
                        'Transferencia',
                        'transferencia',
                        Icons.swap_horiz,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColores.superficie,
                        foregroundColor: AppColores.textoTitulo,
                        side: const BorderSide(color: AppColores.borde),
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
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _guardando ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _colorActivo,
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
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text('Guardar', style: AppEstilos.textoBoton),
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

  Widget _metodoPagoBtn(String label, String valor, IconData icono) {
    final activo = _metodoPago == valor;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _metodoPago = valor),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: activo ? _colorActivo : AppColores.superficie,
            borderRadius: BorderRadius.circular(AppEstilos.radioInput),
            border: activo ? null : Border.all(color: AppColores.borde),
          ),
          child: Column(
            children: [
              Icon(
                icono,
                color: activo ? Colors.white : AppColores.textoSecundario,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppEstilos.textoSecundario.copyWith(
                  fontSize: 11,
                  color: activo ? Colors.white : AppColores.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, {TextStyle? hintStyleOverride}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: hintStyleOverride ?? AppEstilos.textoSecundario,
        filled: true,
        fillColor: AppColores.superficie,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
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
      );
}
