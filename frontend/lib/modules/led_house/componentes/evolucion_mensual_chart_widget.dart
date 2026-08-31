import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/app_theme.dart';

class EvolucionMensualChartWidget extends StatelessWidget {
  final Map<String, Map<String, double>> monthlyData;
  final List<String> sortedMonths;
  final double maxBarY;
  final NumberFormat currencyFormatter;

  const EvolucionMensualChartWidget({
    super.key,
    required this.monthlyData,
    required this.sortedMonths,
    required this.maxBarY,
    required this.currencyFormatter,
  });

  String _formatoMontoCorta(double monto) {
    if (monto >= 1000000) {
      return '\$${(monto / 1000000).toStringAsFixed(1)}M';
    } else if (monto >= 1000) {
      return '\$${(monto / 1000).toStringAsFixed(0)}K';
    }
    return '\$${monto.toStringAsFixed(0)}';
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.ledhouseBlue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Evolución Mensual',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.more_horiz,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Resumen de ventas, costos y gastos a lo largo del año',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(AppTheme.successColor, 'Ventas'),
              const SizedBox(width: 20),
              _buildLegendItem(const Color(0xFFFB8C00), 'Costos'),
              const SizedBox(width: 20),
              _buildLegendItem(AppTheme.dangerColor, 'Gastos'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxBarY > 0 ? maxBarY * 1.2 : 100,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  enabled: false, // Valores fijos
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.transparent,
                    tooltipPadding: const EdgeInsets.all(0),
                    tooltipMargin: 4,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      if (rod.toY == 0) return null; // No mostrar si es 0
                      return BarTooltipItem(
                        _formatoMontoCorta(rod.toY),
                        TextStyle(
                          color: rod.color, // Color de la respectiva barra
                          fontWeight: FontWeight.bold,
                          fontSize: 9, // Ligeramente más grande
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < sortedMonths.length) {
                          String mesStr = sortedMonths[value.toInt()];
                          final parts = mesStr.split('-');
                          if (parts.length == 2) {
                            const months = [
                              'Ene',
                              'Feb',
                              'Mar',
                              'Abr',
                              'May',
                              'Jun',
                              'Jul',
                              'Ago',
                              'Sep',
                              'Oct',
                              'Nov',
                              'Dic',
                            ];
                            int monthIndex = int.tryParse(parts[1]) ?? 0;
                            if (monthIndex >= 1 && monthIndex <= 12) {
                              mesStr = months[monthIndex - 1];
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              mesStr,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 34,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        return Text(
                          _formatoMontoCorta(value),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine:
                      false, // Quitar líneas verticales para un look más limpio
                  horizontalInterval: maxBarY > 0 ? (maxBarY * 1.2) / 5 : 100,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: sortedMonths.asMap().entries.map((entry) {
                  int index = entry.key;
                  var values = monthlyData[entry.value]!;
                  return BarChartGroupData(
                    x: index,
                    barsSpace: 4,
                    showingTooltipIndicators: [0, 1, 2],
                    barRods: [
                      BarChartRodData(
                        toY: values['VENTAS'] ?? 0,
                        color: AppTheme.successColor,
                        width: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: values['COSTOS'] ?? 0,
                        color: const Color(0xFFFB8C00), // Naranja
                        width: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: values['GASTOS'] ?? 0,
                        color: AppTheme.dangerColor,
                        width: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
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
