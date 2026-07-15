import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Text(
          'Error: $_error',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final fmt = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Obligaciones Fiscales'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Padding(
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
                    child: ListTile(
                      title: Text(
                        ob['nombre'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Cuenta: ${ob['codigo']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'RD\$ ${fmt.format(saldo)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: saldo > 0
                                  ? Colors.red.shade700
                                  : Colors.green,
                            ),
                          ),
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
                          const SizedBox(width: 8),
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
                                    }
                                  }
                                : null, // Disable if balance is 0 or less
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
      ),
    );
  }
}
