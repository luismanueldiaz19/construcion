import 'package:flutter/material.dart';
import '../models/cuenta_catalogo_model.dart';
import '../services/cuenta_catalogo_service.dart';

class CuentaCatalogoProvider extends ChangeNotifier {
  final CuentaCatalogoService _service = CuentaCatalogoService();

  List<CuentaCatalogo> _cuentas = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';

  List<CuentaCatalogo> get cuentas => _cuentas;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchCuentas();
  }

  Future<void> fetchCuentas() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _cuentas = await _service.fetchCuentas(search: _searchQuery);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCuenta(Map<String, dynamic> data) async {
    try {
      final nueva = await _service.storeCuenta(data);
      _cuentas.add(nueva);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCuenta(int id, Map<String, dynamic> data) async {
    try {
      final actualizada = await _service.updateCuenta(id, data);
      final index = _cuentas.indexWhere((c) => c.id == id);
      if (index != -1) {
        _cuentas[index] = actualizada;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCuenta(int id) async {
    try {
      await _service.deleteCuenta(id);
      _cuentas.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> importCuentas(List<int> bytes, String filename) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _service.importCuentas(bytes, filename);
      await fetchCuentas();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
