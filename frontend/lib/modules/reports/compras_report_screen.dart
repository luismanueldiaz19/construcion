import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../services/purchase_service.dart';
import '../../services/project_service.dart';
import '../../models/compra.dart';
import '../../models/proyecto.dart';
import '../../models/proveedor.dart';
import 'compra_detail_screen.dart';

class ComprasReportScreen extends StatefulWidget {
  const ComprasReportScreen({super.key});

  @override
  State<ComprasReportScreen> createState() => _ComprasReportScreenState();
}

class _ComprasReportScreenState extends State<ComprasReportScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  final ProjectService _projectService = ProjectService();
  bool _isLoading = true;
  List<Compra> _compras = [];

  // Filtros
  Proyecto? _selectedProyecto;
  Proveedor? _selectedProveedor;
  String? _selectedEstado;
  DateTimeRange? _selectedDateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
  );

  // Paginación
  int _currentPage = 1;
  int _lastPage = 1;
  final int _rowsPerPage = 10;

  // Totales globales (desde el backend)
  double _totalSubtotal = 0;
  double _totalItbis = 0;
  double _totalGeneral = 0;

  // Búsqueda
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Listas de opciones para filtros (Cargadas de APIs)
  List<Proyecto> _proyectos = [];
  List<Proveedor> _proveedores = [];
  final List<String> _estados = ['Pendiente', 'Recibido', 'Cancelado'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Cargar catálogos solo la primera vez
      if (_proyectos.isEmpty) {
        _proyectos = await _projectService.getProyectos();
      }
      if (_proveedores.isEmpty) {
        _proveedores = await _purchaseService.getProveedores();
      }

      // Preparar filtros
      Map<String, dynamic> filters = {};
      if (_selectedProyecto != null) {
        filters['proyecto_id'] = _selectedProyecto!.id;
      }
      if (_selectedProveedor != null) {
        filters['proveedor_id'] = _selectedProveedor!.id;
      }
      if (_selectedEstado != null && _selectedEstado != 'Todos') {
        filters['estado'] = _selectedEstado;
      }
      if (_selectedDateRange != null) {
        filters['fecha_inicio'] = DateFormat(
          'yyyy-MM-dd',
        ).format(_selectedDateRange!.start);
        filters['fecha_fin'] = DateFormat(
          'yyyy-MM-dd',
        ).format(_selectedDateRange!.end);
      }
      if (_searchQuery.isNotEmpty) {
        filters['search'] = _searchQuery;
      }

      final response = await _purchaseService.getComprasReporte(
        filters,
        _currentPage,
        _rowsPerPage,
      );
      final List<dynamic> data = response['data'];

      setState(() {
        _compras = data.map((json) => Compra.fromJson(json)).toList();
        _lastPage = response['last_page'] ?? 1;

        // Asignar totales globales
        if (response['summary'] != null) {
          final summary = response['summary'];
          _totalSubtotal =
              double.tryParse(summary['subtotal']?.toString() ?? '0') ?? 0.0;
          _totalItbis =
              double.tryParse(summary['itbis']?.toString() ?? '0') ?? 0.0;
          _totalGeneral =
              double.tryParse(summary['total']?.toString() ?? '0') ?? 0.0;
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error al cargar compras: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar compras: $e')));
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _currentPage = 1; // Reset a primera página al filtrar
    });
    _loadData();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedProyecto = null;
      _selectedProveedor = null;
      _selectedEstado = null;
      _selectedDateRange = DateTimeRange(
        start: DateTime(DateTime.now().year, DateTime.now().month, 1),
        end: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
      );
      _currentPage = 1;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
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
                if (_selectedProyecto != null) {
                  query += 'proyecto_id=${_selectedProyecto!.id}&';
                }
                if (_selectedProveedor != null) {
                  query += 'proveedor_id=${_selectedProveedor!.id}&';
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
                  child: _compras.isEmpty
                      ? const Center(
                          child: Text(
                            'No se encontraron compras con los filtros seleccionados.',
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _buildTable(f),
                                ),
                              ),
                            ),
                            _buildPagination(),
                          ],
                        ),
                ),
                _buildSummary(f),
              ],
            ),
    );
  }

  Widget _buildPagination() {
    if (_lastPage <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _loadData();
                  }
                : null,
          ),
          Text(
            'Página $_currentPage de $_lastPage',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _lastPage
                ? () {
                    setState(() => _currentPage++);
                    _loadData();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 250,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar comprobante, ID, orden...',
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _applyFilters();
              },
            ),
          ),
          _buildGenericDropdown<Proyecto>(
            'Proyecto',
            _selectedProyecto,
            _proyectos,
            (p) => p.nombre,
            (v) {
              _selectedProyecto = v;
              _applyFilters();
            },
          ),
          _buildGenericDropdown<Proveedor>(
            'Proveedor',
            _selectedProveedor,
            _proveedores,
            (p) => p.nombre,
            (v) {
              _selectedProveedor = v;
              _applyFilters();
            },
          ),
          _buildGenericDropdown<String>(
            'Estado',
            _selectedEstado,
            _estados,
            (s) => s,
            (v) {
              _selectedEstado = v;
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
                  : AppTheme.primaryColor.withValues(alpha: 0.1),
              foregroundColor: AppTheme.primaryColor,
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

  Widget _buildGenericDropdown<T>(
    String label,
    T? value,
    List<T> items,
    String Function(T) getLabel,
    Function(T?) onChanged,
  ) {
    final isActive = value != null;
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primaryColor.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? AppTheme.primaryColor : Colors.grey.shade300,
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
              color: isActive ? AppTheme.primaryColor : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              isDense: true,
              hint: const Text('Todos'),
              value: value,
              icon: Icon(
                Icons.arrow_drop_down,
                color: isActive ? AppTheme.primaryColor : Colors.grey,
              ),
              items: [
                DropdownMenuItem<T>(value: null, child: const Text('Todos')),
                ...items.map(
                  (e) => DropdownMenuItem<T>(
                    value: e,
                    child: Text(getLabel(e), overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(NumberFormat f) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columnSpacing: 40,
                dataRowMaxHeight: 75,
                dataRowMinHeight: 56,
                headingRowColor: WidgetStateProperty.all(AppTheme.primaryColor),
                columns: const [
                  DataColumn(
                    label: Text(
                      'Referencia',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Participantes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Importes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      'Estado',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Acciones',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                rows: _compras.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final Compra c = entry.value;
                  final double total = c.total;
                  final double subtotal = c.subtotal;
                  final bool isEven = index % 2 == 0;

                  return DataRow(
                    color: WidgetStateProperty.all(
                      isEven ? Colors.white : Colors.grey.shade50,
                    ),
                    cells: [
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '#${c.id} - ${c.tipoCompra}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              c.fecha.split('T')[0],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            if (c.comprobante != null &&
                                c.comprobante!.isNotEmpty)
                              Text(
                                'NFC: ${c.comprobante}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueGrey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              c.proveedor?.nombre ?? 'N/A',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              c.proyecto?.nombre ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sub: ${f.format(subtotal)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'ITBIS: ${f.format(c.itbis)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Tot: ${f.format(total)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: c.estado == 'Pendiente'
                                ? Colors.orange.shade100
                                : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            c.estado,
                            style: TextStyle(
                              color: c.estado == 'Pendiente'
                                  ? Colors.orange.shade900
                                  : Colors.green.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.visibility_outlined,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              tooltip: 'Ver Factura',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CompraDetailScreen(compraId: c.id),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.print_outlined,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              tooltip: 'Imprimir',
                              onPressed: () async {
                                final url = Uri.parse(
                                  '$host/compras/${c.id}/print',
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
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummary(NumberFormat f) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildSummaryBox('Subtotal', f.format(_totalSubtotal)),
          const SizedBox(width: 16),
          _buildSummaryBox('ITBIS', f.format(_totalItbis)),
          const SizedBox(width: 16),
          _buildGradientSummaryBox('TOTAL GENERAL', f.format(_totalGeneral)),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientSummaryBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
