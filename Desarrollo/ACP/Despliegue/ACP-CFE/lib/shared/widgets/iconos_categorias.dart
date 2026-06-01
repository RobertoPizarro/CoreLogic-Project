/// Mapeo de iconos de categoría según el identificador del backend.
import 'package:flutter/material.dart';

class IconosCategorias {
  static IconData obtenerIcono(String icono) {
    switch (icono) {
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'trending_up':
        return Icons.trending_up;
      case 'undo':
        return Icons.replay;
      case 'gift':
        return Icons.card_giftcard;
      case 'fork_knife':
        return Icons.restaurant;
      case 'directions_bus':
        return Icons.directions_car;
      case 'movie':
        return Icons.movie;
      case 'health_cross':
        return Icons.health_and_safety;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'more_horiz':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }
}
