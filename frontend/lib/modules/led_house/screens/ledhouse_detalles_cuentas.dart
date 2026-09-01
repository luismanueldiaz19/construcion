import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../providers/ledhouse_provider.dart';
import '../componentes/add_registro_dialog_widget.dart';
import '../componentes/dialog_confimacion_delete.dart';
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
  String? _selectedMonth;
  String? _selectedModulo;

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
      bool matchSearch = true;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery;
        matchSearch =
            r.codigoCuenta.toLowerCase().contains(query) ||
            r.descripcionDeCuenta.toLowerCase().contains(query) ||
            r.modulo.toLowerCase().contains(query) ||
            r.fecha.toLowerCase().contains(query) ||
            r.monto.toString().toLowerCase().contains(query) ||
            (r.registedBy?.toLowerCase().contains(query) ?? false);
      }

      bool matchMonth = true;
      if (_selectedMonth != null) {
        final monthPart = r.fecha.split('-').length >= 2
            ? r.fecha.split('-')[1]
            : null;
        matchMonth = monthPart == _selectedMonth;
      }

      bool matchModulo = true;
      if (_selectedModulo != null) {
        matchModulo = r.modulo.toUpperCase() == _selectedModulo;
      }

      return matchSearch && matchMonth && matchModulo;
    }).toList();

    filteredRegistros.sort((a, b) {
      int weight(String modulo) {
        switch (modulo.toUpperCase()) {
          case 'VENTAS':
            return 1;
          case 'COSTOS':
            return 2;
          case 'GASTOS':
            return 3;
          default:
            return 4;
        }
      }

      return weight(a.modulo).compareTo(weight(b.modulo));
    });

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: IconButton(
              onPressed: _downloadPdf,
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              tooltip: 'Descargar PDF',
            ),
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

    final filteredRegistros = provider.registros.where((r) {
      bool matchSearch = true;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery;
        matchSearch =
            r.codigoCuenta.toLowerCase().contains(q) ||
            r.descripcionDeCuenta.toLowerCase().contains(q) ||
            r.modulo.toLowerCase().contains(q) ||
            r.fecha.toLowerCase().contains(q) ||
            r.monto.toString().contains(q) ||
            (r.registedBy ?? '').toLowerCase().contains(q);
      }

      bool matchMonth = true;
      if (_selectedMonth != null) {
        final monthPart = r.fecha.split('-').length >= 2
            ? r.fecha.split('-')[1]
            : null;
        matchMonth = monthPart == _selectedMonth;
      }

      bool matchModulo = true;
      if (_selectedModulo != null) {
        matchModulo = r.modulo.toUpperCase() == _selectedModulo;
      }

      return matchSearch && matchMonth && matchModulo;
    }).toList();

    filteredRegistros.sort((a, b) {
      int weight(String modulo) {
        switch (modulo.toUpperCase()) {
          case 'VENTAS':
            return 1;
          case 'COSTOS':
            return 2;
          case 'GASTOS':
            return 3;
          default:
            return 4;
        }
      }

      return weight(a.modulo).compareTo(weight(b.modulo));
    });

    double totalVentas = 0;
    double totalCostos = 0;
    double totalGastos = 0;

    for (var r in filteredRegistros) {
      if (r.modulo.toUpperCase() == 'VENTAS') totalVentas += r.monto;
      if (r.modulo.toUpperCase() == 'COSTOS') totalCostos += r.monto;
      if (r.modulo.toUpperCase() == 'GASTOS') totalGastos += r.monto;
    }

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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Filtrar por mes'),
                        value: _selectedMonth,
                        icon: const Icon(
                          Icons.calendar_month,
                          color: Colors.grey,
                          size: 20,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Todos los meses'),
                          ),
                          ...List.generate(12, (index) {
                            final date = DateTime(2000, index + 1, 1);
                            final mesName = DateFormat(
                              'MMMM',
                              'es',
                            ).format(date);
                            final capitalized =
                                '${mesName[0].toUpperCase()}${mesName.substring(1)}';
                            final mesValue = (index + 1).toString().padLeft(
                              2,
                              '0',
                            );
                            return DropdownMenuItem(
                              value: mesValue,
                              child: Text(capitalized),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedMonth = val);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Filtrar por módulo'),
                        value: _selectedModulo,
                        icon: const Icon(
                          Icons.category_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Todos los módulos'),
                          ),
                          DropdownMenuItem(
                            value: 'VENTAS',
                            child: Text('Ventas'),
                          ),
                          DropdownMenuItem(
                            value: 'COSTOS',
                            child: Text('Costos'),
                          ),
                          DropdownMenuItem(
                            value: 'GASTOS',
                            child: Text('Gastos'),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedModulo = val);
                        },
                      ),
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
                          DataColumn(label: Text('Mes')),
                          DataColumn(label: Text('Código')),
                          DataColumn(label: Text('Módulo')),
                          DataColumn(label: Text('Descripción')),
                          DataColumn(label: Text('Monto')),
                          DataColumn(label: Text('Registrado por')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows: filteredRegistros.asMap().entries.map((entry) {
                          int index = entry.key;
                          var r = entry.value;

                          String mesNombre = 'N/A';
                          try {
                            final date = DateTime.parse(r.fecha);
                            final format = DateFormat(
                              'MMMM',
                              'es',
                            ).format(date);
                            mesNombre =
                                '${format[0].toUpperCase()}${format.substring(1)}';
                          } catch (_) {}

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
                              DataCell(Text(mesNombre)),
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
                                      onPressed: () => _confirmarEliminacion(
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
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTotalItem('Total Ventas', totalVentas, Colors.green),
                  _buildTotalItem('Total Costos', totalCostos, Colors.orange),
                  _buildTotalItem('Total Gastos', totalGastos, Colors.red),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  _buildTotalItem(
                    'Balance Final',
                    totalVentas - totalCostos - totalGastos,
                    (totalVentas - totalCostos - totalGastos) >= 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    isMain: true,
                  ),
                ],
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

  Widget _buildTotalItem(
    String title,
    double amount,
    Color color, {
    bool isMain = false,
  }) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: isMain ? 14 : 12,
            fontWeight: isMain ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormatter.format(amount),
          style: TextStyle(
            color: color,
            fontSize: isMain ? 20 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _confirmarEliminacion(
    BuildContext context,
    LedhouseProvider provider,
    int id,
  ) {
    DialogConfirmacionDelete.mostrar(
      context,
      titulo: 'Eliminar cliente',
      onConfirm: () async {
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
    );
  }
}
