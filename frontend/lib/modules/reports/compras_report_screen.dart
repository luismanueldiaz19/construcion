import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../services/api_service.dart';
import 'compra_detail_screen.dart';

class ComprasReportScreen extends StatefulWidget {
  const ComprasReportScreen({super.key});

  @override
  State<ComprasReportScreen> createState() => _ComprasReportScreenState();
}

class _ComprasReportScreenState extends State<ComprasReportScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _allCompras = [];
  List<dynamic> _filteredCompras = [];

  // Filtros
  String? _selectedProyecto;
  String? _selectedProveedor;
  String? _selectedEstado;
  DateTimeRange? _selectedDateRange;

  // Listas de opciones para filtros
  List<String> _proyectos = [];
  List<String> _proveedores = [];
  final List<String> _estados = ['Pendiente', 'Recibido', 'Cancelado'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final compras = await _apiService.getAllCompras();

      final proySet = <String>{};
      final provSet = <String>{};

      for (var c in compras) {
        if (c['proyecto'] != null) proySet.add(c['proyecto']['nombre']);
        if (c['proveedor'] != null) provSet.add(c['proveedor']['nombre']);
      }

      setState(() {
        _allCompras = compras;
        _filteredCompras = List.from(compras);
        _proyectos = proySet.toList()..sort();
        _proveedores = provSet.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar compras: $e')));
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredCompras = _allCompras.where((c) {
        final proyMatch =
            _selectedProyecto == null ||
            _selectedProyecto == 'Todos' ||
            c['proyecto']?['nombre'] == _selectedProyecto;
        final provMatch =
            _selectedProveedor == null ||
            _selectedProveedor == 'Todos' ||
            c['proveedor']?['nombre'] == _selectedProveedor;
        final estadoMatch =
            _selectedEstado == null ||
            _selectedEstado == 'Todos' ||
            c['estado'] == _selectedEstado;

        bool dateMatch = true;
        if (_selectedDateRange != null && c['fecha'] != null) {
          final fecha = DateTime.parse(c['fecha']);
          // Solo comparar la fecha ignorando hora
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

        return proyMatch && provMatch && estadoMatch && dateMatch;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedProyecto = null;
      _selectedProveedor = null;
      _selectedEstado = null;
      _selectedDateRange = null;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Compras'),
        // backgroundColor: Colors.indigo,
        // foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Imprimir Reporte PDF',
            onPressed: () async {
              String query = '?';
              if (_selectedProyecto != null && _selectedProyecto != 'Todos') {
                final match = _allCompras.firstWhere(
                  (c) => c['proyecto']?['nombre'] == _selectedProyecto,
                  orElse: () => null,
                );
                if (match != null)
                  query += 'proyecto_id=${match['proyecto']['id']}&';
              }
              if (_selectedProveedor != null && _selectedProveedor != 'Todos') {
                final match = _allCompras.firstWhere(
                  (c) => c['proveedor']?['nombre'] == _selectedProveedor,
                  orElse: () => null,
                );
                if (match != null)
                  query += 'proveedor_id=${match['proveedor']['id']}&';
              }
              if (_selectedEstado != null && _selectedEstado != 'Todos') {
                query += 'estado=$_selectedEstado&';
              }
              if (_selectedDateRange != null) {
                query +=
                    'fecha_inicio=${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start)}&';
                query +=
                    'fecha_fin=${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end)}&';
              }

              final url = Uri.parse('$host/reports/compras/pdf$query');
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
                  child: _filteredCompras.isEmpty
                      ? const Center(
                          child: Text(
                            'No se encontraron compras con los filtros seleccionados.',
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
          _buildDropdown(
            'Proveedor',
            _selectedProveedor,
            ['Todos', ..._proveedores],
            (v) {
              _selectedProveedor = v;
              _applyFilters();
            },
          ),
          _buildDropdown('Estado', _selectedEstado, ['Todos', ..._estados], (
            v,
          ) {
            _selectedEstado = v;
            _applyFilters();
          }),
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
                  : Colors.indigo.shade50,
              foregroundColor: Colors.indigo,
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
        color: isActive ? Colors.indigo.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.indigo : Colors.grey.shade300,
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
              color: isActive ? Colors.indigo : Colors.grey.shade600,
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
                color: isActive ? Colors.indigo : Colors.grey,
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.indigo.shade50),
          columns: const [
            DataColumn(
              label: Text(
                'Acciones',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold)),
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
                'Proveedor',
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
                'Estado',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Subtotal',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true,
            ),
          ],
          rows: _filteredCompras.map((c) {
            final double total =
                double.tryParse(c['total']?.toString() ?? '0') ?? 0;
            final double subtotal =
                double.tryParse(c['subtotal']?.toString() ?? '0') ?? 0;

            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.visibility_outlined,
                          color: Colors.indigo,
                        ),
                        tooltip: 'Ver Factura Completa',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CompraDetailScreen(compraId: c['id']),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.print_outlined,
                          color: Colors.indigo,
                        ),
                        tooltip: 'Imprimir Factura',
                        onPressed: () async {
                          final url = Uri.parse(
                            '$host/compras/${c!['id']}/print',
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
                DataCell(Text('#${c['id']}')),
                DataCell(Text(c['fecha']?.toString().split('T')[0] ?? '')),
                DataCell(Text(c['proyecto']?['nombre'] ?? 'N/A')),
                DataCell(Text(c['proveedor']?['nombre'] ?? 'N/A')),
                DataCell(Text(c['tipo_compra'] ?? 'N/A')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: c['estado'] == 'Pendiente'
                          ? Colors.orange.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      c['estado'] ?? '',
                      style: TextStyle(
                        color: c['estado'] == 'Pendiente'
                            ? Colors.orange.shade900
                            : Colors.green.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(f.format(subtotal))),
                DataCell(
                  Text(
                    f.format(total),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummary(NumberFormat f) {
    final total = _filteredCompras.fold(
      0.0,
      (sum, c) => sum + (double.tryParse(c['total']?.toString() ?? '0') ?? 0),
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
            'Total Compras Filtradas:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            f.format(total),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }
}
