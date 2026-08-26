import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

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
        return Colors.green;
      case 'COSTOS':
        return Colors.orange;
      case 'GASTOS':
        return Colors.red;
      default:
        return Colors.blue;
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
            fontSize: isBold ? 13 : 12, // Reducir un punto el tamaño base
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(width: 4),
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
                  fontSize: isBold ? 15 : 13, // Reducir un punto
                  fontWeight: FontWeight.bold,
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
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              color: const Color(0xFF1A1C1E),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Resumen Anual',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow('Ventas', ventas, Colors.greenAccent),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Costos', costos, Colors.orangeAccent),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Gastos', gastos, Colors.redAccent),
                    const Divider(color: Colors.white24, height: 24),
                    _buildSummaryRow(
                      'Utilidad Neta',
                      utilidad,
                      utilidad >= 0 ? Colors.greenAccent : Colors.redAccent,
                      isBold: true,
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Margen',
                      margenUtilidad,
                      utilidad >= 0 ? Colors.greenAccent : Colors.redAccent,
                      isPercentage: true,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                  sections: pieChartData.map((data) {
                    double total =
                        double.tryParse(data['total'].toString()) ?? 0;
                    return PieChartSectionData(
                      color: _getColorForModule(data['modulo']),
                      value: total,
                      title:
                          '${data['modulo']}\n${currencyFormatter.format(total)}',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
