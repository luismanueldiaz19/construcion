import 'package:flutter/material.dart';
import '../../../models/nomina_catalogs.dart';
import '../../../services/nomina_service.dart';

class NominaCatalogsProvider extends ChangeNotifier {
  final NominaService _service = NominaService();

  bool isLoading = false;
  String? error;

  List<Department> departments = [];
  List<Position> positions = [];

  NominaCatalogsProvider() {
    loadCatalogs();
  }

  Future<void> loadCatalogs() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getDepartments(),
        _service.getPositions(),
      ]);
      departments = results[0] as List<Department>;
      positions = results[1] as List<Position>;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveDepartment(Map<String, dynamic> data, {int? id}) async {
    try {
      if (id != null) {
        await _service.updateDepartment(id, data);
      } else {
        await _service.createDepartment(data['name'], costCenterCode: data['cost_center_code']);
      }
      await loadCatalogs();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> savePosition(Map<String, dynamic> data, {int? id}) async {
    try {
      if (id != null) {
        await _service.updatePosition(id, data);
      } else {
        await _service.createPosition(data);
      }
      await loadCatalogs();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
