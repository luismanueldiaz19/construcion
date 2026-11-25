import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/constants.dart';
import '../../../../widgets/app_alert.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_empty_state.dart';
import '../../../../widgets/app_status_badge.dart';
import '../providers/project_detail_provider.dart';

/// Pestaña 4 (Pagos / Cobros): KPIs financieros, progreso de cobro e historial integrado.
class DetailPagosTab extends StatelessWidget {
  const DetailPagosTab({super.key});

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectDetailProvider>();
    final proyecto = provider.proyecto!;
    final pagos = provider.pagos;
    final currencyFmt = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);

    final presupuesto = provider.presupuestoTotal;
    final cobrado = provider.totalCobrado;
    final saldo = provider.saldoPendiente;
    final pctCobrado =
        presupuesto > 0 ? (cobrado / presupuesto * 100).clamp(0.0, 100.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPIs compactos superiores
        Row(
          children: [
            Expanded(
              child: _PagoKpiTile(
                label: 'Presupuestado',
                value: currencyFmt.format(presupuesto),
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PagoKpiTile(
                label: 'Cobrado',
                value: currencyFmt.format(cobrado),
                color: const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _PagoKpiTile(
          label: 'Saldo Pendiente de Cobro',
          value: currencyFmt.format(saldo),
          color: saldo > 0.01 ? const Color(0xFFD97706) : const Color(0xFF64748B),
        ),
        const SizedBox(height: 12),

        // Barra de progreso de recaudación
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progreso de Cobros',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              '${pctCobrado.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF16A34A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: pctCobrado / 100.0,
            minHeight: 6,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
          ),
        ),
        const Divider(height: 22, color: Color(0xFFE2E8F0)),

        // Encabezado + Botón imprimir historial
        Row(
          children: [
            const Expanded(
              child: Text(
                'Historial de Cobros',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            AppStatusBadge(
              label: '${pagos.length} ${pagos.length == 1 ? 'cobro' : 'cobros'}',
              type: AppStatusType.active,
            ),
            const SizedBox(width: 8),
            AppButton(
              text: 'Imprimir',
              icon: Icons.print_outlined,
              size: AppButtonSize.compact,
              variant: AppButtonVariant.outlined,
              borderRadius: 8,
              onPressed: () => _openUrl(
                context,
                '$host/reports/pagos-cliente/pdf?proyecto_id=${proyecto.id}',
                errorMessage: 'No se pudo abrir el historial de cobros.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Lista limpia de cobros
        if (pagos.isEmpty)
          const AppEmptyState(
            icon: Icons.payments_outlined,
            title: 'Sin cobros registrados',
            description:
                'Aún no se han registrado cobros o abonos del cliente para este proyecto.',
          )
        else
          ...pagos.map((item) {
            final monto = double.tryParse(item['monto'].toString()) ?? 0.0;
            final entidad = (item['entidad']?.toString().trim() ?? '');
            final concepto = (item['concepto']?.toString().trim() ?? '');
            final fecha = item['fecha']?.toString() ?? '';
            final metodo = item['metodo_pago']?.toString() ?? '';
            final id = item['id'];

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.payments_outlined,
                          size: 15,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entidad.isEmpty ? 'Cliente General' : entidad,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              concepto.isEmpty ? 'Abono de Proyecto' : concepto,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Wrap(
                              spacing: 8,
                              runSpacing: 2,
                              children: [
                                if (fecha.isNotEmpty)
                                  Text(
                                    fecha,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                if (metodo.isNotEmpty)
                                  Text(
                                    '· $metodo',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFmt.format(monto),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                          if (id != null)
                            IconButton(
                              tooltip: 'Imprimir recibo PDF',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.picture_as_pdf_outlined,
                                size: 17,
                                color: AppTheme.accentColor,
                              ),
                              onPressed: () => _openUrl(
                                context,
                                '$host/api/v1/pagos-historial/Cobro/$id/pdf',
                                errorMessage:
                                    'No se pudo abrir el PDF del recibo.',
                                external: true,
                              ),
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

class _PagoKpiTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PagoKpiTile({
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
