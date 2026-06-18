import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../models/compra.dart';
import '../../services/purchase_service.dart';

class ReceptionScreen extends StatefulWidget {
  const ReceptionScreen({super.key});

  @override
  State<ReceptionScreen> createState() => _ReceptionScreenState();
}

class _ReceptionScreenState extends State<ReceptionScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  List<Compra> _comprasPendientes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _purchaseService.getComprasPendientes();
      setState(() {
        _comprasPendientes = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Recepción de Materiales en Obra'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _comprasPendientes.isEmpty
          ? const Center(child: Text('No hay compras pendientes de recepción'))
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _comprasPendientes.length,
              itemBuilder: (context, index) {
                final c = _comprasPendientes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "FACTURA #${c.id}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                            Text(
                              c.fecha,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const Divider(),
                        Text(
                          "Proveedor: ${c.proveedor?.name ?? 'Desconocido'}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Proyecto: ${c.proyecto?.nombre ?? 'Desconocido'}",
                          style: const TextStyle(color: Colors.blue),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Materiales a recibir:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        ...(c.detalles ?? []).map((d) {
                          double total = double.parse(d['cantidad'].toString());
                          double recibido = double.parse(
                            (d['cantidad_recibida'] ?? 0).toString(),
                          );
                          return Text(
                            "• ${d['material']['nombre']}: $recibido / $total ${d['material']['unidad']}",
                            style: TextStyle(
                              color: recibido >= total
                                  ? Colors.green
                                  : (recibido > 0
                                        ? Colors.orange
                                        : Colors.black87),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total: ${f.format(c.total)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _confirmarRecepcion(c),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Confirmar Recepción'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _confirmarRecepcion(Compra compra) {
    final personController = TextEditingController();
    final Map<int, TextEditingController> itemControllers = {};

    for (var d in compra.detalles ?? []) {
      double pendiente =
          double.parse(d['cantidad'].toString()) -
          double.parse((d['cantidad_recibida'] ?? 0).toString());
      if (pendiente > 0) {
        itemControllers[d['id']] = TextEditingController(
          text: pendiente.toString(),
        );
      }
    }

    if (itemControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos los materiales ya han sido recibidos'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recibir Materiales - Factura #${compra.id}'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('¿Quién recibe los materiales?'),
                const SizedBox(height: 8),
                TextField(
                  controller: personController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Receptor',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cantidades Recibidas:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Divider(),
                ...itemControllers.entries.map((entry) {
                  final d = (compra.detalles ?? []).firstWhere(
                    (element) => element['id'] == entry.key,
                  );
                  double total = double.parse(d['cantidad'].toString());
                  double yaRecibido = double.parse(
                    (d['cantidad_recibida'] ?? 0).toString(),
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d['material']['nombre'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Pendiente: ${total - yaRecibido} ${d['material']['unidad']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: entry.value,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Cantidad',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (personController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor ingrese quién recibe'),
                  ),
                );
                return;
              }

              List<Map<String, dynamic>> items = [];
              itemControllers.forEach((id, controller) {
                double qty = double.tryParse(controller.text) ?? 0;
                if (qty > 0) {
                  items.add({'compra_detalle_id': id, 'cantidad': qty});
                }
              });

              if (items.isEmpty) return;

              try {
                await _purchaseService.registrarRecepcion({
                  'compra_id': compra.id,
                  'fecha': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  'recibido_por': personController.text,
                  'items': items,
                });
                Navigator.pop(context);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Inventario actualizado correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Dar Entrada'),
          ),
        ],
      ),
    );
  }
}
