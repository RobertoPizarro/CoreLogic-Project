/// Paleta de colores de la aplicación ACP.

import 'package:flutter/material.dart';

class AppColores {
  // Paleta principal
  static const Color primario = Color(0xFF1A7A7A);
  static const Color primarioSuave = Color(0xFFE8F4F4);
  static const Color fondo = Color(0xFFF2F4F6);
  static const Color superficie = Color(0xFFFFFFFF);
  static const Color textoTitulo = Color(0xFF1A1A2E);
  static const Color textoSecundario = Color(0xFF8A8A9A);
  static const Color ingreso = Color(0xFF1A7A7A);
  static const Color gasto = Color(0xFFE53935);
  static const Color gastoSuave = Color(0xFFFDECEA);
  static const Color borde = Color(0xFFE8E8F0);
  static const Color vencido = Color(0xFF9E9E9E);
  static const Color proximo = Color(0xFF9E9E9E);
  static const Color warning = Color(0xFFE53935);
  static const Color enlace = Color(0xFF1A7A7A);

  // Avatares de miembros (colores rotativos)
  static const List<Color> avatarColores = [
    Color(0xFF1A7A7A),
    Color(0xFF7B68EE),
    Color(0xFFFFA726),
    Color(0xFF26A69A),
  ];

  /// Color consistente para un usuario basado en su ID.
  /// El mismo user_id siempre produce el mismo color en todas las pantallas.
  static Color colorParaUsuario(String userId) {
    return avatarColores[userId.hashCode.abs() % avatarColores.length];
  }

  /// Color consistente para un grupo basado en su ID.
  static Color colorParaGrupo(String grupoId) {
    return avatarColores[grupoId.hashCode.abs() % avatarColores.length];
  }

  // Skeleton loading
  static const Color skeletonBase = Color(0xFFE8E8F0);
  static const Color skeletonHighlight = Color(0xFFF5F5FA);
}
