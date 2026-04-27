import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'purchase_form_screen.dart';
import 'suppliers_screen.dart';
import 'reception_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _materialesGlobal = [];
  List<dynamic> _inventarioProyectos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final global = await _apiService.getMateriales();
      final proyectos = await _apiService.getInventarioPorProyecto();
      setState(() {
        _materialesGlobal = global;
        _inventarioProyectos = proyectos;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Almacén e Inventarios'),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SuppliersScreen(),
                ),
              ),
              icon: const Icon(Icons.people_outline, color: Colors.blue),
              label: const Text('Proveedores'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReceptionScreen(),
                  ),
                );
                _loadData();
              },
              icon: const Icon(
                Icons.local_shipping_outlined,
                color: Colors.orange,
              ),
              label: const Text('Recibir en Obra'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PurchaseFormScreen(),
                  ),
                );
                if (result == true) _loadData();
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Nueva Compra'),
            ),
            const SizedBox(width: 24),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Stock por Proyecto'),
              Tab(text: 'Inventario Global'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [_buildProjectInventory(), _buildGlobalInventory()],
              ),
      ),
    );
  }

  Widget _buildGlobalInventory() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _materialesGlobal.length,
      itemBuilder: (context, index) {
        final m = _materialesGlobal[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.inventory_2, color: Color(0xFF003366)),
            title: Text(
              m['nombre'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Unidad: ${m['unidad']}'),
            trailing: Text(
              'Stock: ${m['stock_global']}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showConsumoDialog(dynamic proj, dynamic material) async {
    final cantidadController = TextEditingController();
    int? selectedPartidaId;
    List<dynamic> partidas = [];
    bool loadingPartidas = true;

    // Cargar partidas del proyecto
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (loadingPartidas) {
            _apiService.getPartidas(proj['id']).then((data) {
              setDialogState(() {
                partidas = data;
                loadingPartidas = false;
              });
            });
          }

          return AlertDialog(
            title: Text('Consumir ${material['material']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Disponible en obra: ${material['cantidad_total']} ${material['unidad']}',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedPartidaId,
                  decoration: const InputDecoration(
                    labelText: 'Partida / Rubro',
                    border: OutlineInputBorder(),
                  ),
                  items: partidas
                      .map(
                        (p) => DropdownMenuItem<int>(
                          value: p['id'],
                          child: Text(p['nombre']),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedPartidaId = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: cantidadController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Cantidad a usar (${material['unidad']})',
                    border: const OutlineInputBorder(),
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
                onPressed: loadingPartidas || selectedPartidaId == null
                    ? null
                    : () async {
                        final cant =
                            double.tryParse(cantidadController.text) ?? 0;
                        if (cant <= 0 ||
                            cant >
                                double.parse(
                                  material['cantidad_total'].toString(),
                                )) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cantidad no válida')),
                          );
                          return;
                        }

                        try {
                          await _apiService.registrarConsumo({
                            'proyecto_id': proj['id'],
                            'material_id': material['material_id'] ?? 1,
                            'subpartida_id': selectedPartidaId,
                            'cantidad': cant,
                            'fecha': DateFormat(
                              'yyyy-MM-dd',
                            ).format(DateTime.now()),
                          });
                          Navigator.pop(context);
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Consumo registrado y contabilidad actualizada',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                child: const Text('Registrar Consumo'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProjectInventory() {
    final f = NumberFormat.currency(symbol: '\$');
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _inventarioProyectos.length,
      itemBuilder: (context, index) {
        final proj = _inventarioProyectos[index];
        final materials = proj['materiales'] as List? ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: const Icon(Icons.apartment, color: Colors.orange),
            title: Text(
              proj['nombre'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${materials.length} materiales en obra'),
            children: [
              if (materials.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No hay materiales recibidos en este proyecto aún',
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                      3: FixedColumnWidth(50),
                    },
                    children: [
                      const TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(4),
                            child: Text(
                              'Material',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(4),
                            child: Text(
                              'Cant.',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(4),
                            child: Text(
                              'Inversión',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(padding: EdgeInsets.all(4), child: Text('')),
                        ],
                      ),
                      ...materials
                          .map(
                            (m) => TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Text(
                                    "${m['material']} (${m['unidad']})",
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Text("${m['cantidad_total']}"),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Text(
                                    f.format(
                                      double.parse(
                                        m['inversion_total'].toString(),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child:
                                      (double.tryParse(
                                                m['cantidad_total']
                                                        ?.toString() ??
                                                    '0',
                                              ) ??
                                              0) >
                                          0
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              _showConsumoDialog(proj, m),
                                          tooltip: 'Consumir material',
                                        )
                                      : const Icon(
                                          Icons.block,
                                          color: Colors.grey,
                                          size: 20,
                                        ), // Icono de bloqueado si es 0
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
