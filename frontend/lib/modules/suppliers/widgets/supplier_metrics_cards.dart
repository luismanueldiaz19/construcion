import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_theme.dart';
import '../providers/suppliers_provider.dart';

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

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = (constraints.maxWidth - 48) / 4;
              final bool useGrid = constraints.maxWidth < 750;

              if (useGrid) {
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.8,
                  children: [
                    _buildPremiumMetricCard('Proveedores Totales', total.toString(), Icons.domain_rounded, Colors.blueAccent),
                    _buildPremiumMetricCard('Activos', activos.toString(), Icons.check_circle_rounded, Colors.teal),
                    _buildPremiumMetricCard('Inactivos', inactivos.toString(), Icons.cancel_rounded, Colors.redAccent),
                    _buildPremiumMetricCard('Con Crédito', conCredito.toString(), Icons.credit_card_rounded, Colors.orangeAccent),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _buildPremiumMetricCard(
                      'Proveedores Totales',
                      total.toString(),
                      Icons.domain_rounded,
                      Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: cardWidth,
                    child: _buildPremiumMetricCard(
                      'Activos',
                      activos.toString(),
                      Icons.check_circle_rounded,
                      Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: cardWidth,
                    child: _buildPremiumMetricCard(
                      'Inactivos',
                      inactivos.toString(),
                      Icons.cancel_rounded,
                      Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: cardWidth,
                    child: _buildPremiumMetricCard(
                      'Con Crédito',
                      conCredito.toString(),
                      Icons.credit_card_rounded,
                      Colors.orangeAccent,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPremiumMetricCard(
    String label,
    String value,
    IconData icon,
    Color primaryColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Decorative background circle
            Positioned(
              right: -15,
              top: -15,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: 0.04),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
