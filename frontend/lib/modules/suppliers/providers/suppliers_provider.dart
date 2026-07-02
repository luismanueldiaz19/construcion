import 'package:flutter/material.dart';
import '../../../../models/proveedor.dart';
import '../../../../services/purchase_service.dart';

class SuppliersProvider extends ChangeNotifier {
  final PurchaseService _purchaseService = PurchaseService();

  List<Proveedor> _proveedores = [];
  List<Proveedor> _filteredProveedores = [];
  bool _isLoading = true;
  String? _error;

  String _searchQuery = '';
  String _selectedType = 'Todos';
  String _selectedClassification = 'Todos';
  String _selectedStatus = 'Todos';

  Proveedor? _editingProveedor;
  bool _isAddingProveedor = false;

  List<Proveedor> get proveedores => _proveedores;
  List<Proveedor> get filteredProveedores => _filteredProveedores;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get searchQuery => _searchQuery;
  String get selectedType => _selectedType;
  String get selectedClassification => _selectedClassification;
  String get selectedStatus => _selectedStatus;

  Proveedor? get editingProveedor => _editingProveedor;
  bool get isAddingProveedor => _isAddingProveedor;

  bool get isFilterActive =>
      _searchQuery.isNotEmpty ||
      _selectedType != 'Todos' ||
      _selectedClassification != 'Todos' ||
      _selectedStatus != 'Todos';

  SuppliersProvider() {
    loadProveedores();
  }

  Future<void> loadProveedores() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _proveedores = await _purchaseService.getProveedores();
      _applyFilters();

      // Update currently editing supplier if it exists
      if (_editingProveedor != null) {
        try {
          _editingProveedor = _proveedores.firstWhere(
            (p) => p.id == _editingProveedor!.id,
          );
        } catch (_) {}
      }
    } catch (e) {
      _error = 'Error al cargar proveedores: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilters() {
    _filteredProveedores = _proveedores.where((proveedor) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          proveedor.name.toLowerCase().contains(query) ||
          (proveedor.code?.toLowerCase().contains(query) ?? false) ||
          (proveedor.commercialName?.toLowerCase().contains(query) ?? false) ||
          (proveedor.rnc?.toLowerCase().contains(query) ?? false);

      final matchesType =
          _selectedType == 'Todos' || proveedor.type == _selectedType;

      final matchesClassification =
          _selectedClassification == 'Todos' ||
          proveedor.classification == _selectedClassification;

      bool matchesStatus = true;
      if (_selectedStatus == 'Activos') {
        matchesStatus = proveedor.active;
      } else if (_selectedStatus == 'Inactivos') {
        matchesStatus = !proveedor.active;
      }

      return matchesSearch &&
          matchesType &&
          matchesClassification &&
          matchesStatus;
    }).toList();
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _applyFilters();
      notifyListeners();
    }
  }

  void setFilters({String? type, String? classification, String? status}) {
    bool changed = false;
    if (type != null && _selectedType != type) {
      _selectedType = type;
      changed = true;
    }
    if (classification != null && _selectedClassification != classification) {
      _selectedClassification = classification;
      changed = true;
    }
    if (status != null && _selectedStatus != status) {
      _selectedStatus = status;
      changed = true;
    }

    if (changed) {
      _applyFilters();
      notifyListeners();
    }
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedType = 'Todos';
    _selectedClassification = 'Todos';
    _selectedStatus = 'Todos';
    _applyFilters();
    notifyListeners();
  }

  void startAddingProveedor() {
    _editingProveedor = null;
    _isAddingProveedor = true;
    notifyListeners();
  }

  void selectProveedorForEdit(Proveedor proveedor) {
    _editingProveedor = proveedor;
    _isAddingProveedor = false;
    notifyListeners();
  }

  void cancelForm() {
    _editingProveedor = null;
    _isAddingProveedor = false;
    notifyListeners();
  }

  Future<void> saveProveedor(Proveedor proveedor, bool isEdit) async {
    try {
      if (isEdit && proveedor.id != null) {
        await _purchaseService.updateProveedor(proveedor.id!, proveedor);
      } else {
        await _purchaseService.createProveedor(proveedor);
      }

      cancelForm();
      await loadProveedores();
    } catch (e) {
      throw Exception('Error al guardar proveedor: $e');
    }
  }

  Future<void> toggleProveedorStatus(Proveedor proveedor) async {
    try {
      if (proveedor.id != null) {
        await _purchaseService.toggleActiveProveedor(proveedor.id!);
        await loadProveedores();
      }
    } catch (e) {
      throw Exception('Error al cambiar estado del proveedor: $e');
    }
  }
}
