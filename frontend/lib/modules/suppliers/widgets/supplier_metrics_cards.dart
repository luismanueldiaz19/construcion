import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_theme.dart';
import '../providers/suppliers_provider.dart';

/// Franja horizontal ultra-compacta de métricas para proveedores.
///
/// Ocupa sólo ~34px de altura, reemplazando las tarjetas grandes para
/// maximizar el espacio vertical visible de la tabla.
class SupplierMetricsCards extends StatelessWidget {
  const SupplierMetricsCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SuppliersProvider>(
      builder: (context, provider, child) {
        final proveedores = provider.proveedores;
        final int total = proveedores.length;
        final int activos = proveedores.where((p) => p.active).length;
        final int inactivos = total - activos;
        final int conCredito = proveedores.where((p) => p.allowCredit).length;

        return Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _MetricItem(
                  icon: Icons.business_rounded,
                  iconColor: const Color(0xFF2563EB),
                  value: total.toString(),
                  label: 'Proveedores',
                ),
                _buildDivider(),
                _MetricItem(
                  icon: Icons.check_circle_rounded,
                  iconColor: const Color(0xFF16A34A),
                  value: activos.toString(),
                  label: 'Activos',
                  valueColor: const Color(0xFF15803D),
                ),
                _buildDivider(),
                _MetricItem(
                  icon: Icons.cancel_rounded,
                  iconColor: const Color(0xFFDC2626),
                  value: inactivos.toString(),
                  label: 'Inactivos',
                  valueColor: inactivos > 0 ? const Color(0xFFDC2626) : AppTheme.textSecondary,
                ),
                _buildDivider(),
                _MetricItem(
                  icon: Icons.credit_card_rounded,
                  iconColor: const Color(0xFFD97706),
                  value: conCredito.toString(),
                  label: 'Con Crédito',
                  valueColor: const Color(0xFFB45309),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 16,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFFCBD5E1),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Color? valueColor;

  const _MetricItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
