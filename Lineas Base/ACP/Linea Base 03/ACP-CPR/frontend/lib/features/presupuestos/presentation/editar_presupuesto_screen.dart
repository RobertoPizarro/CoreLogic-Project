/// Pantalla de Edición de Presupuesto

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colores.dart';
import '../../../core/constants/app_estilos.dart';
import '../../../core/utils/formato_fecha.dart';
import '../../../shared/widgets/grilla_categorias.dart';
import '../../movimientos/providers/movimientos_provider.dart';
import '../providers/presupuestos_provider.dart';

class EditarPresupuestoScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> presupuesto;
  const EditarPresupuestoScreen({super.key, required this.presupuesto});
  @override
  ConsumerState<EditarPresupuestoScreen> createState() =>
      _EditarPresupuestoScreenState();
}

class _EditarPresupuestoScreenState
    extends ConsumerState<EditarPresupuestoScreen> {
  late TextEditingController _montoController;
  late TextEditingController _descripcionController;
  String? _categoriaId;
  late DateTime _fechaInicio;
  late DateTime _fechaFin;
  bool _guardando = false;
  List<dynamic> _categorias = [];

  @override
  void initState() {
    super.initState();
    final p = widget.presupuesto;
    _montoController = TextEditingController(
      text: (p['amount'] as num).toStringAsFixed(2),
    );
    _descripcionController = TextEditingController(
      text: p['description'] ?? '',
    );
    _categoriaId = p['category_id'];
    _fechaInicio = DateTime.parse(p['start_date']);
    _fechaFin = DateTime.parse(p['end_date']);
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: Theme.of(
            c,
          ).colorScheme.copyWith(primary: AppColores.primario),
        ),
        child: child!,
      ),
    );
    if (picked != null)
      setState(() {
        if (esInicio)
          _fechaInicio = picked;
        else
          _fechaFin = picked;
      });
  }

  Future<void> _guardar() async {
    final monto = double.tryParse(_montoController.text);
    if (monto == null || monto <= 0) {
      _snack('Ingresa un monto válido.');
      return;
    }
    if (_categoriaId == null) {
      _snack('Selecciona una categoría.');
      return;
    }
    if (_descripcionController.text.trim().isEmpty) {
      _snack('Ingresa una descripción.');
      return;
    }
    if (_fechaInicio.isAfter(_fechaFin)) {
      _snack('La fecha de inicio no puede ser posterior a la de fin.');
      return;
    }

    setState(() => _guardando = true);
    try {
      final repo = ref.read(presupuestosRepositoryProvider);
      await repo.editarPresupuesto(widget.presupuesto['id'], {
        'description': _descripcionController.text.trim(),
        'amount': monto,
        'category_id': _categoriaId,
        'start_date': FormatoFecha.aIso(_fechaInicio),
        'end_date': FormatoFecha.aIso(_fechaFin),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      final msg = e.toString().contains('Ya existe')
          ? 'Ya existe un presupuesto para esta categoría en ese período.'
          : 'Error al guardar.';
      _snack(msg);
    }
    setState(() => _guardando = false);
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    // Obtener categorías del caché
    final asyncCats = ref.watch(categoriasProvider('expense'));
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
          'Editar presupuesto',
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
                    style: AppEstilos.textoDisplay.copyWith(fontSize: 28),
                    decoration: _deco(
                      '0.00',
                      hintStyleOverride: AppEstilos.textoSecundario.copyWith(
                        fontSize: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Descripción', style: AppEstilos.textoLabel),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descripcionController,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _deco('Descripción del presupuesto'),
                  ),
                  const SizedBox(height: 16),
                  Text('Categoría', style: AppEstilos.textoLabel),
                  const SizedBox(height: 6),
                  GrillaCategorias(
                    categorias: _categorias,
                    categoriaSeleccionada: _categoriaId,
                    colorActivo: AppColores.primario,
                    onSeleccionar: (id) => setState(() => _categoriaId = id),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fecha inicio', style: AppEstilos.textoLabel),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () => _seleccionarFecha(true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
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
                                  children: [
                                    Expanded(
                                      child: Text(
                                        FormatoFecha.formatearCorta(
                                          FormatoFecha.aIso(_fechaInicio),
                                        ),
                                        style: AppEstilos.textoSecundario
                                            .copyWith(
                                              color: AppColores.textoTitulo,
                                            ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: AppColores.textoSecundario,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fecha fin', style: AppEstilos.textoLabel),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () => _seleccionarFecha(false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
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
                                  children: [
                                    Expanded(
                                      child: Text(
                                        FormatoFecha.formatearCorta(
                                          FormatoFecha.aIso(_fechaFin),
                                        ),
                                        style: AppEstilos.textoSecundario
                                            .copyWith(
                                              color: AppColores.textoTitulo,
                                            ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: AppColores.textoSecundario,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
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
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColores.textoTitulo,
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

  InputDecoration _deco(String h, {TextStyle? hintStyleOverride}) =>
      InputDecoration(
        hintText: h,
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
