import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../widgets/app_status_badge.dart';
import '../../../widgets/app_text_field.dart';
import '../providers/project_form_provider.dart';

/// Paso 3: Resumen general del proyecto y desglose de costos indirectos integrado a la pantalla.
class ProjectReviewStep extends StatelessWidget {
  final NumberFormat formatter;

  const ProjectReviewStep({super.key, required this.formatter});

  static final List<TextInputFormatter> _decimalFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectFormProvider>();
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sección 1: Resumen rápido de los datos ingresados
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen del Proyecto',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Verifica los datos antes de registrar la obra',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AppStatusBadge(
              label: provider.estado.toUpperCase(),
              type: AppStatusType.pending,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _InfoChip(
              icon: Icons.apartment_rounded,
              label: 'Proyecto',
              value: provider.nombreController.text.trim().isEmpty
                  ? 'Sin nombre'
                  : provider.nombreController.text.trim(),
            ),
            _InfoChip(
              icon: Icons.person_outline_rounded,
              label: 'Cliente',
              value: provider.selectedClient?.name ?? 'Sin asignar',
            ),
            _InfoChip(
              icon: Icons.location_on_outlined,
              label: 'Ubicación',
              value: provider.ubicacionController.text.trim().isEmpty
                  ? 'No especificada'
                  : provider.ubicacionController.text.trim(),
            ),
            _InfoChip(
              icon: Icons.calendar_today_outlined,
              label: 'Fechas',
              value:
                  '${provider.fechaInicio != null ? dateFmt.format(provider.fechaInicio!) : '--'} → ${provider.fechaFin != null ? dateFmt.format(provider.fechaFin!) : '--'}',
            ),
            _InfoChip(
              icon: Icons.list_alt_rounded,
              label: 'Alcance',
              value:
                  '${provider.partidas.length} partidas · ${provider.totalSubpartidas} ítems',
            ),
          ],
        ),
        const Divider(height: 24, color: Color(0xFFE2E8F0)),

        // Sección 2: Costos Indirectos y Total Final
        const Text(
          'Costos Indirectos e Impuestos',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Usa el botón automático para calcular porcentajes sugeridos',
          style: TextStyle(
            fontSize: 11.5,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _SummaryRow(
          label: 'Sub-total Directo (Partidas)',
          value: formatter.format(provider.subtotal),
          isHeader: true,
        ),
        const Divider(height: 20, color: Color(0xFFE2E8F0)),
        _CostInputRow(
          label: 'Transporte (Sugerido 4%)',
          controller: provider.transporteController,
          onSuggest: provider.suggestTransporte,
          onChanged: (_) => provider.forceUpdate(),
          formatters: _decimalFormatters,
        ),
        const SizedBox(height: 8),
        _CostInputRow(
          label: 'ITBIS (Sugerido 18%)',
          controller: provider.itbisController,
          onSuggest: provider.suggestItbis,
          onChanged: (_) => provider.forceUpdate(),
          formatters: _decimalFormatters,
        ),
        const SizedBox(height: 8),
        _CostInputRow(
          label: 'Supervisión Técnica',
          controller: provider.supervisionController,
          onChanged: (_) => provider.forceUpdate(),
          formatters: _decimalFormatters,
        ),
        const SizedBox(height: 8),
        _CostInputRow(
          label: 'Otros Costos Indirectos',
          controller: provider.otrosCostosController,
          onChanged: (_) => provider.forceUpdate(),
          formatters: _decimalFormatters,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.accentColor.withValues(alpha: 0.25),
            ),
          ),
          child: _SummaryRow(
            label: 'TOTAL FINAL ESTIMADO',
            value: formatter.format(provider.totalFinal),
            isTotal: true,
            valueColor: AppTheme.accentColor,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _CostInputRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback? onSuggest;
  final ValueChanged<String> onChanged;
  final List<TextInputFormatter> formatters;

  const _CostInputRow({
    required this.label,
    required this.controller,
    this.onSuggest,
    required this.onChanged,
    required this.formatters,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        if (onSuggest != null)
          IconButton(
            tooltip: 'Calcular sugerido',
            onPressed: onSuggest,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.auto_fix_high_rounded,
              color: AppTheme.ledhouseBlue,
              size: 18,
            ),
          ),
        const SizedBox(width: 6),
        SizedBox(
          width: 135,
          child: AppTextField(
            controller: controller,
            prefixText: '\$ ',
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: formatters,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHeader;
  final bool isTotal;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isHeader = false,
    this.isTotal = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 13.5 : (isHeader ? 13 : 12),
              fontWeight:
                  isTotal || isHeader ? FontWeight.bold : FontWeight.normal,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 17 : (isHeader ? 14.5 : 13),
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
