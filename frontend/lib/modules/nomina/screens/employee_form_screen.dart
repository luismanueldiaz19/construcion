import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/employees_provider.dart';
import '../../../models/nomina_catalogs.dart';

/// Formulario de creación/edición de empleado.
/// TODOS los campos de selección usan DropdownButtonFormField para
/// evitar que el usuario escriba valores inválidos.
class EmployeeFormScreen extends StatefulWidget {
  final int? employeeId; // null = crear, non-null = editar
  const EmployeeFormScreen({super.key, this.employeeId});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isLoadingEmployee = false;

  // ── Controladores de texto ──
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _idNumber = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _salary = TextEditingController();
  final _tssNumber = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _province = TextEditingController();
  final _bankAccount = TextEditingController();
  final _nationality = TextEditingController();

  // ── Valores de selects ──
  String _idType = 'cedula';
  String _gender = 'M';
  String _maritalStatus = 'soltero';
  String _contractType = 'indefinido';
  String _salaryType = 'fijo';
  String _paymentMethod = 'transferencia';
  String _bankAccountType = 'ahorro';

  int? _departmentId;
  int? _positionId;
  int? _payrollGroupId;
  int? _workScheduleId;
  int? _afpId;
  int? _arsId;
  int? _bankId;

  DateTime? _hireDate;
  DateTime? _contractEndDate;
  DateTime? _birthDate;

  bool _isTssExempt = false;
  bool _isIsrExempt = false;

  bool get isEdit => widget.employeeId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EmployeesProvider>();
      if (!provider.catalogsLoaded) {
        provider.loadCatalogs();
      }
      if (isEdit) {
        _loadEmployee(provider);
      }
      // Cargar todas las posiciones para edición
      provider.loadAllPositions();
    });
  }

  Future<void> _loadEmployee(EmployeesProvider provider) async {
    setState(() => _isLoadingEmployee = true);
    await provider.loadEmployee(widget.employeeId!);
    final emp = provider.selectedEmployee;
    if (emp != null && mounted) {
      _firstName.text = emp.firstName;
      _lastName.text = emp.lastName;
      _idNumber.text = emp.identificationNumber;
      _email.text = emp.email ?? '';
      _phone.text = emp.phone ?? '';
      _salary.text = emp.baseSalary.toStringAsFixed(2);
      _tssNumber.text = emp.tssNumber ?? '';
      _address.text = emp.address ?? '';
      _city.text = emp.city ?? '';
      _province.text = emp.province ?? '';
      _bankAccount.text = emp.bankAccountNumber ?? '';
      _nationality.text = emp.nationality ?? '';

      setState(() {
        _idType = emp.identificationType;
        _gender = emp.gender ?? 'M';
        _maritalStatus = emp.maritalStatus ?? 'soltero';
        _contractType = emp.contractType;
        _salaryType = emp.salaryType;
        _paymentMethod = emp.paymentMethod;
        _bankAccountType = emp.bankAccountType ?? 'ahorro';
        _departmentId = emp.departmentId;
        _positionId = emp.positionId;
        _payrollGroupId = emp.payrollGroupId;
        _workScheduleId = emp.workScheduleId;
        _afpId = emp.afpId;
        _arsId = emp.arsId;
        _bankId = emp.bankId;
        _isTssExempt = emp.isTssExempt;
        _isIsrExempt = emp.isIsrExempt;
        _hireDate = DateTime.tryParse(emp.hireDate);
        if (emp.contractEndDate != null) {
          _contractEndDate = DateTime.tryParse(emp.contractEndDate!);
        }
      });
    }
    setState(() => _isLoadingEmployee = false);
  }

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _idNumber,
      _email,
      _phone,
      _salary,
      _tssNumber,
      _address,
      _city,
      _province,
      _bankAccount,
      _nationality,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Helpers ──

  Future<void> _pickDate(
    BuildContext context, {
    required DateTime? current,
    required void Function(DateTime) onPicked,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1950),
      lastDate: lastDate ?? DateTime(2099),
    );
    if (picked != null) onPicked(picked);
  }

  String _fmtDate(DateTime? d) =>
      d == null ? 'Seleccionar fecha' : DateFormat('dd/MM/yyyy').format(d);

  // ── Save ──────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_hireDate == null) {
      _showError('Seleccione la fecha de ingreso.');
      return;
    }
    if (_contractType == 'definido' && _contractEndDate == null) {
      _showError('Seleccione la fecha de fin de contrato.');
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<EmployeesProvider>();

    final data = <String, dynamic>{
      'first_name': _firstName.text.trim(),
      'last_name': _lastName.text.trim(),
      'identification_type': _idType,
      'identification_number': _idNumber.text.trim(),
      if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
      if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
      'hire_date': DateFormat('yyyy-MM-dd').format(_hireDate!),
      'contract_type': _contractType,
      if (_contractType == 'definido' && _contractEndDate != null)
        'contract_end_date': DateFormat('yyyy-MM-dd').format(_contractEndDate!),
      'base_salary': double.tryParse(_salary.text.replaceAll(',', '')) ?? 0,
      'salary_type': _salaryType,
      'payment_method': _paymentMethod,
      'gender': _gender,
      'marital_status': _maritalStatus,
      if (_nationality.text.trim().isNotEmpty)
        'nationality': _nationality.text.trim(),
      if (_address.text.trim().isNotEmpty) 'address': _address.text.trim(),
      if (_city.text.trim().isNotEmpty) 'city': _city.text.trim(),
      if (_province.text.trim().isNotEmpty) 'province': _province.text.trim(),
      if (_departmentId != null) 'department_id': _departmentId,
      if (_positionId != null) 'position_id': _positionId,
      if (_payrollGroupId != null) 'payroll_group_id': _payrollGroupId,
      if (_workScheduleId != null) 'work_schedule_id': _workScheduleId,
      if (_afpId != null) 'afp_id': _afpId,
      if (_arsId != null) 'ars_id': _arsId,
      if (_bankId != null) 'bank_id': _bankId,
      if (_bankAccount.text.trim().isNotEmpty)
        'bank_account_number': _bankAccount.text.trim(),
      if (_bankId != null) 'bank_account_type': _bankAccountType,
      if (_tssNumber.text.trim().isNotEmpty)
        'tss_number': _tssNumber.text.trim(),
      'is_tss_exempt': _isTssExempt,
      'is_isr_exempt': _isIsrExempt,
    };

    bool ok;
    if (isEdit) {
      ok = await provider.updateEmployee(widget.employeeId!, data);
    } else {
      ok = await provider.createEmployee(data);
    }

    setState(() => _isSaving = false);

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Empleado actualizado correctamente.'
                : 'Empleado creado correctamente.',
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    } else {
      _showError(provider.error ?? 'Error al guardar el empleado.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeesProvider>();

    if (_isLoadingEmployee) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // AppBar will be added in the final return, but we extract formContent first.
    final bool isDesktop = MediaQuery.of(context).size.width > 850;

    Widget formContent = Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Column(
              children: [
                _section('Datos Personales', [
                  _row([
                    _field(
                      'Nombre *',
                      _firstName,
                      validator: _required,
                      capitalize: TextCapitalization.words,
                    ),
                    _field(
                      'Apellido *',
                      _lastName,
                      validator: _required,
                      capitalize: TextCapitalization.words,
                    ),
                  ]),
                  _row([
                    _dropdown<String>(
                      label: 'Tipo ID *',
                      value: _idType,
                      items: const [
                        DropdownMenuItem(
                          value: 'cedula',
                          child: Text('Cédula'),
                        ),
                        DropdownMenuItem(
                          value: 'pasaporte',
                          child: Text('Pasaporte'),
                        ),
                        DropdownMenuItem(value: 'rnc', child: Text('RNC')),
                      ],
                      onChanged: (v) => setState(() => _idType = v!),
                    ),
                    _field(
                      'No. Identificación *',
                      _idNumber,
                      validator: _required,
                    ),
                  ]),
                  _row([
                    _dropdown<String>(
                      label: 'Género',
                      value: _gender,
                      items: const [
                        DropdownMenuItem(value: 'M', child: Text('Masculino')),
                        DropdownMenuItem(value: 'F', child: Text('Femenino')),
                        DropdownMenuItem(value: 'otro', child: Text('Otro')),
                      ],
                      onChanged: (v) => setState(() => _gender = v!),
                    ),
                    _dropdown<String>(
                      label: 'Estado Civil',
                      value: _maritalStatus,
                      items: const [
                        DropdownMenuItem(
                          value: 'soltero',
                          child: Text('Soltero/a'),
                        ),
                        DropdownMenuItem(
                          value: 'casado',
                          child: Text('Casado/a'),
                        ),
                        DropdownMenuItem(
                          value: 'divorciado',
                          child: Text('Divorciado/a'),
                        ),
                        DropdownMenuItem(
                          value: 'viudo',
                          child: Text('Viudo/a'),
                        ),
                        DropdownMenuItem(
                          value: 'union_libre',
                          child: Text('Unión Libre'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _maritalStatus = v!),
                    ),
                  ]),
                  _row([
                    _field(
                      'Correo Electrónico',
                      _email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _field(
                      'Teléfono',
                      _phone,
                      keyboardType: TextInputType.phone,
                    ),
                  ]),
                  _row([
                    _field(
                      'Nacionalidad',
                      _nationality,
                      capitalize: TextCapitalization.words,
                    ),
                    _field('Dirección', _address),
                  ]),
                  _row([
                    _field(
                      'Ciudad',
                      _city,
                      capitalize: TextCapitalization.words,
                    ),
                    _field(
                      'Provincia',
                      _province,
                      capitalize: TextCapitalization.words,
                    ),
                  ]),
                ]),

                const SizedBox(height: 16),
                _section('Información Laboral', [
                  _row([
                    _datePicker(
                      'Fecha de Ingreso *',
                      _hireDate,
                      onPicked: (d) => setState(() => _hireDate = d),
                    ),
                    _dropdown<String>(
                      label: 'Tipo de Contrato *',
                      value: _contractType,
                      items: const [
                        DropdownMenuItem(
                          value: 'indefinido',
                          child: Text('Indefinido'),
                        ),
                        DropdownMenuItem(
                          value: 'definido',
                          child: Text('Definido'),
                        ),
                        DropdownMenuItem(
                          value: 'por_obra',
                          child: Text('Por Obra'),
                        ),
                        DropdownMenuItem(
                          value: 'aprendizaje',
                          child: Text('Aprendizaje'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _contractType = v!),
                    ),
                  ]),
                  if (_contractType == 'definido')
                    _row([
                      _datePicker(
                        'Fecha Fin de Contrato *',
                        _contractEndDate,
                        onPicked: (d) => setState(() => _contractEndDate = d),
                      ),
                    ]),
                  _row([
                    _dropdown<int?>(
                      label: 'Departamento',
                      value: _departmentId,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Sin departamento'),
                        ),
                        ...provider.departments.map(
                          (d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.name),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _departmentId = v;
                          _positionId = null;
                        });
                        if (v != null) provider.loadPositionsByDepartment(v);
                      },
                    ),
                    _dropdown<int?>(
                      label: 'Cargo',
                      value: _positionId,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Sin cargo'),
                        ),
                        ...provider.positions.map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.title),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _positionId = v),
                    ),
                  ]),
                  _row([
                    _dropdown<int?>(
                      label: 'Grupo de Nómina',
                      value: _payrollGroupId,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Sin grupo'),
                        ),
                        ...provider.payrollGroups.map(
                          (g) => DropdownMenuItem(
                            value: g.id,
                            child: Text(g.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _payrollGroupId = v),
                    ),
                    _dropdown<int?>(
                      label: 'Horario',
                      value: _workScheduleId,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Sin horario'),
                        ),
                        ...provider.workSchedules.map(
                          (w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(w.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _workScheduleId = v),
                    ),
                  ]),
                ]),

                const SizedBox(height: 16),
                _section('Salario y Pago', [
                  _row([
                    _field(
                      'Salario Base (RD\$) *',
                      _salary,
                      validator: _requiredNumber,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                      ],
                    ),
                    _dropdown<String>(
                      label: 'Tipo de Salario *',
                      value: _salaryType,
                      items: const [
                        DropdownMenuItem(
                          value: 'fijo',
                          child: Text('Fijo Mensual'),
                        ),
                        DropdownMenuItem(
                          value: 'por_hora',
                          child: Text('Por Hora'),
                        ),
                        DropdownMenuItem(
                          value: 'comision',
                          child: Text('Comisión'),
                        ),
                        DropdownMenuItem(value: 'mixto', child: Text('Mixto')),
                      ],
                      onChanged: (v) => setState(() => _salaryType = v!),
                    ),
                  ]),
                  _row([
                    _dropdown<String>(
                      label: 'Método de Pago *',
                      value: _paymentMethod,
                      items: const [
                        DropdownMenuItem(
                          value: 'transferencia',
                          child: Text('Transferencia'),
                        ),
                        DropdownMenuItem(
                          value: 'cheque',
                          child: Text('Cheque'),
                        ),
                        DropdownMenuItem(
                          value: 'efectivo',
                          child: Text('Efectivo'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _paymentMethod = v!),
                    ),
                    _dropdown<int?>(
                      label: 'Banco',
                      value: _bankId,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Sin banco'),
                        ),
                        ...provider.banks.map(
                          (b) => DropdownMenuItem(
                            value: b.id,
                            child: Text(b.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _bankId = v),
                    ),
                  ]),
                  if (_bankId != null)
                    _row([
                      _field('No. Cuenta Bancaria', _bankAccount),
                      _dropdown<String>(
                        label: 'Tipo de Cuenta',
                        value: _bankAccountType,
                        items: const [
                          DropdownMenuItem(
                            value: 'ahorro',
                            child: Text('Ahorro'),
                          ),
                          DropdownMenuItem(
                            value: 'corriente',
                            child: Text('Corriente'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _bankAccountType = v!),
                      ),
                    ]),
                ]),

                const SizedBox(height: 16),
                _section('Seguridad Social (TSS)', [
                  _row([
                    _dropdown<int?>(
                      label: 'AFP',
                      value: _afpId,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Seleccionar AFP'),
                        ),
                        ...provider.afps.map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _afpId = v),
                    ),
                    _dropdown<int?>(
                      label: 'ARS (Seguro médico)',
                      value: _arsId,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Seleccionar ARS'),
                        ),
                        ...provider.arss.map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _arsId = v),
                    ),
                  ]),
                  _row([
                    _field(
                      'No. TSS',
                      _tssNumber,
                      hint: 'Número de afiliación TSS',
                      keyboardType: TextInputType.number,
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          value: _isTssExempt,
                          title: const Text(
                            'Exento de TSS',
                            style: TextStyle(fontSize: 13),
                          ),
                          onChanged: (v) => setState(() => _isTssExempt = v!),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          value: _isIsrExempt,
                          title: const Text(
                            'Exento de ISR',
                            style: TextStyle(fontSize: 13),
                          ),
                          onChanged: (v) => setState(() => _isIsrExempt = v!),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ]),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isEdit ? 'Guardar Cambios' : 'Registrar Empleado',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Editar Empleado' : 'Nuevo Empleado',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE31E24),
                ),
                onPressed: _save,
                child: const Text('Guardar'),
              ),
            ),
        ],
      ),
      body: isDesktop
          ? Row(
              children: [
                Expanded(flex: 2, child: formContent),
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/background.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      color: const Color(0xFF1E3A5F).withValues(alpha: 0.7),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.badge, size: 100, color: Colors.white70),
                            SizedBox(height: 20),
                            Text(
                              'Agregar Empleados',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : formContent,
    );
  }

  // ── Widget builders ──

  Widget _section(String title, List<Widget> children) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const Divider(height: 16),
          ...children,
        ],
      ),
    ),
  );

  Widget _row(List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.expand((w) => [w, const SizedBox(width: 12)]).toList()
        ..removeLast(),
    ),
  );

  Widget _field(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization capitalize = TextCapitalization.none,
    String? hint,
    List<TextInputFormatter>? inputFormatters,
  }) => Expanded(
    child: TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: capitalize,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    ),
  );

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
  }) {
    final bool exists = items.any((item) => item.value == value);
    final T? safeValue = exists
        ? value
        : (items.isNotEmpty ? items.first.value : null);

    return Expanded(
      child: DropdownButtonFormField<T>(
        initialValue: safeValue,
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _datePicker(
    String label,
    DateTime? current, {
    required void Function(DateTime) onPicked,
  }) => Expanded(
    child: InkWell(
      onTap: () => _pickDate(context, current: current, onPicked: onPicked),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          _fmtDate(current),
          style: TextStyle(
            fontSize: 14,
            color: current == null ? Colors.grey : null,
          ),
        ),
      ),
    ),
  );

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo requerido' : null;

  String? _requiredNumber(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo requerido';
    if (double.tryParse(v.replaceAll(',', '')) == null)
      return 'Ingrese un número válido';
    return null;
  }
}
