import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../providers/project_form_provider.dart';

class ProjectReviewStep extends StatelessWidget {
  final NumberFormat formatter;

  const ProjectReviewStep({super.key, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectFormProvider>();
    final subtotal = provider.subtotal;
    final total = provider.totalFinal;

    return Column(
      children: [
        _buildSectionTitle(
          Icons.summarize_outlined,
          'Resumen de Costos Indirectos',
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildSummaryItem(
                  'Sub-total Directo',
                  subtotal,
                  formatter,
                  isHeader: true,
                ),
                const Divider(height: 32),
                _buildCostInputRow(
                  'Transporte (Sugerido 4%)',
                  provider.transporteController,
                  provider.suggestTransporte,
                  formatter,
                  provider,
                ),
                _buildCostInputRow(
                  'ITBIS (Sugerido 18%)',
                  provider.itbisController,
                  provider.suggestItbis,
                  formatter,
                  provider,
                ),
                _buildCostInputRow(
                  'Supervisión Técnica',
                  provider.supervisionController,
                  null,
                  formatter,
                  provider,
                ),
                _buildCostInputRow(
                  'Otros Costos Indirectos',
                  provider.otrosCostosController,
                  null,
                  formatter,
                  provider,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildSummaryItem(
                    'TOTAL FINAL ESTIMADO',
                    total,
                    formatter,
                    isTotal: true,
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostInputRow(
    String label,
    TextEditingController controller,
    VoidCallback? onSuggest,
    NumberFormat f,
    ProjectFormProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (onSuggest != null)
            IconButton(
              onPressed: onSuggest,
              icon: const Icon(
                Icons.auto_fix_high,
                color: Colors.blue,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (v) => provider.forceUpdate(),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                prefixText: '\$ ',
                isDense: true,
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.05),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    double value,
    NumberFormat f, {
    bool isHeader = false,
    bool isTotal = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : (isHeader ? 14 : 12),
            fontWeight: isTotal || isHeader ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          f.format(value),
          style: TextStyle(
            fontSize: isTotal ? 20 : (isHeader ? 16 : 14),
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
