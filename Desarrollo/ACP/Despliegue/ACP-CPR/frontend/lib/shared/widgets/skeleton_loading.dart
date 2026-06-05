/// Widget reutilizable de skeleton loading con shimmer.

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colores.dart';
import '../../core/constants/app_estilos.dart';

class SkeletonLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoading({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColores.skeletonBase,
      highlightColor: AppColores.skeletonHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColores.skeletonBase,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Skeleton para un item de lista (icono + textos + monto)
class SkeletonListItem extends StatelessWidget {
  const SkeletonListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColores.skeletonBase,
      highlightColor: AppColores.skeletonHighlight,
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: AppEstilos.espacioEntreCards),
        decoration: BoxDecoration(
          color: AppColores.superficie,
          borderRadius: BorderRadius.circular(AppEstilos.radioCard),
        ),
        child: Row(
          children: [
            // Icono
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColores.skeletonBase,
                borderRadius: BorderRadius.circular(
                  AppEstilos.radioIconoCategoria,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColores.skeletonBase,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColores.skeletonBase,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            // Monto
            Container(
              width: 70,
              height: 14,
              decoration: BoxDecoration(
                color: AppColores.skeletonBase,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton para la pantalla Home
class SkeletonHome extends StatelessWidget {
  const SkeletonHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Card de saldo
        const SkeletonLoading(height: 110, borderRadius: 16),
        const SizedBox(height: 12),
        // Cards de ingresos y gastos
        Row(
          children: [
            Expanded(child: SkeletonLoading(height: 70, borderRadius: 16)),
            const SizedBox(width: 12),
            Expanded(child: SkeletonLoading(height: 70, borderRadius: 16)),
          ],
        ),
        const SizedBox(height: 24),
        // Items de lista
        ...List.generate(5, (_) => const SkeletonListItem()),
      ],
    );
  }
}
