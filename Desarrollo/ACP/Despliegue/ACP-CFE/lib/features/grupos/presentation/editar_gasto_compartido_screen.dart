/// Pantalla de Edición de Gasto Compartido.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colores.dart';
import '../../../core/constants/app_estilos.dart';
import '../../../core/utils/formato_fecha.dart';
import '../providers/grupos_provider.dart';

class EditarGastoCompartidoScreen extends ConsumerStatefulWidget {
  final String grupoId;
  final Map<String, dynamic> gasto;
  final List<dynamic> miembros;
  const EditarGastoCompartidoScreen({
    super.key,
    required this.grupoId,
    required this.gasto,
    required this.miembros,
  });

  @override
  ConsumerState<EditarGastoCompartidoScreen> createState() =>
      _EditarGastoCompartidoScreenState();
}

class _EditarGastoCompartidoScreenState
    extends ConsumerState<EditarGastoCompartidoScreen> {
  late TextEditingController _montoController;
  late TextEditingController _descripcionController;
  late DateTime _fecha;
  late String? _pagadorId;
  late String _tipoDivision;
  late Set<String> _participantes;
  Map<String, TextEditingController> _controllersPorcentaje = {};
  Map<String, TextEditingController> _controllersPersonalizado = {};
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final g = widget.gasto;
    _montoController = TextEditingController(
      text: (g['total_amount'] as num).toStringAsFixed(2),
    );
    _descripcionController = TextEditingController(
      text: g['description'] ?? '',
    );
    _fecha = DateTime.parse(g['date']);
    _pagadorId = (g['paid_by'] as Map<String, dynamic>?)?['user_id'];
    _tipoDivision = g['split_type'] ?? 'igual';
    final splits = g['splits'] as List<dynamic>? ?? [];
    _participantes = splits.map((s) => s['user_id'] as String).toSet();
    for (var m in widget.miembros) {
      final uid = m['user_id'] as String;
      _controllersPorcentaje[uid] = TextEditingController();
      _controllersPersonalizado[uid] = TextEditingController();
    }
    // Precargar valores de splits
    for (var s in splits) {
      final uid = s['user_id'] as String;
      final amt = (s['amount_owed'] as num).toDouble();
      _controllersPersonalizado[uid]?.text = amt.toStringAsFixed(2);
    }
    _inicializarPorcentajes();
  }

  void _inicializarPorcentajes() {
    if (_participantes.isEmpty) return;
    final n = _participantes.length;
    final base = (100.0 / n * 10).floor() / 10;
    final residuo = ((100.0 - base * n) * 10).round() / 10;
    int i = 0;
    for (var uid in _participantes) {
      final valor = i == 0 ? base + residuo : base;
      _controllersPorcentaje[uid]?.text = valor.toStringAsFixed(1);
      i++;
    }
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    for (var c in _controllersPorcentaje.values) c.dispose();
    for (var c in _controllersPersonalizado.values) c.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
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
    if (picked != null) setState(() => _fecha = picked);
  }

  List<Map<String, dynamic>> _calcularDivisionIgual(double monto) {
    final participantesOrdenados = _participantes.toList();
    final n = participantesOrdenados.length;
    if (n == 0) return [];
    final base = (monto * 100 / n).floor() / 100;
    final total = base * n;
    final residuo = ((monto - total) * 100).round() / 100;
    return participantesOrdenados.asMap().entries.map((e) {
      final amt = e.key == 0 ? base + residuo : base;
      return {
        'user_id': e.value,
        'amount_owed': double.parse(amt.toStringAsFixed(2)),
      };
    }).toList();
  }

  Future<void> _guardar() async {
    final monto = double.tryParse(_montoController.text);
    if (monto == null || monto <= 0) {
      _snack('Ingresa un monto válido.');
      return;
    }
    if (_descripcionController.text.trim().isEmpty) {
      _snack('Ingresa una descripción.');
      return;
    }
    if (_pagadorId == null) {
      _snack('Selecciona quién pagó.');
      return;
    }
    if (_participantes.isEmpty) {
      _snack('Selecciona al menos un participante.');
      return;
    }

    final datos = <String, dynamic>{
      'description': _descripcionController.text.trim(),
      'total_amount': monto,
      'paid_by': _pagadorId,
      'date': FormatoFecha.aIso(_fecha),
      'split_type': _tipoDivision,
      'participants': _participantes.toList(),
    };
    if (_tipoDivision == 'porcentaje') {
      datos['splits'] = _participantes.map((uid) {
        final pct =
            double.tryParse(_controllersPorcentaje[uid]?.text ?? '') ?? 0;
        return {
          'user_id': uid,
          'percentage': pct,
          'amount_owed': monto * pct / 100,
        };
      }).toList();
    } else if (_tipoDivision == 'personalizado') {
      datos['splits'] = _participantes.map((uid) {
        final amt =
            double.tryParse(_controllersPersonalizado[uid]?.text ?? '') ?? 0;
        return {'user_id': uid, 'amount_owed': amt};
      }).toList();
    }

    setState(() => _guardando = true);
    try {
      final repo = ref.read(gruposRepositoryProvider);
      await repo.editarGasto(widget.grupoId, widget.gasto['id'], datos);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('Error al editar el gasto.');
    }
    if (mounted) setState(() => _guardando = false);
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  InputDecoration _deco(String hint, {TextStyle? hintStyleOverride}) =>
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
          borderSide: BorderSide(color: AppColores.borde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppEstilos.radioInput),
          borderSide: BorderSide(color: AppColores.borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppEstilos.radioInput),
          borderSide: BorderSide(color: AppColores.borde),
        ),
      );

  String _nombreMiembro(String uid) {
    final miembro = widget.miembros.cast<Map<String, dynamic>>().firstWhere(
      (m) => m['user_id'] == uid,
      orElse: () => <String, dynamic>{'name': '?'},
    );
    return (miembro['name'] ?? '?').toString();
  }

  String _nombreCorto(String uid) => _nombreMiembro(uid).split(' ').first;

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
          'Editar gasto compartido',
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
                  // Monto grande centrado
                  Center(
                    child: Column(
                      children: [
                        Text('Monto (S/.)', style: AppEstilos.textoSecundario),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 220,
                          child: TextField(
                            controller: _montoController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            textAlign: TextAlign.center,
                            style: AppEstilos.textoDisplay.copyWith(
                              fontSize: 40,
                              letterSpacing: 2,
                            ),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: AppEstilos.textoSecundario.copyWith(
                                fontSize: 40,
                                letterSpacing: 2,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
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
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: AppColores.textoSecundario,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              FormatoFecha.formatearCorta(
                                _fecha.toIso8601String(),
                              ),
                              style: AppEstilos.textoCuerpo,
                            ),
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
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _deco('Descripción del gasto'),
                  ),
                  const SizedBox(height: 16),
                  // Pagado por — chips horizontales
                  Text('Pagado por', style: AppEstilos.textoLabel),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.miembros.map((m) {
                      final uid = m['user_id'] as String;
                      final activo = _pagadorId == uid;
                      return GestureDetector(
                        onTap: () => setState(() => _pagadorId = uid),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: activo
                                ? AppColores.primario
                                : AppColores.superficie,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: activo
                                  ? AppColores.primario
                                  : AppColores.borde,
                            ),
                          ),
                          child: Text(
                            _nombreCorto(uid),
                            style: AppEstilos.textoCuerpo.copyWith(
                              color: activo
                                  ? Colors.white
                                  : AppColores.textoTitulo,
                              fontWeight: activo
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // Dividir entre — checkboxes con avatares
                  Text('Dividir entre', style: AppEstilos.textoLabel),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColores.superficie,
                      borderRadius: BorderRadius.circular(AppEstilos.radioCard),
                      border: Border.all(color: AppColores.borde),
                    ),
                    child: Column(
                      children: widget.miembros.asMap().entries.map((e) {
                        final m = e.value;
                        final i = e.key;
                        final uid = m['user_id'] as String;
                        final nombre = m['name'] ?? '';
                        final iniciales = nombre
                            .split(' ')
                            .take(2)
                            .map((p) => p.isNotEmpty ? p[0] : '')
                            .join()
                            .toUpperCase();
                        final color = AppColores.colorParaUsuario(uid);
                        final seleccionado = _participantes.contains(uid);
                        return Column(
                          children: [
                            InkWell(
                              onTap: () => setState(() {
                                if (seleccionado)
                                  _participantes.remove(uid);
                                else
                                  _participantes.add(uid);
                                if (_tipoDivision == 'porcentaje')
                                  _inicializarPorcentajes();
                              }),
                              child: Padding(
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
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: seleccionado
                                            ? AppColores.primario
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: seleccionado
                                              ? AppColores.primario
                                              : AppColores.borde,
                                          width: 2,
                                        ),
                                      ),
                                      child: seleccionado
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (i < widget.miembros.length - 1)
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
                  const SizedBox(height: 20),
                  // Tipo de división
                  Text('Tipo de división', style: AppEstilos.textoLabel),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildChipDivision('Igual', 'igual'),
                      const SizedBox(width: 8),
                      _buildChipDivision('Porcentaje', 'porcentaje'),
                      const SizedBox(width: 8),
                      _buildChipDivision('Personalizado', 'personalizado'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDivisionDetalle(),
                  const SizedBox(height: 16),
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
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
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

  Widget _buildChipDivision(String label, String tipo) {
    final activo = _tipoDivision == tipo;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _tipoDivision = tipo);
          if (tipo == 'porcentaje') _inicializarPorcentajes();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: activo ? AppColores.primario : AppColores.superficie,
            borderRadius: BorderRadius.circular(AppEstilos.radioInput),
            border: Border.all(
              color: activo ? AppColores.primario : AppColores.borde,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppEstilos.textoSecundario.copyWith(
                color: activo ? Colors.white : AppColores.textoTitulo,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivisionDetalle() {
    final monto = double.tryParse(_montoController.text) ?? 0;
    final participantesLista = _participantes.toList();
    if (_tipoDivision == 'igual')
      return _buildDivisionIgual(monto, participantesLista);
    if (_tipoDivision == 'porcentaje')
      return _buildDivisionPorcentaje(participantesLista);
    return _buildDivisionPersonalizado(participantesLista);
  }

  Widget _buildDivisionIgual(double monto, List<String> participantesLista) {
    final splits = _calcularDivisionIgual(monto);
    return Column(
      children: participantesLista.asMap().entries.map((e) {
        final uid = e.value;
        final nombre = _nombreMiembro(uid);
        final iniciales = nombre
            .split(' ')
            .take(2)
            .map((p) => p.isNotEmpty ? p[0] : '')
            .join()
            .toUpperCase();
        final color = AppColores.colorParaUsuario(uid);
        final split = splits.cast<Map<String, dynamic>>().firstWhere(
          (s) => s['user_id'] == uid,
          orElse: () => <String, dynamic>{'amount_owed': 0.0},
        );
        final montoSplit = (split['amount_owed'] as num).toDouble();
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColores.superficie,
              borderRadius: BorderRadius.circular(AppEstilos.radioCard),
              border: Border.all(color: AppColores.borde),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color,
                  child: Text(
                    iniciales,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    nombre,
                    style: AppEstilos.textoCuerpoMedio,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'S/. ${montoSplit.toStringAsFixed(2)}',
                  style: AppEstilos.textoSecundario.copyWith(fontSize: 15),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDivisionPorcentaje(List<String> participantesLista) {
    return Column(
      children: participantesLista.map((uid) {
        final nombre = _nombreMiembro(uid);
        final iniciales = nombre
            .split(' ')
            .take(2)
            .map((p) => p.isNotEmpty ? p[0] : '')
            .join()
            .toUpperCase();
        final color = AppColores.colorParaUsuario(uid);
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColores.superficie,
              borderRadius: BorderRadius.circular(AppEstilos.radioCard),
              border: Border.all(color: AppColores.borde),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color,
                  child: Text(
                    iniciales,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    nombre,
                    style: AppEstilos.textoCuerpoMedio,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: _controllersPorcentaje[uid],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    textAlign: TextAlign.end,
                    style: AppEstilos.textoCuerpo,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Text(' %', style: AppEstilos.textoSecundario),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDivisionPersonalizado(List<String> participantesLista) {
    return Column(
      children: participantesLista.map((uid) {
        final nombre = _nombreMiembro(uid);
        final iniciales = nombre
            .split(' ')
            .take(2)
            .map((p) => p.isNotEmpty ? p[0] : '')
            .join()
            .toUpperCase();
        final color = AppColores.colorParaUsuario(uid);
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColores.superficie,
              borderRadius: BorderRadius.circular(AppEstilos.radioCard),
              border: Border.all(color: AppColores.borde),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color,
                  child: Text(
                    iniciales,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    nombre,
                    style: AppEstilos.textoCuerpoMedio,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('S/. ', style: AppEstilos.textoSecundario),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: _controllersPersonalizado[uid],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    textAlign: TextAlign.end,
                    style: AppEstilos.textoCuerpo,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
