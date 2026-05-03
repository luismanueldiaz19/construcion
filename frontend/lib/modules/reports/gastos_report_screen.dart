import 'package:construccion_erp/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../services/purchase_service.dart';
import 'gasto_detail_screen.dart';

class GastosReportScreen extends StatefulWidget {
  const GastosReportScreen({super.key});

  @override
  State<GastosReportScreen> createState() => _GastosReportScreenState();
}

class _GastosReportScreenState extends State<GastosReportScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  bool _isLoading = true;
  List<dynamic> _allGastos = [];
  List<dynamic> _filteredGastos = [];

  // Filtros
  String? _selectedProyecto;
  String? _selectedTipo;
  String? _selectedProveedor;
  DateTimeRange? _selectedDateRange;

  // Listas de opciones para filtros
  List<String> _proyectos = [];
  List<String> _tipos = [];
  List<String> _proveedores = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final gastos = await _purchaseService.getAllGastos();

      final proySet = <String>{};
      final tipoSet = <String>{};
      final provSet = <String>{};

      for (var g in gastos) {
        if (g['proyecto'] != null) proySet.add(g['proyecto']['nombre']);
        if (g['tipo_gasto'] != null) tipoSet.add(g['tipo_gasto']);
        if (g['proveedor'] != null) provSet.add(g['proveedor']['nombre']);
      }

      setState(() {
        _allGastos = gastos;
        _filteredGastos = List.from(gastos);
        _proyectos = proySet.toList()..sort();
        _tipos = tipoSet.toList()..sort();
        _proveedores = provSet.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar gastos: $e')));
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredGastos = _allGastos.where((g) {
        final proyMatch =
            _selectedProyecto == null ||
            _selectedProyecto == 'Todos' ||
            g['proyecto']?['nombre'] == _selectedProyecto;
        final tipoMatch =
            _selectedTipo == null ||
            _selectedTipo == 'Todos' ||
            g['tipo_gasto'] == _selectedTipo;
        final provMatch =
            _selectedProveedor == null ||
            _selectedProveedor == 'Todos' ||
            g['proveedor']?['nombre'] == _selectedProveedor;

        bool dateMatch = true;
        if (_selectedDateRange != null && g['fecha'] != null) {
          final fecha = DateTime.parse(g['fecha']);
          final fDate = DateTime(fecha.year, fecha.month, fecha.day);
          final start = DateTime(
            _selectedDateRange!.start.year,
            _selectedDateRange!.start.month,
            _selectedDateRange!.start.day,
          );
          final end = DateTime(
            _selectedDateRange!.end.year,
            _selectedDateRange!.end.month,
            _selectedDateRange!.end.day,
          );
          dateMatch =
              fDate.isAfter(start.subtract(const Duration(days: 1))) &&
              fDate.isBefore(end.add(const Duration(days: 1)));
        }

        return proyMatch && tipoMatch && provMatch && dateMatch;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedProyecto = null;
      _selectedTipo = null;
      _selectedProveedor = null;
      _selectedDateRange = null;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        title: const Text('Reporte de Gastos / Pagos'),
        // backgroundColor: AppTheme.primaryColor.withValues(alpha: .5),
        // foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Imprimir Reporte PDF',
            onPressed: () async {
              String query = '?';
              if (_selectedProyecto != null && _selectedProyecto != 'Todos') {
                final match = _allGastos.firstWhere(
                  (g) => g['proyecto']?['nombre'] == _selectedProyecto,
                  orElse: () => null,
                );
                if (match != null) {
                  query += 'proyecto_id=${match['proyecto_id']}&';
                }
              }
              if (_selectedProveedor != null && _selectedProveedor != 'Todos') {
                final match = _allGastos.firstWhere(
                  (g) => g['proveedor']?['nombre'] == _selectedProveedor,
                  orElse: () => null,
                );
                if (match != null) {
                  query += 'proveedor_id=${match['proveedor_id']}&';
                }
              }
              if (_selectedTipo != null && _selectedTipo != 'Todos') {
                query += 'tipo_gasto=$_selectedTipo&';
              }
              // Nota: Agregaremos soporte para rango de fechas si existe la variable
              // Por ahora enviamos los filtros básicos disponibles.

              final url = Uri.parse('$host/reports/gastos/pdf$query');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo generar el reporte PDF'),
                    ),
                  );
                }
              }
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterBar(),
                Expanded(
                  child: _filteredGastos.isEmpty
                      ? const Center(
                          child: Text(
                            'No se encontraron gastos con los filtros seleccionados.',
                          ),
                        )
                      : _buildTable(f),
                ),
                _buildSummary(f),
              ],
            ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildDropdown(
            'Proyecto',
            _selectedProyecto,
            ['Todos', ..._proyectos],
            (v) {
              _selectedProyecto = v;
              _applyFilters();
            },
          ),
          _buildDropdown('Tipo de Gasto', _selectedTipo, ['Todos', ..._tipos], (
            v,
          ) {
            _selectedTipo = v;
            _applyFilters();
          }),
          _buildDropdown(
            'Proveedor (Opcional)',
            _selectedProveedor,
            ['Todos', ..._proveedores],
            (v) {
              _selectedProveedor = v;
              _applyFilters();
            },
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                initialDateRange: _selectedDateRange,
              );
              if (range != null) {
                _selectedDateRange = range;
                _applyFilters();
              }
            },
            icon: const Icon(Icons.date_range),
            label: Text(
              _selectedDateRange == null
                  ? 'Rango de Fechas'
                  : '${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedDateRange == null
                  ? Colors.white
                  : Colors.teal.shade50,
              foregroundColor: Colors.teal.shade700,
            ),
          ),
          TextButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.clear_all),
            label: const Text('Limpiar Filtros'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    final isActive = value != null && value != 'Todos';
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.teal.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.teal : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? Colors.teal : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              isDense: true,
              hint: const Text('Todos'),
              value: value,
              icon: Icon(
                Icons.arrow_drop_down,
                color: isActive ? Colors.teal : Colors.grey,
              ),
              items: items
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(NumberFormat f) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.teal.shade50),
            columns: const [
              DataColumn(
                label: Text(
                  'Acciones',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'ID',
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
                  'Proyecto',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Subpartida',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Tipo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Descripción',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Proveedor',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Método Pago',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Monto',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                numeric: true,
              ),
            ],
            rows: _filteredGastos.map((g) {
              final double monto =
                  double.tryParse(g['monto']?.toString() ?? '0') ?? 0;

              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.visibility,
                            color: Colors.teal,
                          ),
                          tooltip: 'Ver Detalle',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    GastoDetailScreen(gastoId: g['id']),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.print_outlined,
                            color: Colors.teal,
                          ),
                          tooltip: 'Imprimir Comprobante',
                          onPressed: () async {
                            final url = Uri.parse(
                              '$host/gastos/${g['id']}/print',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No se pudo abrir el enlace de impresión',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text('#${g['id']}')),
                  DataCell(Text(g['fecha']?.toString().split('T')[0] ?? '')),
                  DataCell(Text(g['proyecto']?['nombre'] ?? 'N/A')),
                  DataCell(Text(g['subpartida']?['descripcion'] ?? 'General')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        g['tipo_gasto'] ?? 'N/A',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.teal.shade800,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 250,
                      child: Text(
                        g['descripcion'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text(g['proveedor']?['nombre'] ?? 'N/A')),
                  DataCell(Text(g['metodo_pago'] ?? '')),
                  DataCell(
                    Text(
                      f.format(monto),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(NumberFormat f) {
    final total = _filteredGastos.fold(
      0.0,
      (sum, g) => sum + (double.tryParse(g['monto']?.toString() ?? '0') ?? 0),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'Total Gastos Filtrados:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            f.format(total),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
