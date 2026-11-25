import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_theme.dart';
import '../../../../models/consumo_proyecto.dart';
import '../../../../models/partida.dart';
import '../../../../widgets/app_alert.dart';
import '../../../../widgets/app_confirm_dialog.dart';
import '../../../../widgets/app_empty_state.dart';
import '../../../../widgets/app_status_badge.dart';
import '../providers/project_detail_provider.dart';

/// Modal inferior limpio para visualizar y gestionar los materiales consumidos de una partida.
class PartidaMaterialesSheet extends StatelessWidget {
  final Partida partida;
  final ProjectDetailProvider provider;

  const PartidaMaterialesSheet({
    super.key,
    required this.partida,
    required this.provider,
  });

  static Future<void> show(
    BuildContext context, {
    required Partida partida,
    required ProjectDetailProvider provider,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PartidaMaterialesSheet(
        partida: partida,
        provider: provider,
      ),
    );
  }

  Future<void> _handleDelete(
    BuildContext context,
    ConsumoProyecto consumo,
  ) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: '¿Eliminar consumo?',
      message:
          'Se devolverá "${consumo.materialNombre ?? 'este material'}" al inventario y se revertirá el costo.',
      confirmText: 'Eliminar',
      isDestructive: true,
    );
    if (!confirmed || consumo.id == null) return;

    try {
      await provider.eliminarConsumo(consumo.id!);
      if (context.mounted) {
        AppAlert.showToast(
          context,
          'Consumo eliminado y material devuelto al inventario.',
          type: AppAlertType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppAlert.showToast(
          context,
          'Error al eliminar consumo: $e',
          type: AppAlertType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);
    final dateFmt = DateFormat('dd/MM/yyyy');

    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final consumos = provider.consumosListDePartida(partida);
        final totalConsumido =
            consumos.fold<double>(0.0, (sum, c) => sum + c.total);

        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.68,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 10, 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        color: AppTheme.accentColor,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Materiales Consumidos',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              partida.descripcion,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppStatusBadge(
                        label: currencyFmt.format(totalConsumido),
                        type: AppStatusType.inactive,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 19),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                Expanded(
                  child: consumos.isEmpty
                      ? const AppEmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'Sin materiales consumidos',
                          description:
                              'Aún no se han registrado consumos de inventario para esta partida.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          itemCount: consumos.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          itemBuilder: (ctx, index) {
                            final c = consumos[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.materialNombre ?? 'Material',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${c.cantidad}${c.materialUnidad != null ? ' ${c.materialUnidad}' : ''} × ${currencyFmt.format(c.costoUnitario ?? 0)} · ${dateFmt.format(c.fecha)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    currencyFmt.format(c.total),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  if (!provider.isReadonly && c.id != null)
                                    IconButton(
                                      tooltip: 'Eliminar consumo',
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 17,
                                        color: AppTheme.dangerColor,
                                      ),
                                      onPressed: () => _handleDelete(ctx, c),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
