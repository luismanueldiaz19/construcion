import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class GananciaNetaChartWidget extends StatelessWidget {
  final Map<String, Map<String, double>> monthlyData;
  final List<String> sortedMonths;
  final NumberFormat currencyFormatter;

  const GananciaNetaChartWidget({
    super.key,
    required this.monthlyData,
    required this.sortedMonths,
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

  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots = sortedMonths.asMap().entries.map((entry) {
      double val = monthlyData[entry.value]?['GANANCIA'] ?? 0;
      return FlSpot(entry.key.toDouble(), val);
    }).toList();

    double maxY = 0;
    double minY = 0;
    for (var spot in spots) {
      if (spot.y > maxY) maxY = spot.y;
      if (spot.y < minY) minY = spot.y;
    }
    // Add some padding to max and min values
    maxY = maxY + (maxY.abs() * 0.05); // Reducido para que la curva suba más
    minY = minY < 0 ? minY - (minY.abs() * 0.05) : 0;
    if (maxY == 0) maxY = 100;

    final lineBarData = LineChartBarData(
      spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
      isCurved: true,
      curveSmoothness: 0.2,
      preventCurveOverShooting: true,
      color: Colors.blueAccent,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 3,
            color: Colors.white,
            strokeWidth: 2,
            strokeColor: Colors.blueAccent,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            Colors.blueAccent.withOpacity(0.3),
            Colors.blueAccent.withOpacity(0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );

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
                      'Evolución de Ganancias Neta',
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
              'Ganancia limpia calculada después de costos y gastos',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(
              height: 32,
            ), // Espacio extra para los tooltips fijos arriba
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    minY: minY,
                    maxY: maxY,
                    showingTooltipIndicators: spots.asMap().entries.map((
                      entry,
                    ) {
                      return ShowingTooltipIndicators([
                        LineBarSpot(lineBarData, 0, entry.value),
                      ]);
                    }).toList(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true, // Líneas verticales activadas
                      verticalInterval: 1, // Línea en cada punto de mes
                      horizontalInterval: (maxY - minY) / 5 > 0
                          ? (maxY - minY) / 5
                          : 100,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.brown.shade400,
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: Colors.blue.shade400,
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
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
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize:
                              35, // Aumentado ligeramente para el K sin decimales
                          getTitlesWidget: (value, meta) {
                            if (value == meta.max) return const Text('');
                            if (value == meta.min && meta.min == 0) {
                              return const Text('');
                            }
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
                    ),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      enabled: false, // Desactivar toques porque ya están fijos
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => const Color(
                          0xFF1E293B,
                        ), // Contenedor oscuro elegante
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        tooltipBorderRadius: BorderRadius.circular(8),
                        tooltipMargin: 8,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((LineBarSpot touchedSpot) {
                            return LineTooltipItem(
                              currencyFormatter.format(touchedSpot.y),
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [lineBarData],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
