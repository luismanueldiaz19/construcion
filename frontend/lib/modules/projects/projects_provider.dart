import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ProjectsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _proyectos = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get proyectos => _proyectos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProyectos({
    String? estado,
    int? year,
    String? search,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _proyectos = await _apiService.getProyectos(
        estado: estado,
        year: year,
        search: search,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProyecto(int id) async {
    try {
      await _apiService.deleteProyecto(id);
      _proyectos.removeWhere((p) => p['id'] == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
