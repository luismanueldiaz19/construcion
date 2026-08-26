import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../providers/ledhouse_provider.dart';
import '../componentes/add_registro_dialog_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class LedhouseDetallesCuentas extends StatefulWidget {
  const LedhouseDetallesCuentas({super.key});

  @override
  State<LedhouseDetallesCuentas> createState() =>
      _LedhouseDetallesCuentasState();
}

class _LedhouseDetallesCuentasState extends State<LedhouseDetallesCuentas> {
  final ScrollController _tableScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tableScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _downloadPdf() async {
    final provider = Provider.of<LedhouseProvider>(context, listen: false);

    if (provider.registros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay registros para generar el reporte.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final filteredRegistros = provider.registros.where((r) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery;
      return r.codigoCuenta.toLowerCase().contains(query) ||
          r.descripcionDeCuenta.toLowerCase().contains(query) ||
          r.modulo.toLowerCase().contains(query) ||
          r.fecha.toLowerCase().contains(query) ||
          r.monto.toString().toLowerCase().contains(query) ||
          (r.registedBy?.toLowerCase().contains(query) ?? false);
    }).toList();

    if (filteredRegistros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay registros filtrados para generar el reporte.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final ids = filteredRegistros.map((r) => r.id).join(',');
    final queryParams = <String>['ids=$ids'];

    final queryString = '?${queryParams.join('&')}';
    final urlStr = '$host/api/v1/ledhouse/estado-resultado/pdf$queryString';
    final url = Uri.parse(urlStr);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se pudo abrir el PDF.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de Cuentas'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          const SizedBox(width: 8),
          IconButton(
            onPressed: _downloadPdf,
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            tooltip: 'Descargar PDF',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddRegistroDialogWidget(),
          ).then((_) {
            // Recargar datos al cerrar el diálogo por si hubo cambios
            Provider.of<LedhouseProvider>(
              context,
              listen: false,
            ).fetchEstadoResultados();
          });
        },
        backgroundColor: const Color(0xFF0C336B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<LedhouseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.registros.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildDataTable(provider),
          );
        },
      ),
    );
  }

  Widget _buildDataTable(LedhouseProvider provider) {
    if (provider.registros.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text('No hay registros encontrados.')),
        ),
      );
    }

    final currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detalle de Registros',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  width: 300,
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar (código, desc, módulo...)',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Color(0xFF0C336B),
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  controller: _tableScrollController,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    controller: _tableScrollController,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        headingRowColor: WidgetStateProperty.all(
                          Colors.grey.shade200,
                        ),
                        dividerThickness: 0.5,
                        dataRowMaxHeight: 50,
                        columns: const [
                          DataColumn(label: Text('Fecha')),
                          DataColumn(label: Text('Código')),
                          DataColumn(label: Text('Módulo')),
                          DataColumn(label: Text('Descripción')),
                          DataColumn(label: Text('Monto')),
                          DataColumn(label: Text('Registrado por')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows: provider.registros
                            .where((r) {
                              if (_searchQuery.isEmpty) return true;
                              final q = _searchQuery;
                              return r.codigoCuenta.toLowerCase().contains(q) ||
                                  r.descripcionDeCuenta.toLowerCase().contains(
                                    q,
                                  ) ||
                                  r.modulo.toLowerCase().contains(q) ||
                                  r.fecha.toLowerCase().contains(q) ||
                                  r.monto.toString().contains(q) ||
                                  (r.registedBy ?? '').toLowerCase().contains(
                                    q,
                                  );
                            })
                            .toList()
                            .asMap()
                            .entries
                            .map((entry) {
                              int index = entry.key;
                              var r = entry.value;
                              return DataRow(
                                color: WidgetStateProperty.resolveWith<Color?>((
                                  Set<WidgetState> states,
                                ) {
                                  if (states.contains(WidgetState.hovered)) {
                                    return Colors.blue.withOpacity(0.1);
                                  }
                                  return index.isEven
                                      ? Colors.white
                                      : Colors.grey.shade50;
                                }),
                                cells: [
                                  DataCell(Text(r.fecha)),
                                  DataCell(Text(r.codigoCuenta)),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getColorForModule(
                                          r.modulo,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        r.modulo,
                                        style: TextStyle(
                                          color: _getColorForModule(r.modulo),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(r.descripcionDeCuenta)),
                                  DataCell(
                                    Text(
                                      currencyFormatter.format(r.monto),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(r.registedBy ?? 'N/A')),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                            size: 20,
                                          ),
                                          tooltip: 'Editar',
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) =>
                                                  AddRegistroDialogWidget(
                                                    registro: r,
                                                  ),
                                            ).then((_) {
                                              provider.fetchEstadoResultados();
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          tooltip: 'Eliminar',
                                          onPressed: () =>
                                              _confirmarEliminacion(
                                                context,
                                                provider,
                                                r.id,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            })
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForModule(String modulo) {
    switch (modulo.toUpperCase()) {
      case 'VENTAS':
        return Colors.green;
      case 'COSTOS':
        return Colors.orange;
      case 'GASTOS':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _confirmarEliminacion(
    BuildContext context,
    LedhouseProvider provider,
    int id,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este registro? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.deleteRegistro(id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Registro eliminado'),
                    backgroundColor: Colors.green,
                  ),
                );
                provider.fetchEstadoResultados();
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${provider.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
