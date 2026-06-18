import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants.dart';
import '../../providers/project_details_provider.dart';
import '../cards/detail_stat_card.dart';

class ProjectPagosTab extends StatelessWidget {
  final VoidCallback onAddPago;

  const ProjectPagosTab({super.key, required this.onAddPago});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectDetailsProvider>(context);
    final f = NumberFormat.currency(symbol: '\$');
    final proyecto = provider.proyecto!;
    final pagos = provider.pagos;

    final totalConImpuestos =
        double.tryParse(
          proyecto.totalPresupuestoConGlobales?.toString() ?? '0',
        ) ??
        0;
    final totalCobrado = proyecto.totalCobrado ?? 0;
    final saldoPendiente = totalConImpuestos - totalCobrado;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DetailStatCard(
                  title: 'Monto Total Presupuestado',
                  value: f.format(totalConImpuestos),
                  color: const Color(0xFF003366),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DetailStatCard(
                  title: 'Total Cobrado al Cliente',
                  value: f.format(totalCobrado),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DetailStatCard(
                  title: 'Saldo Pendiente de Cobro',
                  value: f.format(saldoPendiente),
                  color: saldoPendiente > 0.01 ? Colors.orange : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Historial de Cobros a Clientes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (pagos.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Text('No hay cobros registrados para este proyecto.'),
              ),
            )
          else
            ...pagos.map((item) {
              final monto = double.tryParse(item['monto'].toString()) ?? 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade100),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['entidad'] ?? 'Cliente General',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        f.format(monto),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(item['concepto'] ?? 'Abono de Proyecto'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item['fecha'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.payment,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item['metodo_pago'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    onPressed: () => _openPagoPdf(context, item['id']),
                    tooltip: 'Imprimir Recibo',
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  void _openPagoPdf(BuildContext context, int id) async {
    final url = Uri.parse('$host/api/v1/pagos-historial/Cobro/$id/pdf');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el PDF del recibo')),
        );
      }
    }
  }
}
