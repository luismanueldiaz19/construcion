import 'package:flutter/material.dart';
import '../../../models/employee.dart';

// ─────────────────────────────────────────────────────
//  EmployeeStatusBadge
// ─────────────────────────────────────────────────────
class EmployeeStatusBadge extends StatelessWidget {
  final String status;
  const EmployeeStatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'activo' => ('Activo', const Color(0xFF2E7D32)),
      'vacaciones' => ('Vacaciones', const Color(0xFF1565C0)),
      'licencia' => ('Licencia', const Color(0xFFE65100)),
      'suspendido' => ('Suspendido', const Color(0xFF6A1B9A)),
      'inactivo' => ('Inactivo', const Color(0xFF757575)),
      'desvinculado' => ('Desvinculado', const Color(0xFFC62828)),
      _ => (status, const Color(0xFF757575)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  PayrollStatusBadge
// ─────────────────────────────────────────────────────
class PayrollStatusBadge extends StatelessWidget {
  final String status;
  const PayrollStatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'borrador' => ('Borrador', const Color(0xFF757575), Icons.edit_note),
      'calculado' => ('Calculado', const Color(0xFF1565C0), Icons.calculate),
      'revisado' => ('Revisado', const Color(0xFFE65100), Icons.fact_check),
      'aprobado' => ('Aprobado', const Color(0xFF2E7D32), Icons.verified),
      'pagado' => ('Pagado', const Color(0xFF00796B), Icons.payments),
      'cerrado' => ('Cerrado', const Color(0xFF1A1C1E), Icons.lock),
      _ => (status, const Color(0xFF757575), Icons.info),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  EmployeeCard — Tarjeta de empleado para el listado
// ─────────────────────────────────────────────────────
class EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const EmployeeCard({
    super.key,
    required this.employee,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(employee.fullName);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1.5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar con iniciales
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF1E3A5F),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            employee.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        EmployeeStatusBadge(employee.employmentStatus),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${employee.employeeCode} · ${employee.position?.title ?? 'Sin cargo'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.apartment,
                          size: 11,
                          color: Color(0xFF999999),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          employee.department?.name ?? 'Sin departamento',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF999999),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.attach_money,
                          size: 11,
                          color: Color(0xFF999999),
                        ),
                        Text(
                          _formatSalary(employee.baseSalary),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: const Color(0xFF666666),
                  onPressed: onEdit,
                  tooltip: 'Editar',
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _formatSalary(double amount) {
    if (amount >= 1000) {
      return 'RD\$ ${(amount / 1000).toStringAsFixed(1)}k';
    }
    return 'RD\$ ${amount.toStringAsFixed(0)}';
  }
}

// ─────────────────────────────────────────────────────
//  SalaryInfoCard — Tarjeta de resumen de salario
// ─────────────────────────────────────────────────────
class SalaryInfoCard extends StatelessWidget {
  final double baseSalary;
  final String salaryType;
  final String paymentMethod;

  const SalaryInfoCard({
    super.key,
    required this.baseSalary,
    required this.salaryType,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF2C5282)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: Colors.white70,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Salario Base',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  'RD\$ ${_fmt(baseSalary)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _tag(_salaryTypeLabel(salaryType)),
              const SizedBox(height: 4),
              _tag(_paymentLabel(paymentMethod)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      style: const TextStyle(color: Colors.white, fontSize: 10),
    ),
  );

  String _fmt(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$intPart.${parts[1]}';
  }

  String _salaryTypeLabel(String t) => switch (t) {
    'fijo' => 'Fijo',
    'por_hora' => 'Por hora',
    'comision' => 'Comisión',
    'mixto' => 'Mixto',
    _ => t,
  };

  String _paymentLabel(String t) => switch (t) {
    'transferencia' => 'Transferencia',
    'cheque' => 'Cheque',
    'efectivo' => 'Efectivo',
    _ => t,
  };
}
