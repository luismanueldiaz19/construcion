import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants.dart';
import '../../../services/accounting_service.dart';
import 'pago_obligacion_dialog.dart';

class ObligacionesScreen extends StatefulWidget {
  const ObligacionesScreen({super.key});

  @override
  State<ObligacionesScreen> createState() => _ObligacionesScreenState();
}

class _ObligacionesScreenState extends State<ObligacionesScreen> {
  final AccountingService _service = AccountingService();
  bool _isLoading = true;
  List<dynamic> _obligaciones = [];
  String? _error;

  // Historial
  bool _isLoadingHistorial = false;
  List<dynamic> _historial = [];
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadHistorial();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _service.getObligaciones();
      setState(() {
        _obligaciones = res;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHistorial() async {
    setState(() => _isLoadingHistorial = true);
    try {
      final start = _startDate != null
          ? DateFormat('yyyy-MM-dd').format(_startDate!)
          : null;
      final end = _endDate != null
          ? DateFormat('yyyy-MM-dd').format(_endDate!)
          : null;

      final res = await _service.getHistorialPagosObligaciones(
        startDate: start,
        endDate: end,
      );
      setState(() {
        _historial = res;
        _isLoadingHistorial = false;
      });
    } catch (e) {
      setState(() => _isLoadingHistorial = false);
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadHistorial();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Obligaciones Fiscales'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pendientes por Pagar'),
              Tab(text: 'Historial de Pagos'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _loadData();
                _loadHistorial();
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [_buildPendientesTab(fmt), _buildHistorialTab(fmt)],
        ),
      ),
    );
  }

  Widget _buildPendientesTab(NumberFormat fmt) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Text(
          'Error: $_error',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Consulta y paga tus obligaciones fiscales y retenciones.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _obligaciones.length,
              itemBuilder: (context, index) {
                final ob = _obligaciones[index];
                final double saldo = (ob['saldo'] as num?)?.toDouble() ?? 0.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            ob['nombre'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text('Cuenta: ${ob['codigo']}'),
                          trailing: Text(
                            'RD\$ ${fmt.format(saldo)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: saldo > 0 ? Colors.red.shade700 : Colors.green,
                            ),
                          ),
                        ),
                        const Divider(),
                        OverflowBar(
                          alignment: MainAxisAlignment.end,
                          spacing: 8,
                          overflowSpacing: 8,
                          children: [
                            if (ob['detalle'] != null)
                              TextButton.icon(
                                icon: const Icon(Icons.info_outline, size: 16),
                                label: const Text('Detalles'),
                                onPressed: () {
                                  final detalle = ob['detalle'];
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: Text('Detalle de ${ob['nombre']}'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('ITBIS Cobrado (Pasivo): RD\$ ${fmt.format(detalle['itbis_cobrado'])}'),
                                          const SizedBox(height: 8),
                                          Text('ITBIS Pagado (Activo/Crédito): -RD\$ ${fmt.format(detalle['itbis_pagado'])}'),
                                          const Divider(),
                                          Text(
                                            'Neto a Pagar: RD\$ ${fmt.format(detalle['total_neto'])}',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cerrar'),
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.payment, size: 16),
                              label: const Text('Pagar'),
                              onPressed: saldo > 0
                                  ? () async {
                                      final bool? paid = await showDialog(
                                        context: context,
                                        builder: (_) => PagoObligacionDialog(
                                          cuentaId: ob['cuenta_id'],
                                          nombre: ob['nombre'],
                                          saldo: saldo,
                                        ),
                                      );
                                      if (paid == true) {
                                        _loadData();
                                        _loadHistorial();
                                      }
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorialTab(NumberFormat fmt) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(
                  _startDate == null
                      ? 'Filtrar por Fechas'
                      : '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                ),
                onPressed: _selectDateRange,
              ),
              if (_startDate != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                    _loadHistorial();
                  },
                ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Exportar PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  String url =
                      '$host/api/v1/contabilidad/obligaciones/historial/pdf?';
                  if (_startDate != null && _endDate != null) {
                    final s = DateFormat('yyyy-MM-dd').format(_startDate!);
                    final e = DateFormat('yyyy-MM-dd').format(_endDate!);
                    url += 'start_date=$s&end_date=$e';
                  }

                  try {
                    launchUrl(Uri.parse(url));
                  } catch (e) {
                    debugPrint('No se pudo abrir el PDF');
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingHistorial
              ? const Center(child: CircularProgressIndicator())
              : _historial.isEmpty
              ? const Center(
                  child: Text('No hay pagos registrados en este periodo'),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(
                        Colors.grey.shade100,
                      ),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Fecha',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Referencia',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Cuenta Pagada',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Origen (Banco)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Monto (RD\$)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      rows: _historial.map((asiento) {
                        final detalles = asiento['detalles'] as List;

                        dynamic detallePago;
                        dynamic detalleBanco;

                        for (var d in detalles) {
                          final debe =
                              double.tryParse(d['debe'].toString()) ?? 0.0;
                          final haber =
                              double.tryParse(d['haber'].toString()) ?? 0.0;
                          final cuenta = d['cuenta'];
                          final tipo = cuenta != null ? cuenta['tipo'] : null;

                          if (debe > 0 &&
                              tipo == 'Pasivo' &&
                              detallePago == null) {
                            detallePago = d;
                          }
                          if (haber > 0 &&
                              tipo == 'Activo' &&
                              detalleBanco == null) {
                            detalleBanco = d;
                          }
                        }

                        final nombreObligacion =
                            detallePago != null && detallePago['cuenta'] != null
                            ? detallePago['cuenta']['nombre']
                            : 'Obligación';
                        final nombreBanco =
                            detalleBanco != null &&
                                detalleBanco['cuenta'] != null
                            ? detalleBanco['cuenta']['nombre']
                            : 'Banco';
                        final montoPagado = detalleBanco != null
                            ? (double.tryParse(
                                    detalleBanco['haber'].toString(),
                                  ) ??
                                  0.0)
                            : 0.0;

                        return DataRow(
                          cells: [
                            DataCell(Text(asiento['fecha'] ?? '')),
                            DataCell(Text(asiento['glosa'] ?? '')),
                            DataCell(Text(nombreObligacion)),
                            DataCell(Text(nombreBanco)),
                            DataCell(
                              Text(
                                fmt.format(montoPagado),
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
    );
  }
}
