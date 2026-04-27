import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'dashboard_provider.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: '\$');

    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(child: Text('Error: ${provider.error}'));
        }

        final kpis = provider.data?['kpis'];

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard Gerencial',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 1200
                      ? 4
                      : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildKPICard(
                      'Proyectos Activos',
                      '${kpis?['proyectos_activos'] ?? 0}',
                      Icons.business,
                      Colors.blue,
                    ),
                    _buildKPICard(
                      'Rentabilidad',
                      f.format(
                        double.tryParse(
                              kpis?['rentabilidad']?.toString() ?? '0',
                            ) ??
                            0,
                      ),
                      Icons.trending_up,
                      Colors.green,
                    ),
                    _buildKPICard(
                      'Ingresos Totales',
                      f.format(
                        double.tryParse(
                              kpis?['ingresos_totales']?.toString() ?? '0',
                            ) ??
                            0,
                      ),
                      Icons.payments,
                      Colors.teal,
                    ),
                    _buildKPICard(
                      'Costos Totales',
                      f.format(
                        double.tryParse(
                              kpis?['costos_totales']?.toString() ?? '0',
                            ) ??
                            0,
                      ),
                      Icons.money_off,
                      Colors.red,
                    ),
                    _buildKPICard(
                      'Impuesto DGII (ITBIS)',
                      f.format(
                        double.tryParse(
                              kpis?['itbis_neto']?.toString() ?? '0',
                            ) ??
                            0,
                      ),
                      Icons.account_balance,
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
