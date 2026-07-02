import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/purchase_service.dart';
import '../../../../services/project_service.dart';
import '../../../../models/compra.dart';
import '../../../../models/proyecto.dart';
import '../../../../models/proveedor.dart';
import '../../../../widgets/quick_date_filter.dart';

class ComprasReportProvider extends ChangeNotifier {
  final PurchaseService _purchaseService = PurchaseService();
  final ProjectService _projectService = ProjectService();

  bool isLoading = true;
  List<Compra> compras = [];

  // Filtros
  Proyecto? selectedProyecto;
  Proveedor? selectedProveedor;
  String? selectedEstado;
  DateTimeRange? selectedDateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
  );
  DateFilterOption selectedDateFilter = DateFilterOption.esteMes;

  // Paginación
  int currentPage = 1;
  int lastPage = 1;
  final int rowsPerPage = 10;

  // Totales globales (desde el backend)
  double totalSubtotal = 0;
  double totalItbis = 0;
  double totalGeneral = 0;

  // Búsqueda
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  // Listas de opciones para filtros (Cargadas de APIs)
  List<Proyecto> proyectos = [];
  List<Proveedor> proveedores = [];
  final List<String> estados = ['Pendiente', 'Recibido', 'Cancelado'];

  // Detail states
  Map<String, dynamic>? selectedCompraDetail;
  bool isLoadingDetail = false;

  bool get isFilterActive =>
      searchController.text.isNotEmpty ||
      selectedProyecto != null ||
      selectedProveedor != null ||
      selectedEstado != null ||
      selectedDateRange != null;

  ComprasReportProvider() {
    loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  DateTimeRange? getDateRangeFromOption(DateFilterOption option) {
    final now = DateTime.now();
    switch (option) {
      case DateFilterOption.todos:
        return null;
      case DateFilterOption.ultimos7Dias:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
      case DateFilterOption.ultimos30Dias:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
      case DateFilterOption.esteMes:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case DateFilterOption.mesPasado:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 1, 1),
          end: DateTime(now.year, now.month, 0, 23, 59, 59),
        );
      case DateFilterOption.hace2Meses:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 2, 1),
          end: DateTime(now.year, now.month - 1, 0, 23, 59, 59),
        );
      case DateFilterOption.hace3Meses:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 3, 1),
          end: DateTime(now.year, now.month - 2, 0, 23, 59, 59),
        );
      case DateFilterOption.esteAno:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        );
      case DateFilterOption.anoPasado:
        return DateTimeRange(
          start: DateTime(now.year - 1, 1, 1),
          end: DateTime(now.year - 1, 12, 31, 23, 59, 59),
        );
    }
  }

  Future<void> loadData() async {
    isLoading = true;
    notifyListeners();

    try {
      if (proyectos.isEmpty) {
        proyectos = await _projectService.getProyectos();
      }
      if (proveedores.isEmpty) {
        proveedores = await _purchaseService.getProveedores();
      }

      Map<String, dynamic> filters = {};
      if (selectedProyecto != null) {
        filters['proyecto_id'] = selectedProyecto!.id;
      }
      if (selectedProveedor != null) {
        filters['proveedor_id'] = selectedProveedor!.id;
      }
      if (selectedEstado != null && selectedEstado != 'Todos') {
        filters['estado'] = selectedEstado;
      }
      if (selectedDateRange != null) {
        filters['fecha_inicio'] = DateFormat('yyyy-MM-dd').format(selectedDateRange!.start);
        filters['fecha_fin'] = DateFormat('yyyy-MM-dd').format(selectedDateRange!.end);
      }
      if (searchQuery.isNotEmpty) {
        filters['search'] = searchQuery;
      }

      final response = await _purchaseService.getComprasReporte(
        filters,
        currentPage,
        rowsPerPage,
      );
      final List<dynamic> data = response['data'];

      compras = data.map((json) => Compra.fromJson(json)).toList();
      lastPage = response['last_page'] ?? 1;

      if (response['summary'] != null) {
        final summary = response['summary'];
        totalSubtotal = double.tryParse(summary['subtotal']?.toString() ?? '0') ?? 0.0;
        totalItbis = double.tryParse(summary['itbis']?.toString() ?? '0') ?? 0.0;
        totalGeneral = double.tryParse(summary['total']?.toString() ?? '0') ?? 0.0;
      }

      if (selectedCompraDetail != null) {
        _loadCompraDetailSilently(selectedCompraDetail!['id']);
      }
    } catch (e) {
      debugPrint("Error al cargar compras: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCompraDetailSilently(int id) async {
    try {
      selectedCompraDetail = await _purchaseService.getCompra(id);
      notifyListeners();
    } catch (e) {
      debugPrint("Error sync detail: $e");
    }
  }

  Future<void> loadCompraDetail(int id) async {
    isLoadingDetail = true;
    notifyListeners();

    try {
      selectedCompraDetail = await _purchaseService.getCompra(id);
    } catch (e) {
      debugPrint("Error load detail: $e");
      rethrow;
    } finally {
      isLoadingDetail = false;
      notifyListeners();
    }
  }

  void selectCompra(int? id) {
    if (id == null) {
      selectedCompraDetail = null;
      notifyListeners();
    } else {
      loadCompraDetail(id);
    }
  }

  void applyFilters() {
    currentPage = 1;
    loadData();
  }

  void clearFilters() {
    searchController.clear();
    searchQuery = '';
    selectedProyecto = null;
    selectedProveedor = null;
    selectedEstado = null;
    selectedDateRange = DateTimeRange(
      start: DateTime(DateTime.now().year, DateTime.now().month, 1),
      end: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
    );
    selectedDateFilter = DateFilterOption.esteMes;
    currentPage = 1;
    loadData();
  }

  void updateSearchQuery(String value) {
    searchQuery = value;
    applyFilters();
  }

  void setProyecto(Proyecto? p) {
    selectedProyecto = p;
    applyFilters();
  }

  void setProveedor(Proveedor? p) {
    selectedProveedor = p;
    applyFilters();
  }

  void setEstado(String? e) {
    selectedEstado = e;
    applyFilters();
  }

  void setDateRange(DateTimeRange? range) {
    selectedDateRange = range;
    selectedDateFilter = DateFilterOption.todos;
    applyFilters();
  }

  void setDateFilter(DateFilterOption option) {
    selectedDateFilter = option;
    selectedDateRange = getDateRangeFromOption(option);
    currentPage = 1;
    loadData();
  }

  void setPage(int page) {
    if (page >= 1 && page <= lastPage) {
      currentPage = page;
      loadData();
    }
  }

  Future<void> uploadDocumentoCompra(dynamic file) async {
    if (selectedCompraDetail == null) return;
    isLoadingDetail = true;
    notifyListeners();
    try {
      await _purchaseService.uploadDocumentoCompra(selectedCompraDetail!['id'], file);
      await loadCompraDetail(selectedCompraDetail!['id']);
    } finally {
      isLoadingDetail = false;
      notifyListeners();
    }
  }

  Future<void> deleteDocumentoCompra(int docId) async {
    if (selectedCompraDetail == null) return;
    isLoadingDetail = true;
    notifyListeners();
    try {
      await _purchaseService.deleteDocumentoCompra(docId);
      await loadCompraDetail(selectedCompraDetail!['id']);
    } finally {
      isLoadingDetail = false;
      notifyListeners();
    }
  }
}
