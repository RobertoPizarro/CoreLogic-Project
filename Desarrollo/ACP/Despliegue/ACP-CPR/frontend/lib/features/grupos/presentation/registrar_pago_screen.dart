/// Pantalla de Registro de Pago a Miembro.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colores.dart';
import '../../../core/constants/app_estilos.dart';
import '../../../core/utils/formato_fecha.dart';
import '../providers/grupos_provider.dart';

class RegistrarPagoScreen extends ConsumerStatefulWidget {
  final String grupoId;
  final String toUserId;
  final String toName;
  final double maxAmount;
  const RegistrarPagoScreen({
    super.key,
    required this.grupoId,
    required this.toUserId,
    required this.toName,
    required this.maxAmount,
  });

  @override
  ConsumerState<RegistrarPagoScreen> createState() =>
      _RegistrarPagoScreenState();
}

class _RegistrarPagoScreenState extends ConsumerState<RegistrarPagoScreen> {
  late TextEditingController _montoController;
  final _notaController = TextEditingController();
  DateTime _fecha = DateTime.now();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController(
      text: widget.maxAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _montoController.dispose();
    _notaController.dispose();
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

  Future<void> _confirmar() async {
    final monto = double.tryParse(_montoController.text);
    if (monto == null || monto <= 0) {
      _snack('Ingresa un monto válido.');
      return;
    }
    if (monto > widget.maxAmount + 0.01) {
      _snack(
        'El monto no puede exceder S/ ${widget.maxAmount.toStringAsFixed(2)}',
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final repo = ref.read(gruposRepositoryProvider);
      await repo.registrarPago(widget.grupoId, {
        'to_user_id': widget.toUserId,
        'amount': monto,
        'date': FormatoFecha.aIso(_fecha),
        'note': _notaController.text.trim().isEmpty
            ? null
            : _notaController.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('Error al registrar el pago.');
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
          'Registrar pago',
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
                  // Avatares y dirección del pago
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppColores.primario,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.arrow_forward,
                              color: AppColores.textoSecundario,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppColores.colorParaUsuario(
                                widget.toUserId,
                              ),
                              child: Text(
                                widget.toName
                                    .split(' ')
                                    .take(2)
                                    .map((p) => p.isNotEmpty ? p[0] : '')
                                    .join()
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Pago a ${widget.toName}',
                          style: AppEstilos.textoCuerpo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                    style: AppEstilos.textoDisplay.copyWith(fontSize: 28),
                    decoration: _deco(
                      '0.00',
                      hintStyleOverride: AppEstilos.textoSecundario.copyWith(
                        fontSize: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Máximo: S/ ${widget.maxAmount.toStringAsFixed(2)}',
                    style: AppEstilos.textoSecundario,
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
                        children: [
                          Expanded(
                            child: Text(
                              FormatoFecha.formatearCorta(
                                _fecha.toIso8601String(),
                              ),
                              style: AppEstilos.textoCuerpo,
                            ),
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
                  // Nota
                  Text('Nota (opcional)', style: AppEstilos.textoLabel),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notaController,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _deco('Ej: Pago por Yape'),
                  ),
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
                      onPressed: _guardando ? null : _confirmar,
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
                          : Text('Confirmar', style: AppEstilos.textoBoton),
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
}
