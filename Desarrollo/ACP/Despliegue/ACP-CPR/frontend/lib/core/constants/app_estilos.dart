/// Estilos globales de la aplicación ACP.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colores.dart';

class AppEstilos {
  // --- Border Radius ---
  static const double radioBoton = 14.0;
  static const double radioCard = 16.0;
  static const double radioInput = 12.0;
  static const double radioModal = 20.0;
  static const double radioBadge = 20.0;
  static const double radioLogoApp = 20.0;
  static const double radioIconoCategoria = 12.0;

  // --- Padding ---
  static const double paddingPantalla = 20.0;
  static const double paddingCard = 16.0;
  static const double espacioEntreCards = 10.0;
  static const double espacioEntreSecciones = 24.0;

  // --- Tipografía ---
  static TextStyle textoDisplay = GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColores.textoTitulo,
  );

  static TextStyle textoTituloPantalla = GoogleFonts.inter(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColores.textoTitulo,
  );

  static TextStyle textoTituloCard = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColores.textoTitulo,
  );

  static TextStyle textoSubtitulo = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColores.textoTitulo,
  );

  static TextStyle textoCuerpo = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColores.textoTitulo,
  );

  static TextStyle textoCuerpoMedio = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColores.textoTitulo,
  );

  static TextStyle textoSecundario = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColores.textoSecundario,
  );

  static TextStyle textoLabel = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColores.textoSecundario,
  );

  static TextStyle textoBoton = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle textoBadge = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle textoNavBar = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );

  // --- Sombras ---
  static BoxShadow sombraCard = BoxShadow(
    color: Colors.black.withValues(alpha: 0.04),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );

  static BoxShadow sombraFAB = const BoxShadow(
    color: Colors.black12,
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  static BoxShadow sombraBotonBack = BoxShadow(
    color: Colors.black.withValues(alpha: 0.06),
    blurRadius: 6,
    offset: const Offset(0, 2),
  );
}
