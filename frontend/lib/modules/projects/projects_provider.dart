import 'package:flutter/material.dart';
import '../../services/project_service.dart';
import '../../models/proyecto.dart';

class ProjectsProvider extends ChangeNotifier {
  final ProjectService _projectService = ProjectService();
  
  List<Proyecto> _proyectos = [];
  bool _isLoading = false;
  String? _error;

  List<Proyecto> get proyectos => _proyectos;
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
      _proyectos = await _projectService.getProyectos(
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
      await _projectService.deleteProyecto(id);
      _proyectos.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
