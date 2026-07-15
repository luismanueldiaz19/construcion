import 'nomina_catalogs.dart';

class Employee {
  final int id;
  final String employeeCode;
  final String firstName;
  final String lastName;
  final String fullName;
  final String identificationNumber;
  final String identificationType;
  final String? email;
  final String? phone;
  final String employmentStatus;
  final String contractType;
  final String? contractEndDate;
  final String hireDate;
  final String? terminationDate;
  final double baseSalary;
  final String salaryType;
  final String paymentMethod;
  final int? departmentId;
  final int? positionId;
  final int? payrollGroupId;
  final int? workScheduleId;
  final int? afpId;
  final int? arsId;
  final int? bankId;
  final int? supervisorId;
  final bool isTssExempt;
  final bool isIsrExempt;
  final String? tssNumber;
  final String? gender;
  final String? maritalStatus;
  final String? nationality;
  final String? address;
  final String? city;
  final String? province;
  final String? bankAccountNumber;
  final String? bankAccountType;

  // Relaciones anidadas (opcional)
  final Department? department;
  final Position? position;
  final PayrollGroup? payrollGroup;
  final Afp? afp;
  final Ars? ars;
  final Bank? bank;

  Employee({
    required this.id,
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.identificationNumber,
    required this.identificationType,
    required this.hireDate,
    required this.employmentStatus,
    required this.contractType,
    required this.baseSalary,
    required this.salaryType,
    required this.paymentMethod,
    this.email,
    this.phone,
    this.contractEndDate,
    this.terminationDate,
    this.departmentId,
    this.positionId,
    this.payrollGroupId,
    this.workScheduleId,
    this.afpId,
    this.arsId,
    this.bankId,
    this.supervisorId,
    this.isTssExempt = false,
    this.isIsrExempt = false,
    this.tssNumber,
    this.gender,
    this.maritalStatus,
    this.nationality,
    this.address,
    this.city,
    this.province,
    this.bankAccountNumber,
    this.bankAccountType,
    this.department,
    this.position,
    this.payrollGroup,
    this.afp,
    this.ars,
    this.bank,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      employeeCode: json['employee_code'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ??
          '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      identificationNumber: json['identification_number'] ?? '',
      identificationType: json['identification_type'] ?? 'cedula',
      email: json['email'],
      phone: json['phone'],
      employmentStatus: json['employment_status'] ?? 'activo',
      contractType: json['contract_type'] ?? 'indefinido',
      contractEndDate: json['contract_end_date'],
      hireDate: json['hire_date'] ?? '',
      terminationDate: json['termination_date'],
      baseSalary:
          double.tryParse(json['base_salary']?.toString() ?? '0') ?? 0.0,
      salaryType: json['salary_type'] ?? 'fijo',
      paymentMethod: json['payment_method'] ?? 'transferencia',
      departmentId: json['department_id'],
      positionId: json['position_id'],
      payrollGroupId: json['payroll_group_id'],
      workScheduleId: json['work_schedule_id'],
      afpId: json['afp_id'],
      arsId: json['ars_id'],
      bankId: json['bank_id'],
      supervisorId: json['supervisor_id'],
      isTssExempt: json['is_tss_exempt'] == true,
      isIsrExempt: json['is_isr_exempt'] == true,
      tssNumber: json['tss_number'],
      gender: json['gender'],
      maritalStatus: json['marital_status'],
      nationality: json['nationality'],
      address: json['address'],
      city: json['city'],
      province: json['province'],
      bankAccountNumber: json['bank_account_number'],
      bankAccountType: json['bank_account_type'],
      department: json['department'] != null
          ? Department.fromJson(json['department'])
          : null,
      position:
          json['position'] != null ? Position.fromJson(json['position']) : null,
      payrollGroup: json['payroll_group'] != null
          ? PayrollGroup.fromJson(json['payroll_group'])
          : null,
      afp: json['afp'] != null ? Afp.fromJson(json['afp']) : null,
      ars: json['ars'] != null ? Ars.fromJson(json['ars']) : null,
      bank: json['bank'] != null ? Bank.fromJson(json['bank']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'identification_type': identificationType,
        'identification_number': identificationNumber,
        'email': email,
        'phone': phone,
        'hire_date': hireDate,
        'employment_status': employmentStatus,
        'contract_type': contractType,
        if (contractEndDate != null) 'contract_end_date': contractEndDate,
        'base_salary': baseSalary,
        'salary_type': salaryType,
        'payment_method': paymentMethod,
        if (departmentId != null) 'department_id': departmentId,
        if (positionId != null) 'position_id': positionId,
        if (payrollGroupId != null) 'payroll_group_id': payrollGroupId,
        if (workScheduleId != null) 'work_schedule_id': workScheduleId,
        if (afpId != null) 'afp_id': afpId,
        if (arsId != null) 'ars_id': arsId,
        if (bankId != null) 'bank_id': bankId,
        if (supervisorId != null) 'supervisor_id': supervisorId,
        'is_tss_exempt': isTssExempt,
        'is_isr_exempt': isIsrExempt,
        if (tssNumber != null) 'tss_number': tssNumber,
        if (gender != null) 'gender': gender,
        if (maritalStatus != null) 'marital_status': maritalStatus,
        if (nationality != null) 'nationality': nationality,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (province != null) 'province': province,
        if (bankAccountNumber != null) 'bank_account_number': bankAccountNumber,
        if (bankAccountType != null) 'bank_account_type': bankAccountType,
      };

  bool get isActive => employmentStatus == 'activo';
}

class SalaryHistoryEntry {
  final int id;
  final double previousSalary;
  final double newSalary;
  final String effectiveDate;
  final String reason;
  final String? approvedByName;

  SalaryHistoryEntry({
    required this.id,
    required this.previousSalary,
    required this.newSalary,
    required this.effectiveDate,
    required this.reason,
    this.approvedByName,
  });

  factory SalaryHistoryEntry.fromJson(Map<String, dynamic> json) =>
      SalaryHistoryEntry(
        id: json['id'],
        previousSalary:
            double.tryParse(json['previous_salary']?.toString() ?? '0') ?? 0,
        newSalary:
            double.tryParse(json['new_salary']?.toString() ?? '0') ?? 0,
        effectiveDate: json['effective_date'] ?? '',
        reason: json['reason'] ?? '',
        approvedByName: json['approved_by']?['name'],
      );
}
