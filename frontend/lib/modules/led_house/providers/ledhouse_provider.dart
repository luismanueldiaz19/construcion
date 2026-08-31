import 'package:flutter/material.dart';
import '../models/ledhouse_estado_resultado_model.dart';
import '../services/ledhouse_service.dart';

class LedhouseProvider with ChangeNotifier {
  final LedhouseService _service = LedhouseService();

  List<LedhouseEstadoResultado> _registros = [];
  bool _isLoading = false;
  String? _error;

  // Resumen
  double _total = 0;
  List<Map<String, dynamic>> _pieChartData = [];
  List<Map<String, dynamic>> _barChartData = [];

  // Matriz Anual
  Map<String, dynamic> _matrizData = {};
  bool _isMatrizLoading = false;

  List<LedhouseEstadoResultado> get registros => _registros;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get total => _total;
  List<Map<String, dynamic>> get pieChartData => _pieChartData;
  List<Map<String, dynamic>> get barChartData => _barChartData;
  Map<String, dynamic> get matrizData => _matrizData;
  bool get isMatrizLoading => _isMatrizLoading;

  Future<void> fetchEstadoResultados({
    String? startDate,
    String? endDate,
    String? modulo,
    String? codigoCuenta,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _registros = await _service.fetchEstadoResultados(
        startDate: startDate,
        endDate: endDate,
        modulo: modulo,
        codigoCuenta: codigoCuenta,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchSummary({
    String? startDate,
    String? endDate,
    String? modulo,
    String? codigoCuenta,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _service.fetchSummary(
        startDate: startDate,
        endDate: endDate,
        modulo: modulo,
        codigoCuenta: codigoCuenta,
      );

      _total = double.tryParse(data['total']?.toString() ?? '0') ?? 0.0;

      if (data['pie_chart'] != null) {
        _pieChartData = List<Map<String, dynamic>>.from(data['pie_chart']);
      }

      if (data['bar_chart'] != null) {
        _barChartData = List<Map<String, dynamic>>.from(data['bar_chart']);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMatrizAnual({int? year}) async {
    _isMatrizLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _service.fetchMatrizAnual(year: year);
      if (data['matriz'] != null) {
        _matrizData = Map<String, dynamic>.from(data['matriz']);
      } else {
        _matrizData = {};
      }
    } catch (e) {
      _error = e.toString();
    }

    _isMatrizLoading = false;
    notifyListeners();
  }

  Future<bool> createRegistro(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.storeEstadoResultado(data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRegistro(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateEstadoResultado(id, data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRegistro(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteEstadoResultado(id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> importRegistros(List<int> fileBytes, String filename, String fecha) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.importEstadoResultado(fileBytes, filename, fecha);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
