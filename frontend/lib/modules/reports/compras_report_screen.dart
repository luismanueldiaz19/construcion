import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../services/purchase_service.dart';
import '../../services/project_service.dart';
import '../../models/compra.dart';
import '../../models/proyecto.dart';
import '../../models/proveedor.dart';

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

  // Detail states
  Map<String, dynamic>? _selectedCompraDetail;
  bool _isLoadingDetail = false;
  StateSetter? _bottomSheetSetState;

  bool get _isFilterActive =>
      _searchController.text.isNotEmpty ||
      _selectedProyecto != null ||
      _selectedProveedor != null ||
      _selectedEstado != null ||
      _selectedDateRange != null;

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

        // Sync detail if active
        if (_selectedCompraDetail != null) {
          _loadCompraDetail(_selectedCompraDetail!['id']);
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

  Future<void> _loadCompraDetail(int id) async {
    setState(() {
      _isLoadingDetail = true;
    });
    if (_bottomSheetSetState != null) {
      _bottomSheetSetState!(() {});
    }
    try {
      final detail = await _purchaseService.getCompra(id);
      setState(() {
        _selectedCompraDetail = detail;
        _isLoadingDetail = false;
      });
      if (_bottomSheetSetState != null) {
        _bottomSheetSetState!(() {});
      }
    } catch (e) {
      setState(() {
        _isLoadingDetail = false;
      });
      if (_bottomSheetSetState != null) {
        _bottomSheetSetState!(() {});
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar detalle de compra: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onCompraPressed(int id, bool isLargeScreen) {
    _loadCompraDetail(id);
    if (!isLargeScreen) {
      _showDetailBottomSheet();
    }
  }

  void _showDetailBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 600),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            _bottomSheetSetState = setModalState;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: _buildDetailPanel(
                      isBottomSheet: true,
                      onStateChanged: () {
                        setModalState(() {});
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _bottomSheetSetState = null;
      if (mounted) {
        setState(() {
          _selectedCompraDetail = null;
        });
      }
    });
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 600),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtrar Compras',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar comprobante, ID, orden...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _applyFilters();
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Proyecto>(
                    value: _selectedProyecto,
                    decoration: InputDecoration(
                      labelText: 'Proyecto',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: [
                      const DropdownMenuItem<Proyecto>(
                        value: null,
                        child: Text('Todos los proyectos'),
                      ),
                      ..._proyectos.map(
                        (p) => DropdownMenuItem<Proyecto>(
                          value: p,
                          child: Text(p.nombre),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _selectedProyecto = v;
                      });
                      _applyFilters();
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Proveedor>(
                    value: _selectedProveedor,
                    decoration: InputDecoration(
                      labelText: 'Proveedor',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: [
                      const DropdownMenuItem<Proveedor>(
                        value: null,
                        child: Text('Todos los proveedores'),
                      ),
                      ..._proveedores.map(
                        (p) => DropdownMenuItem<Proveedor>(
                          value: p,
                          child: Text(p.nombre),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _selectedProveedor = v;
                      });
                      _applyFilters();
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedEstado,
                    decoration: InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Todos los estados'),
                      ),
                      ..._estados.map(
                        (s) =>
                            DropdownMenuItem<String>(value: s, child: Text(s)),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _selectedEstado = v;
                      });
                      _applyFilters();
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        initialDateRange: _selectedDateRange,
                      );
                      if (range != null) {
                        setState(() {
                          _selectedDateRange = range;
                        });
                        _applyFilters();
                        setModalState(() {});
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Rango de Fechas',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDateRange == null
                                ? 'No seleccionado'
                                : '${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const Icon(Icons.date_range, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _clearFilters();
                            setModalState(() {});
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('LIMPIAR FILTROS'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('APLICAR'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChips() {
    if (!_isFilterActive) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Text(
            'Filtros activos: ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                if (_searchController.text.isNotEmpty)
                  Chip(
                    label: Text('Buscar: "${_searchController.text}"'),
                    onDeleted: () {
                      _searchController.clear();
                      _searchQuery = '';
                      _applyFilters();
                    },
                    deleteIcon: const Icon(Icons.close, size: 16),
                    backgroundColor: Colors.blue[50],
                  ),
                if (_selectedProyecto != null)
                  Chip(
                    label: Text('Proyecto: ${_selectedProyecto!.nombre}'),
                    onDeleted: () {
                      setState(() {
                        _selectedProyecto = null;
                      });
                      _applyFilters();
                    },
                    deleteIcon: const Icon(Icons.close, size: 16),
                    backgroundColor: Colors.blue[50],
                  ),
                if (_selectedProveedor != null)
                  Chip(
                    label: Text('Proveedor: ${_selectedProveedor!.nombre}'),
                    onDeleted: () {
                      setState(() {
                        _selectedProveedor = null;
                      });
                      _applyFilters();
                    },
                    deleteIcon: const Icon(Icons.close, size: 16),
                    backgroundColor: Colors.blue[50],
                  ),
                if (_selectedEstado != null)
                  Chip(
                    label: Text('Estado: $_selectedEstado'),
                    onDeleted: () {
                      setState(() {
                        _selectedEstado = null;
                      });
                      _applyFilters();
                    },
                    deleteIcon: const Icon(Icons.close, size: 16),
                    backgroundColor: Colors.blue[50],
                  ),
                if (_selectedDateRange != null)
                  Chip(
                    label: Text(
                      'Fechas: ${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}',
                    ),
                    onDeleted: () {
                      setState(() {
                        _selectedDateRange = null;
                      });
                      _applyFilters();
                    },
                    deleteIcon: const Icon(Icons.close, size: 16),
                    backgroundColor: Colors.blue[50],
                  ),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Limpiar todo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: '\$');
    final width = MediaQuery.of(context).size.width;
    final isLargeScreen = width > 950;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        title: const Text('Registro de Compras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Imprimir Reporte PDF',
            onPressed: () async {
              String query = '?';
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
                if (mounted) {
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
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _showFilterBottomSheet(),
            icon: Icon(
              _isFilterActive ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _isFilterActive
                  ? AppTheme.accentColor
                  : AppTheme.textSecondary,
              size: 20,
            ),
            label: Text(
              'Filtrar',
              style: TextStyle(
                color: _isFilterActive
                    ? AppTheme.accentColor
                    : AppTheme.textSecondary,
                fontWeight: _isFilterActive
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _isFilterActive
                    ? AppTheme.accentColor
                    : Colors.grey[300]!,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterChips(),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _compras.isEmpty
                            ? const Center(
                                child: Text(
                                  'No se encontraron compras con los filtros seleccionados.',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: _buildTable(f, isLargeScreen),
                                      ),
                                    ),
                                  ),
                                  _buildPagination(),
                                ],
                              ),
                      ),
                      if (isLargeScreen)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 16.0,
                            right: 16.0,
                            bottom: 16.0,
                          ),
                          child: SizedBox(
                            width: 460,
                            child:
                                _selectedCompraDetail != null ||
                                    _isLoadingDetail
                                ? _buildDetailPanel(isBottomSheet: false)
                                : _buildPlaceholderPanel(),
                          ),
                        ),
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

  Widget _buildTable(NumberFormat f, bool isLargeScreen) {
    // Header
    Widget header = Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Referencia',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Participantes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Importes',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                'Estado',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // List of rows
    return Column(
      children: [
        header,
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        Expanded(
          child: ListView.separated(
            itemCount: _compras.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
            itemBuilder: (context, index) {
              final Compra c = _compras[index];
              final double total = c.total;
              final double subtotal = c.subtotal;
              final double itbis = total - subtotal;
              final bool isSelected =
                  _selectedCompraDetail != null &&
                  _selectedCompraDetail!['id'] == c.id;

              Color estadoColor = c.estado == 'Pendiente'
                  ? Colors.orange
                  : Colors.green;

              return InkWell(
                onTap: () => _onCompraPressed(c.id, isLargeScreen),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.05)
                        : Colors.transparent,
                    border: Border(
                      left: BorderSide(
                        color: isSelected
                            ? AppTheme.accentColor
                            : Colors.transparent,
                        width: 4,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 24,
                    top: 16,
                    bottom: 16,
                  ),
                  child: Row(
                    children: [
                      // Referencia
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '#${c.id} - ${c.tipoCompra}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c.fecha.split('T')[0],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            if (c.comprobante != null &&
                                c.comprobante!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'NFC: ${c.comprobante}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blueGrey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Participantes
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              c.proveedor?.nombre ?? 'N/A',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
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
                      // Importes
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              f.format(total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sub: ${f.format(subtotal)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'ITBIS: ${f.format(itbis)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Estado
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: estadoColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: estadoColor.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              c.estado,
                              style: TextStyle(
                                color: estadoColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailPanel({
    required bool isBottomSheet,
    VoidCallback? onStateChanged,
  }) {
    if (_isLoadingDetail) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: isBottomSheet
            ? null
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Cargando detalles...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedCompraDetail == null) {
      return const SizedBox.shrink();
    }

    final f = NumberFormat.currency(symbol: '\$');
    final detalles = _selectedCompraDetail!['detalles'] as List? ?? [];
    final documentos = _selectedCompraDetail!['documentos'] as List? ?? [];
    final estado = _selectedCompraDetail!['estado'] ?? 'N/A';
    Color estadoColor = estado == 'Pendiente' ? Colors.orange : Colors.green;

    final subtotal =
        double.tryParse(
          _selectedCompraDetail!['subtotal']?.toString() ?? '0',
        ) ??
        0;
    final itbis =
        double.tryParse(_selectedCompraDetail!['itbis']?.toString() ?? '0') ??
        0;
    final total =
        double.tryParse(_selectedCompraDetail!['total']?.toString() ?? '0') ??
        0;

    final infoSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información de Facturación
        _buildInfoItem(
          'Proveedor',
          _selectedCompraDetail!['proveedor']?['nombre'] ?? 'N/A',
          Icons.store,
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          'Proyecto',
          _selectedCompraDetail!['proyecto']?['nombre'] ?? 'N/A',
          Icons.business,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'Fecha',
                _selectedCompraDetail!['fecha']?.toString().split('T')[0] ??
                    'N/A',
                Icons.calendar_today,
              ),
            ),
            Expanded(
              child: _buildInfoItem(
                'Tipo',
                _selectedCompraDetail!['tipo_compra'] ?? 'N/A',
                Icons.payment,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'Comprobante',
                _selectedCompraDetail!['comprobante'] ?? 'N/A',
                Icons.confirmation_number,
              ),
            ),
            Expanded(
              child: _buildInfoItem(
                'Orden #',
                _selectedCompraDetail!['orden'] ?? 'N/A',
                Icons.receipt_long,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'Código Ref.',
                _selectedCompraDetail!['codigo'] ?? 'N/A',
                Icons.qr_code,
              ),
            ),
            Expanded(
              child: _buildInfoItem(
                'Vencimiento',
                _selectedCompraDetail!['fecha_vencimiento']?.toString().split(
                      'T',
                    )[0] ??
                    'N/A',
                Icons.event_note,
              ),
            ),
          ],
        ),
        if (_selectedCompraDetail!['nota'] != null &&
            _selectedCompraDetail!['nota'].toString().isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoItem(
            'Notas / Observaciones',
            _selectedCompraDetail!['nota'],
            Icons.info_outline,
          ),
        ],

        // Desglose de Artículos
        const Divider(height: 24),
        const Text(
          'Artículos / Materiales',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: detalles.length,
          itemBuilder: (context, index) {
            final d = detalles[index];
            final mat = d['material'];
            final cantidad =
                double.tryParse(d['cantidad']?.toString() ?? '0') ?? 0;
            final precio =
                double.tryParse(d['precio_unitario']?.toString() ?? '0') ?? 0;
            final subtotalVal =
                double.tryParse(d['subtotal']?.toString() ?? '0') ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mat?['nombre'] ?? 'Desconocido',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${cantidad.toStringAsFixed(2)} x ${f.format(precio)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    f.format(subtotalVal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Evidencias / Documentos
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Evidencias / Documentos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.blueGrey,
              ),
            ),
            TextButton.icon(
              onPressed: () => _uploadDocumento(onStateChanged),
              icon: const Icon(Icons.upload_file, size: 16),
              label: const Text('Subir', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (documentos.isEmpty)
          const Text(
            'No hay documentos adjuntos.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: documentos.length,
            itemBuilder: (context, index) {
              final doc = documentos[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(
                  Icons.insert_drive_file,
                  color: Colors.blueGrey,
                  size: 16,
                ),
                title: Text(
                  doc['original_name'] ?? 'Documento',
                  style: const TextStyle(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.open_in_new,
                        color: Colors.blue,
                        size: 16,
                      ),
                      onPressed: () async {
                        final url = Uri.parse(
                          '$host/storage/${doc['file_path']}',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 16,
                      ),
                      onPressed: () =>
                          _confirmDeleteDocumento(doc['id'], onStateChanged),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );

    final totalsSection = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF003366),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildTotalRow('Subtotal', f.format(subtotal), Colors.white70),
          const SizedBox(height: 4),
          _buildTotalRow('ITBIS (18%)', f.format(itbis), Colors.white70),
          const Divider(color: Colors.white24, height: 16),
          _buildTotalRow(
            'TOTAL',
            f.format(total),
            Colors.greenAccent,
            isTotal: true,
          ),
        ],
      ),
    );

    final headerSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Factura #${_selectedCompraDetail!['id']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.print, color: AppTheme.primaryColor),
              tooltip: 'Imprimir Factura',
              onPressed: () async {
                final url = Uri.parse(
                  '$host/compras/${_selectedCompraDetail!['id']}/print',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  if (mounted) {
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
            if (isBottomSheet)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            else
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedCompraDetail = null),
                tooltip: 'Cerrar',
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: estadoColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: estadoColor),
          ),
          child: Text(
            estado.toUpperCase(),
            style: TextStyle(
              color: estadoColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        const Divider(height: 24),
      ],
    );

    if (isBottomSheet) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            headerSection,
            infoSection,
            const SizedBox(height: 12),
            totalsSection,
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            headerSection,
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [infoSection, const SizedBox(height: 16)],
                ),
              ),
            ),
            const SizedBox(height: 12),
            totalsSection,
          ],
        ),
      );
    }
  }

  Future<void> _uploadDocumento(VoidCallback? onStateChanged) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isLoadingDetail = true);
        if (onStateChanged != null) onStateChanged();

        await _purchaseService.uploadDocumentoCompra(
          _selectedCompraDetail!['id'],
          result.files.single.path!,
        );

        final detail = await _purchaseService.getCompra(
          _selectedCompraDetail!['id'],
        );
        setState(() {
          _selectedCompraDetail = detail;
          _isLoadingDetail = false;
        });
        if (onStateChanged != null) onStateChanged();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Documento subido correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoadingDetail = false);
      if (onStateChanged != null) onStateChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir documento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteDocumento(
    int docId,
    VoidCallback? onStateChanged,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Documento'),
        content: const Text('¿Está seguro que desea eliminar este documento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoadingDetail = true);
      if (onStateChanged != null) onStateChanged();
      try {
        await _purchaseService.deleteDocumentoCompra(docId);
        final detail = await _purchaseService.getCompra(
          _selectedCompraDetail!['id'],
        );
        setState(() {
          _selectedCompraDetail = detail;
          _isLoadingDetail = false;
        });
        if (onStateChanged != null) onStateChanged();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Documento eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoadingDetail = false);
        if (onStateChanged != null) onStateChanged();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildPlaceholderPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Detalles de Factura',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Seleccione una compra del registro a la izquierda para visualizar su factura, desglose de materiales, totales y documentos de evidencia adjuntos.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildTotalRow(
    String label,
    String value,
    Color color, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: isTotal ? 16 : 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
