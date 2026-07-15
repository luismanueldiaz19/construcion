// ignore_for_file: non_constant_identifier_names

class Department {
  final int id;
  final String name;
  final String? costCenterCode;
  final bool isActive;

  Department({
    required this.id,
    required this.name,
    this.costCenterCode,
    this.isActive = true,
  });

  factory Department.fromJson(Map<String, dynamic> json) => Department(
        id: json['id'],
        name: json['name'] ?? '',
        costCenterCode: json['cost_center_code'],
        isActive: json['is_active'] == true,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'cost_center_code': costCenterCode,
      };

  @override
  String toString() => name;
}

class Position {
  final int id;
  final String title;
  final int? departmentId;
  final double? salaryMin;
  final double? salaryMax;
  final bool isActive;

  Position({
    required this.id,
    required this.title,
    this.departmentId,
    this.salaryMin,
    this.salaryMax,
    this.isActive = true,
  });

  factory Position.fromJson(Map<String, dynamic> json) => Position(
        id: json['id'],
        title: json['title'] ?? '',
        departmentId: json['department_id'],
        salaryMin: json['salary_min'] != null
            ? double.tryParse(json['salary_min'].toString())
            : null,
        salaryMax: json['salary_max'] != null
            ? double.tryParse(json['salary_max'].toString())
            : null,
        isActive: json['is_active'] == true,
      );

  @override
  String toString() => title;
}

class PayrollGroup {
  final int id;
  final String name;
  final String frequency;
  final bool isActive;

  PayrollGroup({
    required this.id,
    required this.name,
    required this.frequency,
    this.isActive = true,
  });

  factory PayrollGroup.fromJson(Map<String, dynamic> json) => PayrollGroup(
        id: json['id'],
        name: json['name'] ?? '',
        frequency: json['frequency'] ?? 'monthly',
        isActive: json['is_active'] == true,
      );

  String get frequencyLabel => switch (frequency) {
        'weekly' => 'Semanal',
        'biweekly' => 'Quincenal',
        'monthly' => 'Mensual',
        _ => frequency,
      };

  @override
  String toString() => '$name ($frequencyLabel)';
}

class WorkSchedule {
  final int id;
  final String name;
  final bool isActive;

  WorkSchedule({required this.id, required this.name, this.isActive = true});

  factory WorkSchedule.fromJson(Map<String, dynamic> json) => WorkSchedule(
        id: json['id'],
        name: json['name'] ?? '',
        isActive: json['is_active'] == true,
      );

  @override
  String toString() => name;
}

class Afp {
  final int id;
  final String name;
  final String? code;

  Afp({required this.id, required this.name, this.code});

  factory Afp.fromJson(Map<String, dynamic> json) =>
      Afp(id: json['id'], name: json['name'] ?? '', code: json['code']);

  @override
  String toString() => name;
}

class Ars {
  final int id;
  final String name;
  final String? code;

  Ars({required this.id, required this.name, this.code});

  factory Ars.fromJson(Map<String, dynamic> json) =>
      Ars(id: json['id'], name: json['name'] ?? '', code: json['code']);

  @override
  String toString() => name;
}

class Bank {
  final int id;
  final String name;
  final String? code;

  Bank({required this.id, required this.name, this.code});

  factory Bank.fromJson(Map<String, dynamic> json) =>
      Bank(id: json['id'], name: json['name'] ?? '', code: json['code']);

  @override
  String toString() => name;
}
