import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectInventoryDetailsScreen extends StatefulWidget {
  final int proyectoId;
  final String proyectoNombre;

  const ProjectInventoryDetailsScreen({
    super.key,
    required this.proyectoId,
    required this.proyectoNombre,
  });

  @override
  State<ProjectInventoryDetailsScreen> createState() =>
      _ProjectInventoryDetailsScreenState();
}

class _ProjectInventoryDetailsScreenState
    extends State<ProjectInventoryDetailsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getInventarioDetalleProyecto(
        widget.proyectoId,
      );
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Inventario: ${widget.proyectoNombre}'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) async {
                final url = Uri.parse(
                  '${_apiService.baseUrl}/inventario-proyectos/${widget.proyectoId}/pdf?tipo=$value',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se pudo abrir el PDF')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.picture_as_pdf),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'balance',
                  child: Text('PDF: Balance de Stock'),
                ),
                const PopupMenuItem(
                  value: 'movimientos',
                  child: Text('PDF: Movimientos'),
                ),
                const PopupMenuItem(
                  value: 'completo',
                  child: Text('PDF: Reporte Completo'),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Balance de Stock'),
              Tab(text: 'Movimientos'),
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
      return const Center(child: Text('No hay materiales en este proyecto.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
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
                'Balance',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Últ. Costo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Inversión',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Acciones',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: [
            ...balance.map((item) {
              final stock = double.tryParse(item['stock'].toString()) ?? 0;
              final costo =
                  double.tryParse(item['ultimo_costo'].toString()) ?? 0;
              return DataRow(
                cells: [
                  DataCell(Text(item['material'])),
                  DataCell(Text(item['unidad'])),
                  DataCell(Text(item['entradas'].toString())),
                  DataCell(Text(item['salidas'].toString())),
                  DataCell(
                    Text(
                      stock.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  DataCell(Text(f.format(costo))),
                  DataCell(
                    Text(
                      f.format(stock * costo),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      onPressed: stock > 0
                          ? () => _showConsumoDialog(item)
                          : null,
                      tooltip: 'Registrar Salida (Consumo)',
                    ),
                  ),
                ],
              );
            }),
            // Fila de Gran Total
            DataRow(
              color: WidgetStateProperty.all(Colors.green.shade50),
              cells: [
                const DataCell(
                  Text(
                    'TOTAL GENERAL',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const DataCell(Text('')),
                const DataCell(Text('')),
                const DataCell(Text('')),
                const DataCell(Text('')),
                const DataCell(Text('')),
                DataCell(
                  Text(
                    f.format(
                      balance.fold(
                        0.0,
                        (sum, item) =>
                            sum +
                            ((double.tryParse(item['stock'].toString()) ?? 0) *
                                (double.tryParse(
                                      item['ultimo_costo'].toString(),
                                    ) ??
                                    0)),
                      ),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ),
                const DataCell(Text('')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showConsumoDialog(dynamic material) async {
    final cantidadController = TextEditingController();
    int? selectedSubpartidaId;
    List<dynamic> subpartidas = [];
    bool loading = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (loading) {
            _apiService.getPartidas(widget.proyectoId).then((partidas) {
              // Aplanamos subpartidas para el dropdown
              List<dynamic> allSub = [];
              for (var p in partidas) {
                if (p['subpartidas'] != null) {
                  for (var s in p['subpartidas']) {
                    allSub.add({
                      'id': s['id'],
                      'nombre': "${p['descripcion']} -> ${s['descripcion']}",
                    });
                  }
                }
              }
              setDialogState(() {
                subpartidas = allSub;
                loading = false;
              });
            });
          }

          return AlertDialog(
            title: Text('Salida de Material: ${material['material']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Disponible: ${material['stock']} ${material['unidad']}'),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedSubpartidaId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Destino (Sub-partida)',
                    border: OutlineInputBorder(),
                  ),
                  items: subpartidas
                      .map(
                        (s) => DropdownMenuItem<int>(
                          value: s['id'],
                          child: Text(
                            s['nombre'],
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedSubpartidaId = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: cantidadController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Cantidad (${material['unidad']})',
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
                onPressed: loading || selectedSubpartidaId == null
                    ? null
                    : () async {
                        final cant =
                            double.tryParse(cantidadController.text) ?? 0;
                        if (cant <= 0 ||
                            cant > double.parse(material['stock'].toString())) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Cantidad no válida o insuficiente',
                              ),
                            ),
                          );
                          return;
                        }

                        try {
                          await _apiService.registrarConsumo({
                            'proyecto_id': widget.proyectoId,
                            'material_id': material['material_id'],
                            'subpartida_id': selectedSubpartidaId,
                            'cantidad': cant,
                            'fecha': DateFormat(
                              'yyyy-MM-dd',
                            ).format(DateTime.now()),
                          });
                          Navigator.pop(context);
                          _fetchData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Salida registrada con éxito'),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                child: const Text('Confirmar Salida'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMovementsTab() {
    final movimientos = _data?['movimientos'] as List? ?? [];
    final f = NumberFormat.currency(symbol: '\$');

    if (movimientos.isEmpty) {
      return const Center(child: Text('No hay movimientos registrados.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
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
              final cantidad = double.tryParse(mov['cantidad'].toString()) ?? 0;
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
                  DataCell(Text(mov['referencia'])),
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
            // Fila de Total para Movimientos
            DataRow(
              color: WidgetStateProperty.all(Colors.blueGrey.shade50),
              cells: [
                const DataCell(
                  Text(
                    'TOTAL ACUMULADO',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const DataCell(Text('')),
                const DataCell(Text('')),
                const DataCell(Text('')),
                const DataCell(Text('')),
                const DataCell(Text('')),
                DataCell(
                  Text(
                    f.format(
                      movimientos.fold(0.0, (sum, mov) {
                        final cant =
                            double.tryParse(mov['cantidad'].toString()) ?? 0;
                        final cost =
                            double.tryParse(mov['costo'].toString()) ?? 0;
                        return sum + (cant * cost);
                      }),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
