import 'package:flutter/foundation.dart';
import '../../../services/http_service.dart';
import '../models/ledhouse_proveedor.dart';

class LedhouseProveedorProvider with ChangeNotifier {
  final HttpService _http = HttpService();
  List<LedhouseProveedor> _proveedores = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<LedhouseProveedor> get proveedores => _proveedores;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchProveedores() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _http.get('ledhouse/proveedores');
      if (response is List) {
        _proveedores = response
            .map((json) => LedhouseProveedor.fromJson(json))
            .toList();
      }
    } catch (e) {
      _error = 'Error al cargar proveedores: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createProveedor(LedhouseProveedor proveedor) async {
    try {
      final response = await _http.post(
        'ledhouse/proveedores',
        proveedor.toJson(),
      );
      if (response != null && response['data'] != null) {
        final newProveedor = LedhouseProveedor.fromJson(response['data']);
        _proveedores.add(newProveedor);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProveedor(LedhouseProveedor proveedor) async {
    try {
      final response = await _http.put(
        'ledhouse/proveedores/${proveedor.id}',
        proveedor.toJson(),
      );
      if (response != null && response['data'] != null) {
        final index = _proveedores.indexWhere((p) => p.id == proveedor.id);
        if (index != -1) {
          _proveedores[index] = LedhouseProveedor.fromJson(response['data']);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProveedor(int id) async {
    try {
      await _http.delete('ledhouse/proveedores/$id');
      _proveedores.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
