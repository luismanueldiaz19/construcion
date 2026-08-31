import 'package:flutter/material.dart';
import '../models/cxc_model.dart';
import '../models/cxc_soporte_model.dart';
import '../services/cxc_service.dart';

class CxcProvider with ChangeNotifier {
  final CxcService _service;

  List<CxcModel> _cxcs = [];
  List<Map<String, dynamic>> _clientesAgrupados = [];
  bool _isLoading = false;
  String? _error;

  List<CxcSoporteModel> _soportes = [];
  bool _isLoadingSoportes = false;

  CxcProvider(this._service);

  List<CxcModel> get cxcs => _cxcs;
  List<Map<String, dynamic>> get clientesAgrupados => _clientesAgrupados;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<CxcSoporteModel> get soportes => _soportes;
  bool get isLoadingSoportes => _isLoadingSoportes;

  Future<void> fetchCxcs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getCxc(),
        _service.getGroupedByCliente(),
      ]);
      _cxcs = results[0] as List<CxcModel>;
      _clientesAgrupados = results[1] as List<Map<String, dynamic>>;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createCxc(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.createCxc(data);
      await fetchCxcs();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCxc(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateCxc(id, data);
      await fetchCxcs();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCxc(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteCxc(id);
      await fetchCxcs();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchSoportes(int cxcId) async {
    _isLoadingSoportes = true;
    notifyListeners();

    try {
      _soportes = await _service.getSoportes(cxcId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoadingSoportes = false;
    notifyListeners();
  }

  Future<bool> addSoporte(int cxcId, Map<String, dynamic> data) async {
    _isLoadingSoportes = true;
    notifyListeners();

    try {
      await _service.addSoporte(cxcId, data);
      await fetchSoportes(cxcId);
      await fetchCxcs(); // Actualiza total intervenciones y fecha
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoadingSoportes = false;
      notifyListeners();
      return false;
    }
  }
}
