/// Pantalla Home
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colores.dart';
import '../../../core/constants/app_estilos.dart';
import '../../../core/constants/app_rutas.dart';
import '../../../core/utils/formato_moneda.dart';
import '../../../core/utils/formato_fecha.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import '../../../shared/widgets/iconos_categorias.dart';
import '../../../shared/widgets/boton_notificacion.dart';
import '../providers/home_provider.dart';
import 'navegador_principal.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: AppColores.fondo,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColores.primario,
          onRefresh: () async {
            ref.invalidate(homeProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppEstilos.paddingPantalla),
            child: homeAsync.when(
              loading: () => const SkeletonHome(),
              error: (error, _) => _buildError(ref),
              data: (datos) => _buildContenido(context, ref, datos),
            ),
          ),
        ),
      ),
      // Botón para nuevo movimiento
      floatingActionButton: GestureDetector(
        onTap: () async {
          await Navigator.pushNamed(context, AppRutas.nuevoMovimiento);
          ref.invalidate(homeProvider);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppColores.primario,
            borderRadius: BorderRadius.circular(AppEstilos.radioBoton),
            boxShadow: [AppEstilos.sombraFAB],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Nuevo movimiento', style: AppEstilos.textoBoton),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Text(
            'Algo salió mal. Intenta de nuevo.',
            style: AppEstilos.textoCuerpo,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => ref.invalidate(homeProvider),
            child: Text(
              'Reintentar',
              style: AppEstilos.textoCuerpoMedio.copyWith(
                color: AppColores.enlace,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> datos,
  ) {
    final saldo = (datos['saldo_total'] as num).toDouble();
    final ingresos = (datos['total_ingresos'] as num).toDouble();
    final gastos = (datos['total_gastos'] as num).toDouble();
    final movimientos = datos['movimientos_recientes'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bienvenido 👋', style: AppEstilos.textoSubtitulo),
                const SizedBox(height: 4),
                Text(
                  'Tu resumen financiero',
                  style: AppEstilos.textoSecundario,
                ),
              ],
            ),
            const BotonNotificacion(),
          ],
        ),
        const SizedBox(height: 20),

        // Card de saldo total
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppEstilos.paddingCard),
          decoration: BoxDecoration(
            color: AppColores.primario,
            borderRadius: BorderRadius.circular(AppEstilos.radioCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saldo total',
                style: AppEstilos.textoSecundario.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                FormatoMoneda.formatear(saldo),
                style: AppEstilos.textoTituloCard.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Cards de ingresos y gastos
        Row(
          children: [
            // Ingresos
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColores.primarioSuave,
                  borderRadius: BorderRadius.circular(AppEstilos.radioCard),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColores.ingreso,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('Ingresos', style: AppEstilos.textoSecundario),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      FormatoMoneda.formatear(ingresos),
                      style: AppEstilos.textoCuerpoMedio.copyWith(
                        color: AppColores.ingreso,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Gastos
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColores.gastoSuave,
                  borderRadius: BorderRadius.circular(AppEstilos.radioCard),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColores.gasto,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('Gastos', style: AppEstilos.textoSecundario),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      FormatoMoneda.formatear(gastos),
                      style: AppEstilos.textoCuerpoMedio.copyWith(
                        color: AppColores.gasto,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppEstilos.espacioEntreSecciones),

        // Sección: Movimientos recientes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Movimientos recientes', style: AppEstilos.textoSubtitulo),
            GestureDetector(
              onTap: () {
                ref.read(navegacionIndexProvider.notifier).state =
                    1; // Ir a la pantalla de movimientos
              },
              child: Text(
                'Ver todos',
                style: AppEstilos.textoCuerpoMedio.copyWith(
                  color: AppColores.enlace,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (movimientos.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: AppColores.textoSecundario,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sin movimientos aún',
                    style: AppEstilos.textoCuerpoMedio,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Registra tu primer ingreso o gasto',
                    style: AppEstilos.textoSecundario,
                  ),
                ],
              ),
            ),
          )
        else
          ...movimientos.map((mov) => _buildItemMovimiento(context, ref, mov)),
      ],
    );
  }

  Widget _buildItemMovimiento(
    BuildContext context,
    WidgetRef ref,
    dynamic mov,
  ) {
    final esIngreso = mov['type'] == 'income';
    final icono = IconosCategorias.obtenerIcono(mov['icon'] ?? '');

    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(
          context,
          AppRutas.detalleMovimiento,
          arguments: {'id': mov['id']},
        );
        ref.invalidate(homeProvider);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: AppEstilos.espacioEntreCards),
        decoration: BoxDecoration(
          color: AppColores.superficie,
          borderRadius: BorderRadius.circular(AppEstilos.radioCard),
          boxShadow: [AppEstilos.sombraCard],
        ),
        child: Row(
          children: [
            // Icono categoría
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: esIngreso
                    ? AppColores.primarioSuave
                    : AppColores.gastoSuave,
                borderRadius: BorderRadius.circular(
                  AppEstilos.radioIconoCategoria,
                ),
              ),
              child: Icon(
                icono,
                color: esIngreso ? AppColores.primario : AppColores.gasto,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Descripción y fecha
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mov['description'] ?? mov['category'] ?? '',
                    style: AppEstilos.textoCuerpoMedio,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    FormatoFecha.formatearCorta(mov['date']),
                    style: AppEstilos.textoSecundario,
                  ),
                ],
              ),
            ),
            // Monto
            Text(
              FormatoMoneda.formatearConSigno(
                (mov['amount'] as num).toDouble(),
                mov['type'],
              ),
              style: AppEstilos.textoCuerpoMedio.copyWith(
                color: esIngreso ? AppColores.ingreso : AppColores.gasto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
