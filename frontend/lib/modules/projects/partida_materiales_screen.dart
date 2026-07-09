import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/partida.dart';
import '../../../models/consumo_proyecto.dart';
import '../../../core/auth_provider.dart';
import '../../../services/inventory_service.dart';
import 'providers/project_details_provider.dart';

class PartidaMaterialesScreen extends StatefulWidget {
  final Partida partida;
  final List<ConsumoProyecto> consumos;

  const PartidaMaterialesScreen({
    super.key,
    required this.partida,
    required this.consumos,
  });

  @override
  State<PartidaMaterialesScreen> createState() =>
      _PartidaMaterialesScreenState();
}

class _PartidaMaterialesScreenState extends State<PartidaMaterialesScreen> {
  late List<ConsumoProyecto> consumosPartida;

  @override
  void initState() {
    super.initState();
    _filterConsumos();
  }

  void _filterConsumos() {
    final subpartidaIds = widget.partida.subpartidas.map((s) => s.id).toList();
    consumosPartida = widget.consumos
        .where(
          (c) =>
              c.subpartidaId != null && subpartidaIds.contains(c.subpartidaId),
        )
        .toList();
  }

  void _deleteConsumo(ConsumoProyecto consumo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Consumo'),
        content: const Text(
          '¿Está seguro de eliminar este consumo? Esta acción regresará el material al inventario y revertirá el gasto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await InventoryService().deleteConsumo(consumo.id!);
        setState(() {
          consumosPartida.removeWhere((c) => c.id == consumo.id);
          widget.consumos.removeWhere((c) => c.id == consumo.id);
        });
        if (mounted) {
          Provider.of<ProjectDetailsProvider>(context, listen: false).refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Consumo eliminado correctamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final authProvider = Provider.of<AuthProvider>(context);
    final isMaster =
        authProvider.username?.toLowerCase() == 'master' ||
        authProvider.username?.toLowerCase() == 'ludeveloper';

    double totalMateriales = consumosPartida.fold(
      0.0,
      (sum, c) => sum + c.total,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Materiales Consumidos - ${widget.partida.descripcion}',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1C1E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: consumosPartida.isEmpty
                ? const Center(
                    child: Text(
                      'No hay materiales registrados para esta partida.',
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth,
                                ),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    Colors.grey.shade100,
                                  ),
                                  columns: [
                                    const DataColumn(
                                      label: Text(
                                        'Fecha',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const DataColumn(
                                      label: Text(
                                        'Subpartida',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const DataColumn(
                                      label: Text(
                                        'Material',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const DataColumn(
                                      label: Text(
                                        'Cantidad',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const DataColumn(
                                      label: Text(
                                        'Costo Unit.',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const DataColumn(
                                      label: Text(
                                        'Total',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isMaster)
                                      const DataColumn(
                                        label: Text(
                                          'Acciones',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                  rows: consumosPartida.map((c) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(dateFormat.format(c.fecha)),
                                        ),
                                        DataCell(
                                          Text(c.subpartidaNombre ?? 'N/A'),
                                        ),
                                        DataCell(
                                          Text(
                                            c.materialNombre ??
                                                'Material #${c.materialId}',
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '${c.cantidad} ${c.materialUnidad ?? ''}',
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            f.format(
                                              c.costoUnitario ??
                                                  (c.cantidad > 0
                                                      ? c.total / c.cantidad
                                                      : 0),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(f.format(c.total))),
                                        if (isMaster)
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.redAccent,
                                                    size: 20,
                                                  ),
                                                  tooltip: 'Eliminar',
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  onPressed: () =>
                                                      _deleteConsumo(c),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Subtotal Materiales: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  f.format(totalMateriales),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFFC62828),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
