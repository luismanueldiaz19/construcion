import '../models/employee.dart';
import '../models/nomina_catalogs.dart';
import '../models/payroll.dart';
import 'http_service.dart';

/// NominaService — Todos los llamados HTTP del módulo de nómina.
/// Sigue el patrón del proyecto: HttpService + modelos tipados.
class NominaService {
  final HttpService _http = HttpService();

  Future<Map<String, dynamic>> getReportNominaConsolidada(int payrollId) async {
    final data = await _http.get(
      'nomina/reports/nomina-consolidada?payroll_id=$payrollId',
    );
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getReportPlanillaTSS(int payrollId) async {
    final data = await _http.get(
      'nomina/reports/planilla-tss?payroll_id=$payrollId',
    );
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getReportRetencionesISR(int payrollId) async {
    final data = await _http.get(
      'nomina/reports/retenciones-isr?payroll_id=$payrollId',
    );
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getReportProvisiones(
    String fromDate,
    String toDate,
  ) async {
    final data = await _http.get(
      'nomina/reports/provisiones?from=$fromDate&to=$toDate',
    );
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getReportHistorialSalarios(
    String fromDate,
    String toDate,
  ) async {
    final data = await _http.get(
      'nomina/reports/historial-salarios?from=$fromDate&to=$toDate',
    );
    return data as Map<String, dynamic>;
  }

  // ──────────────────────────────────────────────────────────
  //  CATÁLOGOS (datos de referencia para formularios)
  // ──────────────────────────────────────────────────────────

  Future<List<Department>> getDepartments() async {
    final data = await _http.get('nomina/departments') as List;
    return data.map((j) => Department.fromJson(j)).toList();
  }

  Future<Department> createDepartment(
    String name, {
    String? costCenterCode,
  }) async {
    final res = await _http.post('nomina/departments', {
      'name': name,
      if (costCenterCode != null) 'cost_center_code': costCenterCode,
    });
    return Department.fromJson(res);
  }

  Future<Department> updateDepartment(int id, Map<String, dynamic> data) async {
    final res = await _http.put('nomina/departments/$id', data);
    return Department.fromJson(res);
  }

  Future<List<Position>> getPositions({int? departmentId}) async {
    final query = departmentId != null
        ? 'nomina/positions?department_id=$departmentId'
        : 'nomina/positions';
    final data = await _http.get(query) as List;
    return data.map((j) => Position.fromJson(j)).toList();
  }

  Future<Position> createPosition(Map<String, dynamic> data) async {
    final res = await _http.post('nomina/positions', data);
    return Position.fromJson(res);
  }

  Future<Position> updatePosition(int id, Map<String, dynamic> data) async {
    final res = await _http.put('nomina/positions/$id', data);
    return Position.fromJson(res);
  }

  Future<List<PayrollGroup>> getPayrollGroups() async {
    final data = await _http.get('nomina/payroll-groups') as List;
    return data.map((j) => PayrollGroup.fromJson(j)).toList();
  }

  Future<List<WorkSchedule>> getWorkSchedules() async {
    final data = await _http.get('nomina/work-schedules') as List;
    return data.map((j) => WorkSchedule.fromJson(j)).toList();
  }

  Future<List<Afp>> getAfps() async {
    final data = await _http.get('nomina/afps') as List;
    return data.map((j) => Afp.fromJson(j)).toList();
  }

  Future<List<Ars>> getArss() async {
    final data = await _http.get('nomina/arss') as List;
    return data.map((j) => Ars.fromJson(j)).toList();
  }

  Future<List<Bank>> getBanks() async {
    final data = await _http.get('nomina/banks') as List;
    return data.map((j) => Bank.fromJson(j)).toList();
  }

  Future<List<Map<String, dynamic>>> getLegalParameters({
    String? category,
  }) async {
    final query = category != null
        ? 'nomina/legal-parameters?category=$category'
        : 'nomina/legal-parameters';
    final data = await _http.get(query) as List;
    return data.cast<Map<String, dynamic>>();
  }

  // ──────────────────────────────────────────────────────────
  //  EMPLEADOS
  // ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getEmployees({
    int page = 1,
    int perPage = 20,
    String? status,
    int? departmentId,
    int? payrollGroupId,
    String? search,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (status != null) 'status': status,
      if (departmentId != null) 'department_id': departmentId.toString(),
      if (payrollGroupId != null) 'payroll_group_id': payrollGroupId.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
    };
    return await _http.get('employees', params: params);
  }

  Future<Employee> getEmployee(int id) async {
    final data = await _http.get('employees/$id');
    return Employee.fromJson(data);
  }

  Future<Employee> createEmployee(Map<String, dynamic> data) async {
    final res = await _http.post('employees', data);
    return Employee.fromJson(res);
  }

  Future<Employee> updateEmployee(int id, Map<String, dynamic> data) async {
    final res = await _http.put('employees/$id', data);
    return Employee.fromJson(res);
  }

  Future<void> deleteEmployee(int id) async {
    await _http.delete('employees/$id');
  }

  Future<void> restoreEmployee(int id) async {
    await _http.post('employees/$id/restore', {});
  }

  /// Cambio de salario — SIEMPRE vía este método (crea histórico inmutable)
  Future<Map<String, dynamic>> changeSalary(
    int id,
    double newSalary,
    String effectiveDate,
    String reason,
  ) async {
    return await _http.post('employees/$id/change-salary', {
      'new_salary': newSalary,
      'effective_date': effectiveDate,
      'reason': reason,
    });
  }

  /// Cambio de estatus — activo/suspendido/vacaciones/licencia
  Future<void> changeStatus(int id, String newStatus, {String? reason}) async {
    await _http.post('employees/$id/change-status', {
      'new_status': newStatus,
      if (reason != null) 'reason': reason,
    });
  }

  /// Desvinculación con cálculo automático de prestaciones
  Future<Map<String, dynamic>> terminate(
    int id, {
    required String terminationDate,
    required String terminationType,
    required String reason,
  }) async {
    return await _http.post('employees/$id/terminate', {
      'termination_date': terminationDate,
      'termination_type': terminationType,
      'reason': reason,
    });
  }

  Future<Map<String, dynamic>> getEmployeeSalaryHistory(int id) async {
    final data = await _http.get('employees/$id/payroll-history');
    return data;
  }

  // ──────────────────────────────────────────────────────────
  //  NÓMINA — PERIODOS Y PROCESO
  // ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getPayrollPeriods({
    int? payrollGroupId,
    String? status,
    int? fiscalYear,
  }) async {
    final params = <String, String>{
      if (payrollGroupId != null) 'payroll_group_id': payrollGroupId.toString(),
      if (status != null) 'status': status,
      if (fiscalYear != null) 'fiscal_year': fiscalYear.toString(),
    };
    return await _http.get('nomina/periods', params: params);
  }

  Future<PayrollPeriod> createPayrollPeriod(Map<String, dynamic> data) async {
    final res = await _http.post('nomina/periods', data);
    return PayrollPeriod.fromJson(res);
  }

  Future<void> deletePayrollPeriod(int id) async {
    await _http.delete('nomina/periods/$id');
  }

  Future<Map<String, dynamic>> getPayrolls({String? status}) async {
    final params = <String, String>{if (status != null) 'status': status};
    return await _http.get('payrolls', params: params);
  }

  Future<Payroll> createPayrollDraft(
    int payrollPeriodId, {
    String? notes,
  }) async {
    final res = await _http.post('payrolls', {
      'payroll_period_id': payrollPeriodId,
      if (notes != null) 'notes': notes,
    });
    return Payroll.fromJson(res);
  }

  Future<Payroll> getPayroll(int id) async {
    final data = await _http.get('payrolls/$id');
    return Payroll.fromJson(data);
  }

  Future<Payroll> calculatePayroll(
    int id, {
    Map<String, dynamic>? extras,
  }) async {
    final res = await _http.post('payrolls/$id/calculate', {
      'extras': extras ?? {},
    });
    return Payroll.fromJson(res['payroll']);
  }

  Future<void> reviewPayroll(int id) async {
    await _http.post('payrolls/$id/review', {});
  }

  Future<void> approvePayroll(int id) async {
    await _http.post('payrolls/$id/approve', {});
  }

  Future<void> markPayrollPaid(int id) async {
    await _http.post('payrolls/$id/mark-paid', {});
  }

  Future<void> closePayroll(int id) async {
    await _http.post('payrolls/$id/close', {});
  }

  Future<void> forceDeletePayroll(int id) async {
    await _http.delete('payrolls/$id/force-delete');
  }

  Future<void> deletePayroll(int id) async {
    await _http.delete('payrolls/$id');
  }

  Future<Map<String, dynamic>> getPayrollEmployeeDetail(
    int payrollId,
    int employeeId,
  ) async {
    return await _http.get('payrolls/$payrollId/employee/$employeeId');
  }

  Future<List<dynamic>> getPayrollEmployeeSummary(int payrollId) async {
    final data = await _http.get('payrolls/$payrollId/employee-summary');
    return data as List<dynamic>;
  }

  // ──────────────────────────────────────────────────────────
  //  PRÉSTAMOS
  // ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getLoans({
    int? employeeId,
    String? status,
  }) async {
    final params = <String, String>{
      if (employeeId != null) 'employee_id': employeeId.toString(),
      if (status != null) 'status': status,
    };
    return await _http.get('payroll-loans', params: params);
  }

  Future<PayrollLoan> createLoan(Map<String, dynamic> data) async {
    final res = await _http.post('payroll-loans', data);
    return PayrollLoan.fromJson(res);
  }

  Future<void> cancelLoan(int id) async {
    await _http.delete('payroll-loans/$id');
  }
}
