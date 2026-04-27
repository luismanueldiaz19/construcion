import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class ReceptionScreen extends StatefulWidget {
  const ReceptionScreen({super.key});

  @override
  State<ReceptionScreen> createState() => _ReceptionScreenState();
}

class _ReceptionScreenState extends State<ReceptionScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _comprasPendientes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getComprasPendientes();
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
      appBar: AppBar(title: const Text('Recepción de Materiales en Obra')),
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
                              "FACTURA #${c['id']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                            Text(
                              c['fecha'],
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const Divider(),
                        Text(
                          "Proveedor: ${c['proveedor']['nombre']}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Proyecto: ${c['proyecto']['nombre']}",
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
                        ...(c['detalles'] as List)
                            .map(
                              (d) => Text(
                                "• ${d['cantidad']} ${d['material']['unidad']} de ${d['material']['nombre']}",
                              ),
                            )
                            .toList(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total: ${f.format(double.parse(c['total'].toString()))}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _confirmarRecepcion(c['id']),
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

  void _confirmarRecepcion(int compraId) {
    final personController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Recepción'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Quién recibe los materiales en el proyecto?'),
            const SizedBox(height: 16),
            TextField(
              controller: personController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Receptor',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (personController.text.isEmpty) return;
              await _apiService.registrarRecepcion({
                'compra_id': compraId,
                'fecha': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                'recibido_por': personController.text,
              });
              Navigator.pop(context);
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Inventario actualizado correctamente'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Dar Entrada'),
          ),
        ],
      ),
    );
  }
}
