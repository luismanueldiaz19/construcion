class PayrollPeriod {
  final int id;
  final int payrollGroupId;
  final String startDate;
  final String endDate;
  final String paymentDate;
  final int fiscalYear;
  final int periodNumber;
  final String status;
  final String? groupName;
  final String? groupFrequency;

  PayrollPeriod({
    required this.id,
    required this.payrollGroupId,
    required this.startDate,
    required this.endDate,
    required this.paymentDate,
    required this.fiscalYear,
    required this.periodNumber,
    required this.status,
    this.groupName,
    this.groupFrequency,
  });

  factory PayrollPeriod.fromJson(Map<String, dynamic> json) => PayrollPeriod(
        id: json['id'],
        payrollGroupId: json['payroll_group_id'],
        startDate: json['start_date'] ?? '',
        endDate: json['end_date'] ?? '',
        paymentDate: json['payment_date'] ?? '',
        fiscalYear: json['fiscal_year'] ?? DateTime.now().year,
        periodNumber: json['period_number'] ?? 1,
        status: json['status'] ?? 'abierto',
        groupName: json['payroll_group']?['name'],
        groupFrequency: json['payroll_group']?['frequency'],
      );

  String get statusLabel => switch (status) {
        'abierto' => 'Abierto',
        'calculado' => 'Calculado',
        'revisado' => 'Revisado',
        'aprobado' => 'Aprobado',
        'pagado' => 'Pagado',
        'cerrado' => 'Cerrado',
        _ => status,
      };

  bool get isClosed => status == 'cerrado';
}

class Payroll {
  final int id;
  final int payrollPeriodId;
  final String status;
  final double totalGross;
  final double totalDeductions;
  final double totalNet;
  final double totalEmployerCost;
  final double totalIsr;
  final double totalTssEmployee;
  final double totalTssEmployer;
  final String? processedAt;
  final String? approvedAt;
  final String? paidAt;
  final String? notes;
  final PayrollPeriod? period;

  Payroll({
    required this.id,
    required this.payrollPeriodId,
    required this.status,
    required this.totalGross,
    required this.totalDeductions,
    required this.totalNet,
    required this.totalEmployerCost,
    required this.totalIsr,
    required this.totalTssEmployee,
    required this.totalTssEmployer,
    this.processedAt,
    this.approvedAt,
    this.paidAt,
    this.notes,
    this.period,
  });

  factory Payroll.fromJson(Map<String, dynamic> json) => Payroll(
        id: json['id'],
        payrollPeriodId: json['payroll_period_id'],
        status: json['status'] ?? 'borrador',
        totalGross: double.tryParse(json['total_gross']?.toString() ?? '0') ?? 0,
        totalDeductions:
            double.tryParse(json['total_deductions']?.toString() ?? '0') ?? 0,
        totalNet: double.tryParse(json['total_net']?.toString() ?? '0') ?? 0,
        totalEmployerCost:
            double.tryParse(json['total_employer_cost']?.toString() ?? '0') ?? 0,
        totalIsr: double.tryParse(json['total_isr']?.toString() ?? '0') ?? 0,
        totalTssEmployee:
            double.tryParse(json['total_tss_employee']?.toString() ?? '0') ?? 0,
        totalTssEmployer:
            double.tryParse(json['total_tss_employer']?.toString() ?? '0') ?? 0,
        processedAt: json['processed_at'],
        approvedAt: json['approved_at'],
        paidAt: json['paid_at'],
        notes: json['notes'],
        period: json['period'] != null
            ? PayrollPeriod.fromJson(json['period'])
            : null,
      );

  String get statusLabel => switch (status) {
        'borrador' => 'Borrador',
        'calculado' => 'Calculado',
        'revisado' => 'Revisado',
        'aprobado' => 'Aprobado',
        'pagado' => 'Pagado',
        'cerrado' => 'Cerrado',
        _ => status,
      };

  bool get isEditable => status == 'borrador' || status == 'calculado';
  bool get isClosed => status == 'cerrado';
}

class PayrollLoan {
  final int id;
  final int employeeId;
  final String loanType;
  final double originalAmount;
  final double outstandingBalance;
  final double monthlyInstallment;
  final int? totalInstallments;
  final int? remainingInstallments;
  final String startDate;
  final String status;
  final String? description;

  PayrollLoan({
    required this.id,
    required this.employeeId,
    required this.loanType,
    required this.originalAmount,
    required this.outstandingBalance,
    required this.monthlyInstallment,
    required this.startDate,
    required this.status,
    this.totalInstallments,
    this.remainingInstallments,
    this.description,
  });

  factory PayrollLoan.fromJson(Map<String, dynamic> json) => PayrollLoan(
        id: json['id'],
        employeeId: json['employee_id'],
        loanType: json['loan_type'] ?? 'prestamo',
        originalAmount:
            double.tryParse(json['original_amount']?.toString() ?? '0') ?? 0,
        outstandingBalance:
            double.tryParse(json['outstanding_balance']?.toString() ?? '0') ??
                0,
        monthlyInstallment:
            double.tryParse(json['monthly_installment']?.toString() ?? '0') ??
                0,
        totalInstallments: json['total_installments'],
        remainingInstallments: json['remaining_installments'],
        startDate: json['start_date'] ?? '',
        status: json['status'] ?? 'activo',
        description: json['description'],
      );

  String get loanTypeLabel => switch (loanType) {
        'prestamo' => 'Préstamo',
        'adelanto' => 'Adelanto',
        'embargo_judicial' => 'Embargo Judicial',
        'cuota_sindical' => 'Cuota Sindical',
        _ => 'Otro',
      };
}
