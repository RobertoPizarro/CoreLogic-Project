/// Grilla de categorías reutilizable (3 columnas).
/// Usado en nuevo/editar movimiento y nuevo/editar presupuesto.
import 'package:flutter/material.dart';
import '../../core/constants/app_colores.dart';
import '../../core/constants/app_estilos.dart';
import 'iconos_categorias.dart';

class GrillaCategorias extends StatelessWidget {
  final List<dynamic> categorias;
  final String? categoriaSeleccionada;
  final Color colorActivo;
  final ValueChanged<String> onSeleccionar;

  const GrillaCategorias({
    super.key,
    required this.categorias,
    required this.categoriaSeleccionada,
    required this.colorActivo,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    // Calcular ancho disponible
    final anchoDisponible =
        MediaQuery.of(context).size.width - (AppEstilos.paddingPantalla * 2);
    const spacing = 10.0;
    final anchoCelda = (anchoDisponible - (spacing * 2)) / 3;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: categorias.map((c) {
        final seleccionada = c['id'] == categoriaSeleccionada;
        return GestureDetector(
          onTap: () => onSeleccionar(c['id']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: anchoCelda,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: seleccionada ? colorActivo : AppColores.superficie,
              borderRadius: BorderRadius.circular(12),
              border: seleccionada ? null : Border.all(color: AppColores.borde),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  IconosCategorias.obtenerIcono(c['icon'] ?? ''),
                  size: 24,
                  color: seleccionada ? Colors.white : colorActivo,
                ),
                const SizedBox(height: 6),
                Text(
                  c['name'] ?? '',
                  style: AppEstilos.textoSecundario.copyWith(
                    fontSize: 12,
                    color: seleccionada ? Colors.white : AppColores.textoTitulo,
                    fontWeight: seleccionada
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
