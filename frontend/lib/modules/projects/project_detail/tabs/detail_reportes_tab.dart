import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/constants.dart';
import '../../../../widgets/app_alert.dart';
import '../../../../widgets/app_button.dart';
import '../providers/project_detail_provider.dart';

/// Pestaña 8 (Reportes): Centro compacto de descarga de reportes PDF del proyecto.
class DetailReportesTab extends StatelessWidget {
  const DetailReportesTab({super.key});

  Future<void> _openPdf(
    BuildContext context,
    String rawUrl,
    String title,
  ) async {
    final uri = Uri.parse(rawUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      AppAlert.showToast(
        context,
        'No se pudo abrir: $title',
        type: AppAlertType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final proyecto = context.watch<ProjectDetailProvider>().proyecto!;
    final id = proyecto.id;

    final reports = [
      (
        title: 'Reporte General del Proyecto',
        desc: 'Avance físico consolidado, presupuesto por partida, gastos y balance.',
        icon: Icons.picture_as_pdf_outlined,
        color: AppTheme.accentColor,
        url: '$host/reports/proyecto/$id/pdf',
      ),
      (
        title: 'Estado de Resultados (P&L)',
        desc: 'Ingresos devengados, costos directos, gastos operativos y utilidad neta.',
        icon: Icons.analytics_outlined,
        color: const Color(0xFF16A34A),
        url: '$host/reports/estado-resultados/pdf?proyecto_id=$id',
      ),
      (
        title: 'Reporte de Gastos del Proyecto',
        desc: 'Historial detallado de mano de obra, alquileres y otros egresos.',
        icon: Icons.shopping_bag_outlined,
        color: const Color(0xFFD97706),
        url: '$host/reports/gastos/pdf?proyecto_id=$id',
      ),
      (
        title: 'Historial de Cobros al Cliente',
        desc: 'Relación de abonos recibidos, métodos de pago y saldo pendiente.',
        icon: Icons.payments_outlined,
        color: const Color(0xFF2563EB),
        url: '$host/reports/pagos-cliente/pdf?proyecto_id=$id',
      ),
      (
        title: 'Reporte de Compras del Proyecto',
        desc: 'Facturas de proveedores, subtotales, ITBIS y NCF registrados.',
        icon: Icons.shopping_cart_outlined,
        color: const Color(0xFF7C3AED),
        url: '$host/reports/compras/pdf?proyecto_id=$id',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Informes y Reportes PDF',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Descarga y consulta los documentos financieros y operativos de esta obra.',
          style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
        ),
        const Divider(height: 18, color: Color(0xFFE2E8F0)),
        ...reports.map(
          (r) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: r.color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: Icon(r.icon, size: 18, color: r.color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.title,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            r.desc,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      text: 'PDF',
                      icon: Icons.open_in_new_rounded,
                      size: AppButtonSize.compact,
                      variant: AppButtonVariant.outlined,
                      borderRadius: 8,
                      onPressed: () => _openPdf(context, r.url, r.title),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
            ],
          ),
        ),
      ],
    );
  }
}
