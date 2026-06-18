import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants.dart';
import '../../providers/project_details_provider.dart';
import '../cards/detail_stat_card.dart';
import '../../gasto_proyecto_dialog.dart';
import '../gasto_card.dart';

class ProjectGastosTab extends StatelessWidget {
  const ProjectGastosTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectDetailsProvider>(context);
    final f = NumberFormat.currency(symbol: '\$');
    final gastos = provider.gastos;

    final double totalGastado = gastos.fold(0.0, (sum, g) => sum + g.monto);
    final double moGastado = gastos
        .where((g) => g.tipoGasto.contains('Mano de Obra'))
        .fold(0.0, (sum, g) => sum + g.monto);
    final double alquilerGastado = gastos
        .where((g) => g.tipoGasto.contains('Alquiler'))
        .fold(0.0, (sum, g) => sum + g.monto);
    final double otrosGastado = totalGastado - moGastado - alquilerGastado;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final bool useGrid = constraints.maxWidth > 700;
              if (useGrid) {
                return Row(
                  children: [
                    Expanded(child: DetailStatCard(title: 'Total Gastado', value: f.format(totalGastado), color: Colors.redAccent)),
                    const SizedBox(width: 16),
                    Expanded(child: DetailStatCard(title: 'Mano de Obra', value: f.format(moGastado), color: Colors.orange)),
                    const SizedBox(width: 16),
                    Expanded(child: DetailStatCard(title: 'Alquiler de Equipos', value: f.format(alquilerGastado), color: Colors.purple)),
                    const SizedBox(width: 16),
                    Expanded(child: DetailStatCard(title: 'Otros Egresos', value: f.format(otrosGastado), color: Colors.cyan)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: DetailStatCard(title: 'Total Gastado', value: f.format(totalGastado), color: Colors.redAccent)),
                        const SizedBox(width: 12),
                        Expanded(child: DetailStatCard(title: 'Mano de Obra', value: f.format(moGastado), color: Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: DetailStatCard(title: 'Alquiler', value: f.format(alquilerGastado), color: Colors.purple)),
                        const SizedBox(width: 12),
                        Expanded(child: DetailStatCard(title: 'Otros', value: f.format(otrosGastado), color: Colors.cyan)),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Historial de Gastos (MO / Alquiler / Otros)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
              ),
              const SizedBox(width: 12),
              if (provider.proyecto!.estado == 'Activo')
                ElevatedButton.icon(
                  onPressed: () => _showGastoDialog(context, provider),
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('Registrar Gasto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (gastos.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Text('No hay gastos registrados en este proyecto.'),
              ),
            )
          else
            ...gastos.map((g) {
              return GastoCard(gasto: g, onPrint: () => _openGastoPdf(context, g.id!));
            }).toList(),
        ],
      ),
    );
  }

  void _showGastoDialog(BuildContext context, ProjectDetailsProvider provider) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => GastoProyectoDialog(proyecto: provider.proyecto!),
    );
    if (result == true) {
      provider.refresh();
    }
  }

  Future<void> _openGastoPdf(BuildContext context, int id) async {
    final url = Uri.parse('$host/api/v1/gastos-proyecto/$id/pdf');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el recibo PDF')),
        );
      }
    }
  }
}
