import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/app_theme.dart';

class ResumenAnualWidget extends StatelessWidget {
  final double ventas;
  final double costos;
  final double gastos;
  final double utilidad;
  final double margenUtilidad;
  final List<dynamic> pieChartData;
  final NumberFormat currencyFormatter;

  const ResumenAnualWidget({
    super.key,
    required this.ventas,
    required this.costos,
    required this.gastos,
    required this.utilidad,
    required this.margenUtilidad,
    required this.pieChartData,
    required this.currencyFormatter,
  });

  Color _getColorForModule(String modulo) {
    switch (modulo.toUpperCase()) {
      case 'VENTAS':
        return AppTheme.successColor;
      case 'COSTOS':
        return const Color(0xFFFB8C00); // Naranja
      case 'GASTOS':
        return AppTheme.dangerColor;
      default:
        return AppTheme.ledhouseBlue;
    }
  }

  Widget _buildSummaryRow(
    String label,
    double value,
    Color color, {
    bool isPercentage = false,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isPercentage
                    ? '${value.toStringAsFixed(2)}%'
                    : currencyFormatter.format(value),
                style: TextStyle(
                  color: color,
                  fontSize: isBold ? 16 : 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta Oscura de Resumen
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Resumen Anual',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSummaryRow('Ventas', ventas, AppTheme.successColor),
                const SizedBox(height: 12),
                _buildSummaryRow('Costos', costos, const Color(0xFFFB8C00)),
                const SizedBox(height: 12),
                _buildSummaryRow('Gastos', gastos, AppTheme.dangerColor),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(
                    color: Colors.white.withOpacity(0.15),
                    height: 1,
                  ),
                ),
                _buildSummaryRow(
                  'Utilidad Neta',
                  utilidad,
                  utilidad >= 0 ? AppTheme.successColor : AppTheme.dangerColor,
                  isBold: true,
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  'Margen',
                  margenUtilidad,
                  utilidad >= 0 ? AppTheme.successColor : AppTheme.dangerColor,
                  isPercentage: true,
                  isBold: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Gráfico de Pastel
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: pieChartData.map((data) {
                  double total = double.tryParse(data['total'].toString()) ?? 0;
                  final color = _getColorForModule(data['modulo']);
                  return PieChartSectionData(
                    color: color,
                    value: total,
                    title:
                        '${data['modulo']}\n${currencyFormatter.format(total)}',
                    radius: 70,
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
