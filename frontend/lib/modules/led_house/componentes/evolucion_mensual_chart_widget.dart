import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

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
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                        color: Colors.blueAccent,
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
                      ),
                    ),
                  ],
                ),
                Icon(Icons.more_horiz, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Resumen de ventas, costos y gastos a lo largo del año',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green, 'Ventas'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.orange, 'Costos'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.red, 'Gastos'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxBarY > 0 ? maxBarY * 1.2 : 100,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(
                    enabled: false, // Valores fijos
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.transparent,
                      tooltipPadding: const EdgeInsets.all(0),
                      tooltipMargin: 2,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        if (rod.toY == 0) return null; // No mostrar si es 0
                        return BarTooltipItem(
                          _formatoMontoCorta(rod.toY),
                          TextStyle(
                            color: rod.color, // Color de la respectiva barra
                            fontWeight: FontWeight.bold,
                            fontSize: 8, // Lo más pequeño legible
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
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                mesStr,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('');
                          return Text(
                            _formatoMontoCorta(value),
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
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
                    drawVerticalLine: true,
                    horizontalInterval: maxBarY > 0 ? (maxBarY * 1.2) / 5 : 100,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                        dashArray: [5, 5],
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
                          color: Colors.green,
                          width: 8,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        BarChartRodData(
                          toY: values['COSTOS'] ?? 0,
                          color: Colors.orange,
                          width: 8,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        BarChartRodData(
                          toY: values['GASTOS'] ?? 0,
                          color: Colors.red,
                          width: 8,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
