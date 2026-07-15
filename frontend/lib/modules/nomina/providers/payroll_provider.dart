import 'package:flutter/material.dart';
import '../../../models/nomina_catalogs.dart';
import '../../../models/payroll.dart';
import '../../../services/nomina_service.dart';

class PayrollProvider extends ChangeNotifier {
  final NominaService _service = NominaService();

  // ── Periodos ──
  bool isLoadingPeriods = false;
  List<PayrollPeriod> periods = [];

  // ── Nóminas ──
  bool isLoadingPayrolls = false;
  List<Payroll> payrolls = [];

  // ── Catálogos ──
  List<PayrollGroup> payrollGroups = [];

  // ── Nómina seleccionada ──
  Payroll? selectedPayroll;
  bool isLoadingDetail = false;

  // ── Detalles por empleado ──
  Map<String, dynamic>? employeePayrollDetail;

  String? error;

  PayrollProvider() {
    _init();
  }

  Future<void> _init() async {
    await Future.wait([loadPayrolls(), loadPeriods(), _loadGroups()]);
  }

  Future<void> _loadGroups() async {
    try {
      payrollGroups = await _service.getPayrollGroups();
      notifyListeners();
    } catch (_) {}
  }

  // ── PERIODOS ──────────────────────────────────────────────────────

  Future<void> loadPeriods({int? groupId, String? status}) async {
    isLoadingPeriods = true;
    notifyListeners();
    try {
      final data = await _service.getPayrollPeriods(
        payrollGroupId: groupId,
        status: status,
        fiscalYear: DateTime.now().year,
      );
      final List raw = data['data'] ?? [];
      periods = raw.map((j) => PayrollPeriod.fromJson(j)).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoadingPeriods = false;
      notifyListeners();
    }
  }

  Future<PayrollPeriod?> createPeriod(Map<String, dynamic> data) async {
    try {
      final period = await _service.createPayrollPeriod(data);
      periods.insert(0, period);
      notifyListeners();
      return period;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deletePeriod(int id) async {
    try {
      await _service.deletePayrollPeriod(id);
      await loadPeriods();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── NÓMINAS ───────────────────────────────────────────────────────

  Future<void> loadPayrolls({String? status}) async {
    isLoadingPayrolls = true;
    notifyListeners();
    try {
      final data = await _service.getPayrolls(status: status);
      final List raw = data['data'] ?? [];
      payrolls = raw.map((j) => Payroll.fromJson(j)).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoadingPayrolls = false;
      notifyListeners();
    }
  }

  Future<Payroll?> createDraft(int periodId, {String? notes}) async {
    try {
      final p = await _service.createPayrollDraft(periodId, notes: notes);
      payrolls.insert(0, p);
      notifyListeners();
      return p;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deletePayroll(int id) async {
    try {
      await _service.deletePayroll(id);
      await loadPayrolls();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadPayroll(int id) async {
    isLoadingDetail = true;
    notifyListeners();
    try {
      selectedPayroll = await _service.getPayroll(id);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoadingDetail = false;
      notifyListeners();
    }
  }

  Future<bool> calculate(int id) async {
    try {
      final updated = await _service.calculatePayroll(id);
      _replaceInList(updated);
      selectedPayroll = updated;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> review(int id) async {
    try {
      await _service.reviewPayroll(id);
      await loadPayroll(id);
      await loadPayrolls();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> approve(int id) async {
    try {
      await _service.approvePayroll(id);
      await loadPayroll(id);
      await loadPayrolls();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markPaid(int id) async {
    try {
      await _service.markPayrollPaid(id);
      await loadPayroll(id);
      await loadPayrolls();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> close(int id) async {
    try {
      await _service.closePayroll(id);
      await loadPayroll(id);
      await loadPayrolls();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> forceDelete(int id) async {
    try {
      await _service.forceDeletePayroll(id);
      selectedPayroll = null;
      await loadPayrolls();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadEmployeeDetail(int payrollId, int employeeId) async {
    try {
      employeePayrollDetail = await _service.getPayrollEmployeeDetail(
        payrollId,
        employeeId,
      );
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  void _replaceInList(Payroll updated) {
    final idx = payrolls.indexWhere((p) => p.id == updated.id);
    if (idx != -1) payrolls[idx] = updated;
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}
