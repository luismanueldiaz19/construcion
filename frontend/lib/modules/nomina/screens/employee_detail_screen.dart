import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/employees_provider.dart';
import '../widgets/nomina_widgets.dart';
import '../../../models/employee.dart';

/// Ficha completa del empleado con 4 tabs.
class EmployeeDetailScreen extends StatefulWidget {
  final int employeeId;
  const EmployeeDetailScreen({super.key, required this.employeeId});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeesProvider>().loadEmployee(widget.employeeId);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeesProvider>();

    if (provider.isLoadingDetail) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final emp = provider.selectedEmployee;
    if (emp == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Empleado')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(provider.error ?? 'No se pudo cargar el empleado.'),
              TextButton(
                onPressed: () =>
                    provider.loadEmployee(widget.employeeId),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emp.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(emp.employeeCode,
                style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => _handleAction(context, action, emp),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit',
                  child: ListTile(leading: Icon(Icons.edit), title: Text('Editar datos'))),
              const PopupMenuItem(value: 'salary',
                  child: ListTile(leading: Icon(Icons.attach_money), title: Text('Cambiar salario'))),
              const PopupMenuItem(value: 'status',
                  child: ListTile(leading: Icon(Icons.swap_horiz), title: Text('Cambiar estatus'))),
              if (emp.employmentStatus != 'desvinculado')
                const PopupMenuItem(value: 'terminate',
                    child: ListTile(
                        leading: Icon(Icons.person_remove, color: Colors.red),
                        title: Text('Desvincular', style: TextStyle(color: Colors.red)))),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: const Color(0xFFE31E24),
          unselectedLabelColor: const Color(0xFF666666),
          indicatorColor: const Color(0xFFE31E24),
          tabs: const [
            Tab(text: 'Datos', icon: Icon(Icons.person, size: 18)),
            Tab(text: 'Laboral', icon: Icon(Icons.work, size: 18)),
            Tab(text: 'Salario', icon: Icon(Icons.payments, size: 18)),
            Tab(text: 'TSS / ISR', icon: Icon(Icons.account_balance, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _PersonalTab(emp: emp),
          _LaborTab(emp: emp),
          _SalaryTab(emp: emp, provider: provider),
          _TssTab(emp: emp),
        ],
      ),
    );
  }

  void _handleAction(
      BuildContext context, String action, Employee emp) {
    switch (action) {
      case 'salary':
        _showChangeSalaryDialog(context, emp);
        break;
      case 'status':
        _showChangeStatusDialog(context, emp);
        break;
      case 'terminate':
        _showTerminateDialog(context, emp);
        break;
      case 'edit':
        // Navegar a formulario de edición
        break;
    }
  }

  // ─────────────────────────────────────────────────────
  //  Diálogo: Cambio de Salario (AUDITABLE)
  // ─────────────────────────────────────────────────────
  void _showChangeSalaryDialog(BuildContext context, Employee emp) {
    final salaryCtrl = TextEditingController(
        text: emp.baseSalary.toStringAsFixed(2));
    final reasonCtrl = TextEditingController();
    DateTime effectiveDate = DateTime.now();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: const Text('Cambiar Salario',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Salario actual:',
                    style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
                Text(
                  'RD\$ ${NumberFormat('#,##0.00').format(emp.baseSalary)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: salaryCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Nuevo Salario (RD\$) *',
                    border: OutlineInputBorder(),
                    prefixText: 'RD\$ ',
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: effectiveDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2099),
                    );
                    if (picked != null) {
                      setState(() => effectiveDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha Efectiva *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(effectiveDate)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: reasonCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Motivo del cambio *',
                    hintText: 'Ej: Aumento por mérito, ajuste inflación...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE31E24)),
              onPressed: () async {
                final newSalary =
                    double.tryParse(salaryCtrl.text.replaceAll(',', ''));
                if (newSalary == null || newSalary <= 0) {
                  _snack(context, 'Ingrese un salario válido.', error: true);
                  return;
                }
                if (reasonCtrl.text.trim().length < 5) {
                  _snack(context, 'Ingrese el motivo del cambio.', error: true);
                  return;
                }
                Navigator.pop(context);
                final ok = await context.read<EmployeesProvider>().changeSalary(
                  emp.id,
                  newSalary,
                  DateFormat('yyyy-MM-dd').format(effectiveDate),
                  reasonCtrl.text.trim(),
                );
                if (mounted) {
                  _snack(this.context,
                      ok ? 'Salario actualizado correctamente.' : 'Error al actualizar salario.',
                      error: !ok);
                }
              },
              child: const Text('Guardar Cambio'),
            ),
          ],
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────
  //  Diálogo: Cambio de Estatus
  // ─────────────────────────────────────────────────────
  void _showChangeStatusDialog(BuildContext context, Employee emp) {
    String newStatus = emp.employmentStatus;
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: const Text('Cambiar Estatus',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: newStatus,
                  decoration: const InputDecoration(
                    labelText: 'Nuevo Estatus *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'activo', child: Text('Activo')),
                    DropdownMenuItem(value: 'vacaciones', child: Text('Vacaciones')),
                    DropdownMenuItem(value: 'licencia', child: Text('Licencia')),
                    DropdownMenuItem(value: 'suspendido', child: Text('Suspendido')),
                    DropdownMenuItem(value: 'inactivo', child: Text('Inactivo')),
                  ],
                  onChanged: (v) => setState(() => newStatus = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: reasonCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Motivo (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE31E24)),
              onPressed: () async {
                Navigator.pop(context);
                final ok = await context.read<EmployeesProvider>().changeStatus(
                  emp.id, newStatus,
                  reason: reasonCtrl.text.trim().isNotEmpty
                      ? reasonCtrl.text.trim()
                      : null,
                );
                if (mounted) {
                  _snack(this.context,
                      ok ? 'Estatus actualizado.' : 'Error al cambiar estatus.',
                      error: !ok);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────
  //  Diálogo: Desvinculación + Prestaciones
  // ─────────────────────────────────────────────────────
  void _showTerminateDialog(BuildContext context, Employee emp) {
    String terminationType = 'renuncia';
    DateTime terminationDate = DateTime.now();
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: const Text('Desvinculación',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(children: [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta acción calculará automáticamente las prestaciones laborales según la Ley 16-92.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: terminationType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Desvinculación *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'renuncia', child: Text('Renuncia Voluntaria')),
                    DropdownMenuItem(value: 'despido_injustificado', child: Text('Despido Injustificado')),
                    DropdownMenuItem(value: 'desahucio', child: Text('Desahucio')),
                    DropdownMenuItem(value: 'mutuo_acuerdo', child: Text('Mutuo Acuerdo')),
                  ],
                  onChanged: (v) => setState(() => terminationType = v!),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: terminationDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) setState(() => terminationDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha de Desvinculación *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(terminationDate)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: reasonCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Motivo *',
                    hintText: 'Descripción del motivo de desvinculación',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () async {
                if (reasonCtrl.text.trim().length < 5) {
                  _snack(context, 'Ingrese el motivo de desvinculación.', error: true);
                  return;
                }
                Navigator.pop(context);
                final result = await context.read<EmployeesProvider>().terminate(
                  emp.id,
                  terminationDate: DateFormat('yyyy-MM-dd').format(terminationDate),
                  terminationType: terminationType,
                  reason: reasonCtrl.text.trim(),
                );
                if (mounted && result != null) {
                  _showPrestacionesResult(this.context, result);
                }
              },
              child: const Text('Desvincular y Calcular Prestaciones'),
            ),
          ],
        );
      }),
    );
  }

  void _showPrestacionesResult(BuildContext context, Map<String, dynamic> result) {
    final prest = result['prestaciones'] as Map<String, dynamic>? ?? {};
    final fmt = NumberFormat('#,##0.00');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.calculate, color: Color(0xFF2E7D32)),
          SizedBox(width: 8),
          Text('Prestaciones Calculadas'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _prestRow('Preaviso', prest['preaviso'], fmt),
            _prestRow('Auxilio de Cesantía', prest['cesantia'], fmt),
            _prestRow('Vacaciones Proporcional', prest['vacaciones_proporcional'], fmt),
            _prestRow('Regalía Proporcional', prest['regalia_proporcional'], fmt),
            const Divider(),
            _prestRow('TOTAL', prest['total'], fmt, bold: true),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _prestRow(String label, dynamic value, NumberFormat fmt,
      {bool bold = false}) {
    final amount = double.tryParse(value?.toString() ?? '0') ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text('RD\$ ${fmt.format(amount)}',
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: bold ? const Color(0xFF2E7D32) : null)),
        ],
      ),
    );
  }

  void _snack(BuildContext context, String msg, {bool error = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade700 : const Color(0xFF2E7D32),
    ));
  }
}

// ─────────────────────────────────────────────────────
//  TAB 1: Datos Personales
// ─────────────────────────────────────────────────────
class _PersonalTab extends StatelessWidget {
  final Employee emp;
  const _PersonalTab({required this.emp});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFF1E3A5F),
                  child: Text(
                    _initials(emp.fullName),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emp.fullName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(emp.employeeCode,
                          style: const TextStyle(color: Color(0xFF666666))),
                      const SizedBox(height: 4),
                      EmployeeStatusBadge(emp.employmentStatus),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _infoCard('Identificación', [
          _infoRow(Icons.badge, 'Tipo', _idTypeLabel(emp.identificationType)),
          _infoRow(Icons.numbers, 'Número', emp.identificationNumber),
          if (emp.tssNumber != null)
            _infoRow(Icons.health_and_safety, 'No. TSS', emp.tssNumber!),
        ]),
        const SizedBox(height: 12),
        _infoCard('Contacto', [
          if (emp.email != null)
            _infoRow(Icons.email, 'Correo', emp.email!),
          if (emp.phone != null)
            _infoRow(Icons.phone, 'Teléfono', emp.phone!),
          if (emp.address != null)
            _infoRow(Icons.location_on, 'Dirección',
                [emp.address, emp.city, emp.province]
                    .where((s) => s != null && s.isNotEmpty)
                    .join(', ')),
        ]),
        const SizedBox(height: 12),
        _infoCard('Personal', [
          if (emp.gender != null)
            _infoRow(Icons.person, 'Género', _genderLabel(emp.gender!)),
          if (emp.maritalStatus != null)
            _infoRow(Icons.favorite, 'Estado Civil',
                _maritalLabel(emp.maritalStatus!)),
          if (emp.nationality != null)
            _infoRow(Icons.flag, 'Nacionalidad', emp.nationality!),
        ]),
      ],
    );
  }

  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length < 2) return p[0][0].toUpperCase();
    return '${p[0][0]}${p[1][0]}'.toUpperCase();
  }

  String _idTypeLabel(String t) => switch (t) {
        'cedula' => 'Cédula', 'pasaporte' => 'Pasaporte', 'rnc' => 'RNC', _ => t
      };
  String _genderLabel(String g) =>
      switch (g) { 'M' => 'Masculino', 'F' => 'Femenino', _ => 'Otro' };
  String _maritalLabel(String m) => switch (m) {
        'soltero' => 'Soltero/a', 'casado' => 'Casado/a',
        'divorciado' => 'Divorciado/a', 'viudo' => 'Viudo/a',
        'union_libre' => 'Unión Libre', _ => m,
      };
}

// ─────────────────────────────────────────────────────
//  TAB 2: Información Laboral
// ─────────────────────────────────────────────────────
class _LaborTab extends StatelessWidget {
  final Employee emp;
  const _LaborTab({required this.emp});

  @override
  Widget build(BuildContext context) {
    final hireDate = DateTime.tryParse(emp.hireDate);
    final antiguedad = hireDate != null
        ? _antiguedad(hireDate)
        : 'Desconocida';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoCard('Posición', [
          if (emp.department != null)
            _infoRow(Icons.apartment, 'Departamento', emp.department!.name),
          if (emp.position != null)
            _infoRow(Icons.work, 'Cargo', emp.position!.title),
          if (emp.payrollGroup != null)
            _infoRow(Icons.group, 'Grupo de Nómina',
                '${emp.payrollGroup!.name} (${emp.payrollGroup!.frequencyLabel})'),
        ]),
        const SizedBox(height: 12),
        _infoCard('Contrato', [
          _infoRow(Icons.calendar_today, 'Fecha Ingreso',
              _fmtDate(emp.hireDate)),
          _infoRow(Icons.timelapse, 'Antigüedad', antiguedad),
          _infoRow(Icons.description, 'Tipo de Contrato',
              _contractLabel(emp.contractType)),
          if (emp.contractEndDate != null)
            _infoRow(Icons.event_busy, 'Fin de Contrato',
                _fmtDate(emp.contractEndDate!)),
          if (emp.terminationDate != null)
            _infoRow(Icons.logout, 'Fecha Desvinculación',
                _fmtDate(emp.terminationDate!), color: Colors.red),
        ]),
      ],
    );
  }

  String _antiguedad(DateTime hire) {
    final now = DateTime.now();
    final years = now.year - hire.year;
    final months = now.month - hire.month;
    final totalMonths = years * 12 + months;
    final y = totalMonths ~/ 12;
    final m = totalMonths % 12;
    if (y == 0) return '$m mes${m != 1 ? 'es' : ''}';
    return '$y año${y != 1 ? 's' : ''} ${m > 0 ? 'y $m mes${m != 1 ? 'es' : ''}' : ''}';
  }

  String _fmtDate(String d) {
    final dt = DateTime.tryParse(d);
    if (dt == null) return d;
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  String _contractLabel(String c) => switch (c) {
        'indefinido' => 'Indefinido', 'definido' => 'Definido',
        'por_obra' => 'Por Obra', 'aprendizaje' => 'Aprendizaje', _ => c,
      };
}

// ─────────────────────────────────────────────────────
//  TAB 3: Salario + Histórico
// ─────────────────────────────────────────────────────
class _SalaryTab extends StatelessWidget {
  final Employee emp;
  final EmployeesProvider provider;
  const _SalaryTab({required this.emp, required this.provider});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SalaryInfoCard(
          baseSalary: emp.baseSalary,
          salaryType: emp.salaryType,
          paymentMethod: emp.paymentMethod,
        ),
        const SizedBox(height: 12),
        _infoCard('Banco', [
          if (emp.bank != null)
            _infoRow(Icons.account_balance, 'Banco', emp.bank!.name),
          if (emp.bankAccountNumber != null)
            _infoRow(Icons.credit_card, 'No. Cuenta', '****${emp.bankAccountNumber!.substring(emp.bankAccountNumber!.length - 4 > 0 ? emp.bankAccountNumber!.length - 4 : 0)}'),
          if (emp.bankAccountType != null)
            _infoRow(Icons.savings, 'Tipo de Cuenta',
                emp.bankAccountType == 'ahorro' ? 'Ahorro' : 'Corriente'),
        ]),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.history, size: 18, color: Color(0xFF1E3A5F)),
                  SizedBox(width: 8),
                  Text('Histórico de Salarios',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1E3A5F))),
                ]),
                const Divider(height: 16),
                if (provider.salaryHistory.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                        child: Text('Sin historial de cambios salariales.',
                            style: TextStyle(color: Color(0xFF999999)))),
                  )
                else
                  ...provider.salaryHistory.map((h) => _SalaryHistoryItem(entry: h, fmt: fmt)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SalaryHistoryItem extends StatelessWidget {
  final SalaryHistoryEntry entry;
  final NumberFormat fmt;
  const _SalaryHistoryItem({required this.entry, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final diff = entry.newSalary - entry.previousSalary;
    final isIncrease = diff >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Icon(
            isIncrease ? Icons.trending_up : Icons.trending_down,
            color: isIncrease ? const Color(0xFF2E7D32) : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${fmt.format(entry.previousSalary)} → ${fmt.format(entry.newSalary)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(entry.reason,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF666666))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncrease ? '+' : ''}${fmt.format(diff)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isIncrease ? const Color(0xFF2E7D32) : Colors.red,
                ),
              ),
              Text(
                _fmtDate(entry.effectiveDate),
                style: const TextStyle(fontSize: 10, color: Color(0xFF999999)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDate(String d) {
    final dt = DateTime.tryParse(d);
    return dt != null ? DateFormat('dd/MM/yyyy').format(dt) : d;
  }
}

// ─────────────────────────────────────────────────────
//  TAB 4: TSS / ISR
// ─────────────────────────────────────────────────────
class _TssTab extends StatelessWidget {
  final Employee emp;
  const _TssTab({required this.emp});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final monthlySalary = emp.baseSalary;

    // Estimaciones TSS empleado (para visualización — el backend las calcula al procesar)
    final sfsMont = monthlySalary * 0.0304;
    final afpMont = monthlySalary * 0.0287;
    final totalDeduccion = sfsMont + afpMont;
    final neto = monthlySalary - totalDeduccion;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoCard('Afiliaciones TSS', [
          if (emp.afp != null)
            _infoRow(Icons.savings, 'AFP', emp.afp!.name),
          if (emp.ars != null)
            _infoRow(Icons.health_and_safety, 'ARS', emp.ars!.name),
          if (emp.tssNumber != null)
            _infoRow(Icons.numbers, 'No. TSS', emp.tssNumber!),
          _infoRow(Icons.check_circle,
              'Exento de TSS', emp.isTssExempt ? 'Sí' : 'No',
              color: emp.isTssExempt ? Colors.orange : null),
          _infoRow(Icons.check_circle,
              'Exento de ISR', emp.isIsrExempt ? 'Sí' : 'No',
              color: emp.isIsrExempt ? Colors.orange : null),
        ]),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Estimación de Descuentos Mensuales',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E3A5F))),
                const Text('(Calculado al procesar la nómina)',
                    style: TextStyle(fontSize: 11, color: Color(0xFF999999))),
                const Divider(height: 16),
                _estimRow('Salario Bruto', monthlySalary, fmt),
                _estimRow('SFS Empleado (3.04%)', -sfsMont, fmt),
                _estimRow('AFP Empleado (2.87%)', -afpMont, fmt),
                if (!emp.isIsrExempt)
                  const _EstimRowISR(),
                const Divider(),
                _estimRow('Neto Estimado', neto, fmt, bold: true),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '⚠️ El ISR se calcula sobre el ingreso anualizado. Esta es una estimación.',
                    style: TextStyle(fontSize: 11, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _estimRow(String label, double value, NumberFormat fmt,
      {bool bold = false}) {
    final isNeg = value < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13)),
          Text(
            '${isNeg ? '-' : ''} RD\$ ${fmt.format(value.abs())}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: isNeg
                  ? Colors.red
                  : bold
                      ? const Color(0xFF2E7D32)
                      : null,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstimRowISR extends StatelessWidget {
  const _EstimRowISR();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('ISR (según escala RD)', style: TextStyle(fontSize: 13)),
          Text('Calculado en nómina',
              style: TextStyle(color: Color(0xFF999999), fontSize: 11)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Helpers compartidos de tabs
// ─────────────────────────────────────────────────────
Widget _infoCard(String title, List<Widget> rows) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E3A5F))),
            const Divider(height: 16),
            ...rows,
          ],
        ),
      ),
    );

Widget _infoRow(IconData icon, String label, String value,
    {Color? color}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF999999)),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF666666))),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color),
            ),
          ),
        ],
      ),
    );
