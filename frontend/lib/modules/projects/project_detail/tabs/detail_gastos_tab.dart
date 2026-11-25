import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/constants.dart';
import '../../../../models/gasto_proyecto.dart';
import '../../../../widgets/app_alert.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_confirm_dialog.dart';
import '../../../../widgets/app_empty_state.dart';
import '../../../../widgets/app_status_badge.dart';
import '../../gasto_proyecto_dialog.dart';
import '../providers/project_detail_provider.dart';

/// Pestaña 3 (Gastos): KPIs compactos, filtros por tipo y lista limpia integrada.
class DetailGastosTab extends StatefulWidget {
  const DetailGastosTab({super.key});

  @override
  State<DetailGastosTab> createState() => _DetailGastosTabState();
}

class _DetailGastosTabState extends State<DetailGastosTab> {
  String _filter = 'Todos';

  bool _matchesFilter(GastoProyecto g) {
    if (_filter == 'Todos') return true;
    final tipo = g.tipoGasto.toLowerCase();
    if (_filter == 'Mano de Obra') return tipo.contains('mano de obra');
    if (_filter == 'Alquiler') return tipo.contains('alquiler');
    return !tipo.contains('mano de obra') && !tipo.contains('alquiler');
  }

  Future<void> _openRegisterGasto(
    BuildContext context,
    ProjectDetailProvider provider,
  ) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => GastoProyectoDialog(proyecto: provider.proyecto!),
    );
    if (created == true) {
      await provider.refresh();
    }
  }

  Future<void> _openUrl(
    BuildContext context,
    String rawUrl, {
    required String errorMessage,
    bool external = false,
  }) async {
    final uri = Uri.parse(rawUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: external
            ? LaunchMode.externalApplication
            : LaunchMode.platformDefault,
      );
    } else if (context.mounted) {
      AppAlert.showToast(context, errorMessage, type: AppAlertType.error);
    }
  }

  Future<void> _confirmDeleteGasto(
    BuildContext context,
    ProjectDetailProvider provider,
    GastoProyecto gasto,
  ) async {
    if (gasto.id == null) return;
    final confirmed = await AppConfirmDialog.show(
      context,
      title: '¿Eliminar gasto?',
      message:
          'Se eliminará este gasto y su asiento contable asociado. Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      isDestructive: true,
    );
    if (!confirmed) return;

    try {
      await provider.eliminarGasto(gasto.id!);
      if (context.mounted) {
        AppAlert.showToast(
          context,
          'Gasto eliminado exitosamente.',
          type: AppAlertType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppAlert.showToast(
          context,
          'Error al eliminar gasto: $e',
          type: AppAlertType.error,
        );
      }
    }
  }

  AppStatusType _badgeTypeFor(String tipoGasto) {
    final t = tipoGasto.toLowerCase();
    if (t.contains('mano de obra')) return AppStatusType.pending;
    if (t.contains('alquiler')) return AppStatusType.info;
    return AppStatusType.neutral;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectDetailProvider>();
    final proyecto = provider.proyecto!;
    final gastos = provider.gastos;
    final filtered = gastos.where(_matchesFilter).toList();
    final currencyFmt = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPIs compactos 2x2
        Row(
          children: [
            Expanded(
              child: _GastoKpiTile(
                label: 'Total Gastado',
                value: currencyFmt.format(provider.totalGastado),
                color: AppTheme.dangerColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GastoKpiTile(
                label: 'Mano de Obra',
                value: currencyFmt.format(provider.gastosManoObra),
                color: const Color(0xFFD97706),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _GastoKpiTile(
                label: 'Alquiler',
                value: currencyFmt.format(provider.gastosAlquiler),
                color: const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GastoKpiTile(
                label: 'Otros Egresos',
                value: currencyFmt.format(provider.gastosOtros),
                color: const Color(0xFF0891B2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Encabezado + Acciones
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Historial de Gastos',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(
                  text: 'Imprimir',
                  icon: Icons.print_outlined,
                  size: AppButtonSize.compact,
                  variant: AppButtonVariant.outlined,
                  borderRadius: 8,
                  onPressed: () => _openUrl(
                    context,
                    '$host/reports/gastos/pdf?proyecto_id=${proyecto.id}',
                    errorMessage: 'No se pudo abrir el reporte de gastos.',
                  ),
                ),
                if (proyecto.estado == 'Activo') ...[
                  const SizedBox(width: 8),
                  AppButton(
                    text: 'Registrar',
                    icon: Icons.add_rounded,
                    size: AppButtonSize.compact,
                    variant: AppButtonVariant.primary,
                    borderRadius: 8,
                    onPressed: () => _openRegisterGasto(context, provider),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Filtros por categoría
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Todos', 'Mano de Obra', 'Alquiler', 'Otros'].map((f) {
              final selected = _filter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => setState(() => _filter = f),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primaryColor
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primaryColor
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.w500,
                        color:
                            selected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 18, color: Color(0xFFE2E8F0)),

        // Lista limpia de gastos
        if (filtered.isEmpty)
          AppEmptyState(
            icon: Icons.receipt_long_outlined,
            title: _filter == 'Todos'
                ? 'Sin gastos registrados'
                : 'Sin gastos en "$_filter"',
            description: _filter == 'Todos'
                ? 'Aún no hay gastos de mano de obra, alquiler u otros en este proyecto.'
                : 'Cambia el filtro para consultar otros tipos de gastos.',
            actionText:
                (_filter == 'Todos' && proyecto.estado == 'Activo')
                    ? 'Registrar Gasto'
                    : null,
            onAction: (_filter == 'Todos' && proyecto.estado == 'Activo')
                ? () => _openRegisterGasto(context, provider)
                : null,
          )
        else
          ...filtered.map((g) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                AppStatusBadge(
                                  label: g.tipoGasto.isNotEmpty
                                      ? g.tipoGasto
                                      : 'Gasto',
                                  type: _badgeTypeFor(g.tipoGasto),
                                ),
                                Text(
                                  dateFmt.format(g.fecha),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                if (g.metodoPago.isNotEmpty)
                                  Text(
                                    '· ${g.metodoPago}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (g.descripcion != null &&
                                      g.descripcion!.trim().isNotEmpty)
                                  ? g.descripcion!
                                  : 'Sin descripción',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (g.proveedor != null || g.subpartida != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                [
                                  if (g.proveedor != null) g.proveedor!.name,
                                  if (g.subpartida != null)
                                    g.subpartida!.descripcion,
                                ].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFmt.format(g.monto),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.dangerColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (g.id != null)
                                IconButton(
                                  tooltip: 'Imprimir recibo PDF',
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.print_outlined,
                                    size: 17,
                                    color: Color(0xFF475569),
                                  ),
                                  onPressed: () => _openUrl(
                                    context,
                                    '$host/api/v1/gastos-proyecto/${g.id}/pdf',
                                    errorMessage:
                                        'No se pudo abrir el recibo PDF.',
                                    external: true,
                                  ),
                                ),
                              if (!provider.isReadonly && g.id != null)
                                IconButton(
                                  tooltip: 'Eliminar gasto',
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 17,
                                    color: AppTheme.dangerColor,
                                  ),
                                  onPressed: () =>
                                      _confirmDeleteGasto(context, provider, g),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
              ],
            );
          }),
      ],
    );
  }
}

class _GastoKpiTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _GastoKpiTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
