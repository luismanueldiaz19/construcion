import 'package:flutter/material.dart';
import '../models/cxp_model.dart';
import '../services/cxp_service.dart';

class CxpProvider with ChangeNotifier {
  final CxpService _service;

  List<CxpModel> _cxps = [];
  bool _isLoading = false;
  String? _error;

  CxpProvider(this._service);

  List<CxpModel> get cxps => _cxps;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCxps() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cxps = await _service.getCxp();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createCxp(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.createCxp(data);
      await fetchCxps();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCxp(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateCxp(id, data);
      await fetchCxps();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
