import 'package:flutter/foundation.dart';
import '../models/ledhouse_cliente.dart';
import '../services/ledhouse_cliente_service.dart';

class LedhouseClienteProvider with ChangeNotifier {
  final LedhouseClienteService _service = LedhouseClienteService();
  List<LedhouseCliente> _clientes = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<LedhouseCliente> get clientes => _clientes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchClientes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _clientes = await _service.getClientes(search: _searchQuery.isNotEmpty ? _searchQuery : null);
    } catch (e) {
      _error = 'Error al cargar clientes: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createCliente(LedhouseCliente cliente) async {
    try {
      final newCliente = await _service.createCliente(cliente);
      _clientes.add(newCliente);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCliente(LedhouseCliente cliente) async {
    try {
      final updatedCliente = await _service.updateCliente(cliente);
      final index = _clientes.indexWhere((c) => c.id == cliente.id);
      if (index != -1) {
        _clientes[index] = updatedCliente;
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCliente(int id) async {
    try {
      await _service.deleteCliente(id);
      _clientes.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> importExcel(List<int> fileBytes, String filename) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _service.importExcel(fileBytes, filename);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
