import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/constants.dart';
import '../../../../services/accounting_service.dart';
import '../../../../widgets/app_alert.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_empty_state.dart';
import '../../../../widgets/app_status_badge.dart';
import '../providers/project_detail_provider.dart';

/// Pestaña 7 (Resultados): Estado de Resultados compacto, integrado y sin overflows.
class DetailResultadosTab extends StatefulWidget {
  const DetailResultadosTab({super.key});

  @override
  State<DetailResultadosTab> createState() => _DetailResultadosTabState();
}

class _DetailResultadosTabState extends State<DetailResultadosTab> {
  final AccountingService _accountingService = AccountingService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;
  int? _loadedProyectoId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.read<ProjectDetailProvider>().proyecto?.id;
    if (id != null && id != _loadedProyectoId) {
      _loadedProyectoId = id;
      _loadData(id);
    }
  }

  Future<void> _loadData(int proyectoId) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data =
          await _accountingService.getEstadoResultados(proyectoId: proyectoId);
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo cargar el estado de resultados: $e';
          _isLoading = false;
        });
      }
    }
  }

  double _toDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '0') ?? 0.0;

  String _formatSigned(double val, NumberFormat fmt) {
    if (val.abs() < 0.005) return fmt.format(0);
    if (val < 0) return '(${fmt.format(val.abs())})';
    return fmt.format(val);
  }

  Future<void> _openPdf(BuildContext context, int proyectoId) async {
    final uri =
        Uri.parse('$host/reports/estado-resultados/pdf?proyecto_id=$proyectoId');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      AppAlert.showToast(
        context,
        'No se pudo abrir el PDF del Estado de Resultados.',
        type: AppAlertType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectDetailProvider>();
    final proyecto = provider.proyecto!;

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppTheme.accentColor,
          ),
        ),
      );
    }

    if (_error != null || _data == null) {
      return AppEmptyState(
        icon: Icons.analytics_outlined,
        title: 'Error al cargar resultados',
        description: _error,
        actionText: 'Reintentar',
        onAction: () => _loadData(proyecto.id!),
      );
    }

    final fmt = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);
    final dateFmt = DateFormat('dd/MM/yyyy');

    final ingresos = _toDouble(_data!['ingresos']);
    final costos = _toDouble(_data!['costos']);
    final gastosOp = _toDouble(_data!['gastos']);
    final utilidadBruta = _toDouble(_data!['utilidad_bruta']);
    final utilidadNeta = _toDouble(_data!['utilidad_neta']);
    final margenNeto = ingresos > 0 ? (utilidadNeta / ingresos * 100) : 0.0;

    final presupuesto = provider.presupuestoTotal;
    final cobrado = provider.totalCobrado;
    final saldo = provider.saldoPendiente;
    final avanceFinanciero =
        presupuesto > 0 ? (cobrado / presupuesto * 100).clamp(0.0, 100.0) : 0.0;
    final avanceFisico = provider.avanceFisico;

    final periodo = [
      if (proyecto.fechaInicio != null) dateFmt.format(proyecto.fechaInicio!),
      if (proyecto.fechaFin != null) dateFmt.format(proyecto.fechaFin!),
    ].join(' - ');

    return RefreshIndicator(
      onRefresh: () => _loadData(proyecto.id!),
      color: AppTheme.accentColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera compacta sin overflow
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estado de Resultados',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (periodo.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Período: $periodo',
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
                AppButton(
                  text: 'Imprimir',
                  icon: Icons.print_outlined,
                  size: AppButtonSize.compact,
                  variant: AppButtonVariant.outlined,
                  borderRadius: 8,
                  onPressed: () => _openPdf(context, proyecto.id!),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // KPIs 2x2 + Margen
            Row(
              children: [
                Expanded(
                  child: _ResultKpiTile(
                    label: 'Ingresos Totales',
                    value: _formatSigned(ingresos, fmt),
                    color: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ResultKpiTile(
                    label: 'Costos Totales',
                    value: _formatSigned(costos, fmt),
                    color: AppTheme.dangerColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ResultKpiTile(
                    label: 'Utilidad Bruta',
                    value: _formatSigned(utilidadBruta, fmt),
                    color: utilidadBruta >= 0
                        ? const Color(0xFF2563EB)
                        : AppTheme.dangerColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ResultKpiTile(
                    label: 'Utilidad Neta',
                    value: _formatSigned(utilidadNeta, fmt),
                    color: utilidadNeta >= 0
                        ? const Color(0xFF16A34A)
                        : AppTheme.dangerColor,
                    badge: '${margenNeto.toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
            const Divider(height: 22, color: Color(0xFFE2E8F0)),

            // Sección: Información del Contrato y Cobros
            const Text(
              'Contrato y Cobros',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _LineItem(
              label: 'Monto Total del Proyecto',
              value: fmt.format(presupuesto),
              isBold: true,
            ),
            _LineItem(
              label: 'Total Cobrado al Cliente',
              value: fmt.format(cobrado),
              valueColor: const Color(0xFF16A34A),
            ),
            _LineItem(
              label: 'Balance Pendiente de Cobro',
              value: fmt.format(saldo),
              valueColor: const Color(0xFFD97706),
              isBold: true,
            ),
            _LineItem(
              label: 'Ingresos Contables (Sin Imp.)',
              value: fmt.format(ingresos),
              valueColor: const Color(0xFF2563EB),
            ),
            const SizedBox(height: 10),
            _ProgressRow(
              label: 'Avance Financiero (Cobrado / Proyecto)',
              percent: avanceFinanciero,
              color: const Color(0xFF2563EB),
            ),
            const SizedBox(height: 8),
            _ProgressRow(
              label: 'Avance Físico (Ejecución Real)',
              percent: avanceFisico,
              color: const Color(0xFF0D9488),
            ),
            const Divider(height: 22, color: Color(0xFFE2E8F0)),

            // Sección: Resumen Contable (P&L)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Resumen Contable',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                AppStatusBadge(
                  label: utilidadNeta >= 0 ? 'GANANCIA' : 'PÉRDIDA',
                  type: utilidadNeta >= 0
                      ? AppStatusType.active
                      : AppStatusType.inactive,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _LineItem(
              label: '(+) Total Ingresos',
              value: fmt.format(ingresos),
              valueColor: const Color(0xFF16A34A),
            ),
            _LineItem(
              label: '(-) Total Costos Directos',
              value: _formatSigned(-costos, fmt),
              valueColor: AppTheme.dangerColor,
            ),
            _LineItem(
              label: '(=) Utilidad Bruta',
              value: _formatSigned(utilidadBruta, fmt),
              isBold: true,
            ),
            if (gastosOp > 0)
              _LineItem(
                label: '(-) Gastos Operativos',
                value: _formatSigned(-gastosOp, fmt),
                valueColor: AppTheme.dangerColor,
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: (utilidadNeta >= 0
                        ? const Color(0xFF16A34A)
                        : AppTheme.dangerColor)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (utilidadNeta >= 0
                          ? const Color(0xFF16A34A)
                          : AppTheme.dangerColor)
                      .withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'UTILIDAD NETA',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatSigned(utilidadNeta, fmt),
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: utilidadNeta >= 0
                            ? const Color(0xFF16A34A)
                            : AppTheme.dangerColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultKpiTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String? badge;

  const _ResultKpiTile({
    required this.label,
    required this.value,
    required this.color,
    this.badge,
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
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              if (badge != null)
                Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
            ],
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

class _LineItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _LineItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double percent;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${percent.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: (percent / 100.0).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
