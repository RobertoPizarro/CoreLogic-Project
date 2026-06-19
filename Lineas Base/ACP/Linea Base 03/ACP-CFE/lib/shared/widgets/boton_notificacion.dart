import 'package:flutter/material.dart';
import '../../core/constants/app_colores.dart';

/// Un botón no funcional
class BotonNotificacion extends StatelessWidget {
  const BotonNotificacion({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColores.borde, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Futura implementación: abrir pantalla de notificaciones
          },
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.notifications_none,
              color: AppColores.textoTitulo,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
