import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:construccion_erp/core/constants.dart'
    as construccion_erp_constants;
import '../../../services/nomina_service.dart';

class PayrollDetailsDialog extends StatefulWidget {
  final int payrollId;

  const PayrollDetailsDialog({super.key, required this.payrollId});

  @override
  State<PayrollDetailsDialog> createState() => _PayrollDetailsDialogState();
}

class _PayrollDetailsDialogState extends State<PayrollDetailsDialog> {
  final NominaService _service = NominaService();
  bool _isLoading = true;
  List<dynamic> _summary = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final res = await _service.getPayrollEmployeeSummary(widget.payrollId);
      setState(() {
        _summary = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');

    return Dialog(
      child: Container(
        width: 900,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Desglose de Empleados',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text('Imprimir Vouchers'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final url = Uri.parse(
                          '${construccion_erp_constants.host}/api/v1/payrolls/${widget.payrollId}/vouchers/pdf',
                        );
                        if (await url_launcher.canLaunchUrl(url)) {
                          await url_launcher.launchUrl(
                            url,
                            mode: url_launcher.LaunchMode.externalApplication,
                          );
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No se pudo abrir el PDF.'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Text(
                    'Error: $_error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            else if (_summary.isEmpty)
              const Expanded(
                child: Center(child: Text('No hay empleados en esta nómina.')),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        Colors.grey.shade200,
                      ),
                      columns: const [
                        DataColumn(label: Text('Identificación')),
                        DataColumn(label: Text('Nombre Empleado')),
                        DataColumn(label: Text('Salario Bruto'), numeric: true),
                        DataColumn(label: Text('Retención TSS / AFP'), numeric: true),
                        DataColumn(label: Text('Retención ISR'), numeric: true),
                        DataColumn(label: Text('Otras Ded.'), numeric: true),
                        DataColumn(label: Text('Neto a Pagar'), numeric: true),
                      ],
                      rows: _summary.map((row) {
                        return DataRow(
                          cells: [
                            DataCell(Text(row['identification_number'] ?? '')),
                            DataCell(
                              Text('${row['first_name']} ${row['last_name']}'),
                            ),
                            DataCell(Text(fmt.format(row['total_gross']))),
                            DataCell(Text(fmt.format(row['total_tss']))),
                            DataCell(Text(fmt.format(row['total_isr']))),
                            DataCell(Text(fmt.format(row['other_deductions']))),
                            DataCell(
                              Text(
                                fmt.format(row['total_net']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
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
