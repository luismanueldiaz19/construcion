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
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 350,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio:
                        1.3, // Aspect ratio to avoid vertical overflow
                  ),
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    final f = NumberFormat.currency(symbol: '\$');
                    final kpis = provider.data?['kpis'];

                    switch (index) {
                      case 0:
                        return _buildKPICard(
                          'Proyectos Activos',
                          '${kpis?['proyectos_activos'] ?? 0}',
                          Icons.business,
                          Colors.blue,
                        );
                      case 1:
                        return _buildKPICard(
                          'Rentabilidad',
                          f.format(
                            double.tryParse(
                                  kpis?['rentabilidad']?.toString() ?? '0',
                                ) ??
                                0,
                          ),
                          Icons.trending_up,
                          Colors.green,
                        );
                      case 2:
                        return _buildKPICard(
                          'Ingresos Totales',
                          f.format(
                            double.tryParse(
                                  kpis?['ingresos_totales']?.toString() ?? '0',
                                ) ??
                                0,
                          ),
                          Icons.payments,
                          Colors.teal,
                        );
                      case 3:
                        return _buildKPICard(
                          'Costos Totales',
                          f.format(
                            double.tryParse(
                                  kpis?['costos_totales']?.toString() ?? '0',
                                ) ??
                                0,
                          ),
                          Icons.money_off,
                          Colors.red,
                        );
                      case 4:
                        return _buildKPICard(
                          'Impuesto DGII (ITBIS)',
                          f.format(
                            double.tryParse(
                                  kpis?['itbis_neto']?.toString() ?? '0',
                                ) ??
                                0,
                          ),
                          Icons.account_balance,
                          Colors.orange,
                        );
                      default:
                        return const SizedBox();
                    }
                  },
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
