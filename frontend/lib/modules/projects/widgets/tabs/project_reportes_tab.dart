import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants.dart';
import '../../providers/project_details_provider.dart';

class ProjectReportesTab extends StatelessWidget {
  const ProjectReportesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectDetailsProvider>(context);
    final f = NumberFormat.currency(symbol: '\$');
    final proyecto = provider.proyecto!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informes y Reportes del Proyecto',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Descarga y consulta la información financiera y operativa del proyecto.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),

          _buildReportItem(
            'Reporte General del Proyecto (PDF)',
            'Incluye avance físico consolidado, desglose de presupuestos por partida, gastos acumulados y balance de fondos.',
            Icons.picture_as_pdf,
            Colors.redAccent,
            () async {
              final url = Uri.parse('$host/reports/proyecto/${proyecto.id}/pdf');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No se pudo abrir el reporte PDF')),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 16),

          _buildReportItem(
            'Estado de Resultados del Proyecto',
            'Informe analítico de ingresos netos devengados, egresos reales de caja y materiales, y cálculo de utilidad/ganancia real.',
            Icons.assessment,
            Colors.green,
            () async {
              try {
                final data = await provider.accountingService.getEstadoResultados(proyectoId: proyecto.id);
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Estado de Resultados del Proyecto'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ingresos Totales: ${f.format(double.tryParse(data['ingresos']?.toString() ?? '0') ?? 0)}'),
                          const SizedBox(height: 8),
                          Text('Costos Totales: ${f.format(double.tryParse(data['costos']?.toString() ?? '0') ?? 0)}'),
                          const Divider(height: 24),
                          Text(
                            'Utilidad: ${f.format(double.tryParse(data['utilidad']?.toString() ?? '0') ?? 0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
                      ],
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al cargar estado de resultados: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(description),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
