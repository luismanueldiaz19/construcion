import 'package:flutter/material.dart';
import '../../../models/employee.dart';
import '../../../models/nomina_catalogs.dart';
import '../../../services/nomina_service.dart';

/// EmployeesProvider — Estado del listado y formulario de empleados.
class EmployeesProvider extends ChangeNotifier {
  final NominaService _service = NominaService();

  // ── Estado del listado ──
  bool isLoading = false;
  String? error;
  List<Employee> employees = [];
  int currentPage = 1;
  int lastPage = 1;
  int total = 0;

  // ── Filtros ──
  String? filterStatus;
  int? filterDepartmentId;
  int? filterPayrollGroupId;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  // ── Catálogos (para formularios y filtros) ──
  List<Department> departments = [];
  List<Position> positions = [];
  List<PayrollGroup> payrollGroups = [];
  List<WorkSchedule> workSchedules = [];
  List<Afp> afps = [];
  List<Ars> arss = [];
  List<Bank> banks = [];
  bool catalogsLoaded = false;

  // ── Empleado seleccionado (detalle) ──
  Employee? selectedEmployee;
  bool isLoadingDetail = false;

  // ── Salary History ──
  List<SalaryHistoryEntry> salaryHistory = [];

  EmployeesProvider() {
    searchController.addListener(_onSearchChanged);
    loadEmployees();
    loadCatalogs();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (searchController.text != searchQuery) {
      searchQuery = searchController.text;
      currentPage = 1;
      loadEmployees();
    }
  }

  // ── CATÁLOGOS ──────────────────────────────────────────────────────

  Future<void> loadCatalogs() async {
    try {
      final results = await Future.wait([
        _service.getDepartments(),
        _service.getPayrollGroups(),
        _service.getWorkSchedules(),
        _service.getAfps(),
        _service.getArss(),
        _service.getBanks(),
      ]);
      departments = results[0] as List<Department>;
      payrollGroups = results[1] as List<PayrollGroup>;
      workSchedules = results[2] as List<WorkSchedule>;
      afps = results[3] as List<Afp>;
      arss = results[4] as List<Ars>;
      banks = results[5] as List<Bank>;
      catalogsLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando catálogos: $e');
    }
  }

  Future<void> loadPositionsByDepartment(int departmentId) async {
    try {
      positions = await _service.getPositions(departmentId: departmentId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando posiciones: $e');
    }
  }

  Future<void> loadAllPositions() async {
    try {
      positions = await _service.getPositions();
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando posiciones: $e');
    }
  }

  // ── LISTADO ────────────────────────────────────────────────────────

  Future<void> loadEmployees({bool reset = true}) async {
    if (reset) {
      currentPage = 1;
      employees = [];
    }
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final data = await _service.getEmployees(
        page: currentPage,
        status: filterStatus,
        departmentId: filterDepartmentId,
        payrollGroupId: filterPayrollGroupId,
        search: searchQuery.isEmpty ? null : searchQuery,
      );
      final List rawList = data['data'] ?? [];
      employees = rawList.map((j) => Employee.fromJson(j)).toList();
      currentPage = data['current_page'] ?? 1;
      lastPage = data['last_page'] ?? 1;
      total = data['total'] ?? 0;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNextPage() async {
    if (currentPage >= lastPage || isLoading) return;
    currentPage++;
    await loadEmployees(reset: false);
  }

  void setFilter({String? status, int? departmentId, int? payrollGroupId}) {
    filterStatus = status;
    filterDepartmentId = departmentId;
    filterPayrollGroupId = payrollGroupId;
    currentPage = 1;
    loadEmployees();
  }

  void clearFilters() {
    filterStatus = null;
    filterDepartmentId = null;
    filterPayrollGroupId = null;
    searchController.clear();
    searchQuery = '';
    loadEmployees();
  }

  bool get hasActiveFilters =>
      filterStatus != null ||
      filterDepartmentId != null ||
      filterPayrollGroupId != null ||
      searchQuery.isNotEmpty;

  // ── DETALLE ────────────────────────────────────────────────────────

  Future<void> loadEmployee(int id) async {
    isLoadingDetail = true;
    selectedEmployee = null;
    notifyListeners();
    try {
      selectedEmployee = await _service.getEmployee(id);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoadingDetail = false;
      notifyListeners();
    }
  }

  // ── CRUD ───────────────────────────────────────────────────────────

  Future<bool> createEmployee(Map<String, dynamic> data) async {
    try {
      await _service.createEmployee(data);
      await loadEmployees();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEmployee(int id, Map<String, dynamic> data) async {
    try {
      final updated = await _service.updateEmployee(id, data);
      final idx = employees.indexWhere((e) => e.id == id);
      if (idx != -1) employees[idx] = updated;
      if (selectedEmployee?.id == id) selectedEmployee = updated;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEmployee(int id) async {
    try {
      await _service.deleteEmployee(id);
      employees.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── ACCIONES ESPECIALES ────────────────────────────────────────────

  Future<bool> changeSalary(
    int id,
    double newSalary,
    String effectiveDate,
    String reason,
  ) async {
    try {
      await _service.changeSalary(id, newSalary, effectiveDate, reason);
      await loadEmployee(id);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> changeStatus(int id, String newStatus, {String? reason}) async {
    try {
      await _service.changeStatus(id, newStatus, reason: reason);
      await loadEmployee(id);
      await loadEmployees();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> terminate(
    int id, {
    required String terminationDate,
    required String terminationType,
    required String reason,
  }) async {
    try {
      final result = await _service.terminate(
        id,
        terminationDate: terminationDate,
        terminationType: terminationType,
        reason: reason,
      );
      await loadEmployees();
      return result;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}
