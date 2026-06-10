import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../models/proyecto.dart';
import '../../models/local_inventory.dart';
import '../../services/inventory_service.dart';
import '../../services/project_service.dart';

class LocalInventoryDetailsScreen extends StatefulWidget {
  final int inventoryId;
  final String inventoryName;

  const LocalInventoryDetailsScreen({
    super.key,
    required this.inventoryId,
    required this.inventoryName,
  });

  @override
  State<LocalInventoryDetailsScreen> createState() =>
      _LocalInventoryDetailsScreenState();
}

class _LocalInventoryDetailsScreenState
    extends State<LocalInventoryDetailsScreen> {
  final InventoryService _inventoryService = InventoryService();
  final ProjectService _projectService = ProjectService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _inventoryService.getLocalInventoryDetail(
        widget.inventoryId,
      );
      setState(() {
        _data = res;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar inventario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTransferDialog(dynamic material) async {
    final cantidadController = TextEditingController();
    final observacionesController = TextEditingController();

    // We combine projects and other warehouses in the destination list
    dynamic selectedDestino; // Can be Proyecto or LocalInventory
    List<dynamic> destinos = [];
    bool loadingDestinos = true;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (loadingDestinos) {
            Future.wait([
                  _projectService.getProyectos(estado: 'Activo'),
                  _inventoryService.getLocalInventories(),
                ])
                .then((results) {
                  final projects = results[0] as List<Proyecto>;
                  final localInventories = results[1] as List<LocalInventory>;

                  final list = [];
                  list.addAll(projects);
                  // Filter out the current warehouse
                  list.addAll(
                    localInventories.where(
                      (inv) => inv.id != widget.inventoryId,
                    ),
                  );

                  if (context.mounted) {
                    setDialogState(() {
                      destinos = list;
                      loadingDestinos = false;
                    });
                  }
                })
                .catchError((e) {
                  if (context.mounted) {
                    setDialogState(() => loadingDestinos = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al cargar destinos: $e')),
                    );
                  }
                });
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFF003366),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.swap_horiz,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Transferir Material',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Material: ${material['material']}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Disponible en este almacén: ${material['stock']} ${material['unidad']}',
                                    style: TextStyle(
                                      color: Colors.blue.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'DETALLES DE LA TRANSFERENCIA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                              fontSize: 11,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          loadingDestinos
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : DropdownButtonFormField<dynamic>(
                                  value: selectedDestino,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Destino (Proyecto o Almacén) *',
                                    prefixIcon: const Icon(Icons.domain),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: destinos.map((dest) {
                                    final bool isProject = dest is Proyecto;
                                    final String label = isProject
                                        ? "🚧 Proyecto: ${dest.nombre}"
                                        : "🏢 Almacén: ${dest.nameInventario}";

                                    return DropdownMenuItem<dynamic>(
                                      value: dest,
                                      child: Text(
                                        label,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: saving
                                      ? null
                                      : (v) => setDialogState(
                                          () => selectedDestino = v,
                                        ),
                                ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: cantidadController,
                            enabled: !saving,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText:
                                  'Cantidad a transferir (${material['unidad']}) *',
                              prefixIcon: const Icon(Icons.numbers),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: observacionesController,
                            enabled: !saving,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Observaciones / Motivo',
                              prefixIcon: const Icon(Icons.comment_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed:
                                  loadingDestinos ||
                                      selectedDestino == null ||
                                      saving
                                  ? null
                                  : () async {
                                      final cant =
                                          double.tryParse(
                                            cantidadController.text,
                                          ) ??
                                          0;
                                      if (cant <= 0 ||
                                          cant >
                                              double.parse(
                                                material['stock'].toString(),
                                              )) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Cantidad no válida o insuficiente',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      setDialogState(() => saving = true);

                                      final isProject =
                                          selectedDestino is Proyecto;

                                      try {
                                        await _inventoryService
                                            .registrarTransferencia({
                                              'material_id':
                                                  material['material_id'],
                                              'inventario_local_origen_id':
                                                  widget.inventoryId,
                                              'proyecto_destino_id': isProject
                                                  ? selectedDestino.id
                                                  : null,
                                              'inventario_local_destino_id':
                                                  !isProject
                                                  ? selectedDestino.id
                                                  : null,
                                              'cantidad': cant,
                                              'fecha': DateFormat(
                                                'yyyy-MM-dd',
                                              ).format(DateTime.now()),
                                              'observaciones':
                                                  observacionesController.text,
                                            });

                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          _fetchData();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Transferencia realizada con éxito',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          setDialogState(() => saving = false);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFA000),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: saving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'CONFIRMAR TRANSFERENCIA',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.inventoryName),
              Text(
                _data?['location'] ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.inventory_2_outlined),
                text: 'Balance de Stock',
              ),
              Tab(icon: Icon(Icons.history), text: 'Movimientos de Almacén'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(children: [_buildBalanceTab(), _buildMovementsTab()]),
      ),
    );
  }

  Widget _buildBalanceTab() {
    final balance = _data?['balance'] as List? ?? [];
    final f = NumberFormat.currency(symbol: '\$');

    if (balance.isEmpty) {
      return const Center(
        child: Text('No hay materiales con stock en este almacén.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.blueGrey.shade50),
            columns: const [
              DataColumn(
                label: Text(
                  'Material',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Unidad',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Entradas',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Salidas',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Stock Actual',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Último Costo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Total Valorado',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Acción',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: [
              ...balance.map((item) {
                final stock = double.tryParse(item['stock'].toString()) ?? 0;
                final entries =
                    double.tryParse(item['entradas'].toString()) ?? 0;
                final exits = double.tryParse(item['salidas'].toString()) ?? 0;
                final cost =
                    double.tryParse(item['ultimo_costo'].toString()) ?? 0;
                final total = stock * cost;

                return DataRow(
                  cells: [
                    DataCell(Text(item['material'])),
                    DataCell(Text(item['unidad'])),
                    DataCell(Text(entries.toString())),
                    DataCell(Text(exits.toString())),
                    DataCell(
                      Text(
                        stock.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    DataCell(Text(f.format(cost))),
                    DataCell(
                      Text(
                        f.format(total),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(
                      ElevatedButton.icon(
                        onPressed: stock <= 0
                            ? null
                            : () => _showTransferDialog(item),
                        icon: const Icon(Icons.swap_horiz, size: 16),
                        label: const Text(
                          'Transferir',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMovementsTab() {
    final movimientos = _data?['movimientos'] as List? ?? [];
    final f = NumberFormat.currency(symbol: '\$');

    if (movimientos.isEmpty) {
      return const Center(
        child: Text('No hay movimientos registrados para este almacén.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.blueGrey.shade50),
            columns: const [
              DataColumn(
                label: Text(
                  'Tipo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
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
                  'Material',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Cant.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Costo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: [
              ...movimientos.map((mov) {
                final isEntrada = mov['tipo'] == 'Entrada';
                final cantidad =
                    double.tryParse(mov['cantidad'].toString()) ?? 0;
                final costo = double.tryParse(mov['costo'].toString()) ?? 0;
                final total = cantidad * costo;

                return DataRow(
                  cells: [
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isEntrada
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          mov['tipo'],
                          style: TextStyle(
                            color: isEntrada
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(mov['fecha'])),
                    DataCell(
                      SizedBox(
                        width: 250,
                        child: Text(
                          mov['referencia'],
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(mov['material'])),
                    DataCell(
                      Text(
                        "${isEntrada ? '+' : '-'}$cantidad",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isEntrada ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    DataCell(Text(f.format(costo))),
                    DataCell(
                      Text(
                        f.format(total),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
