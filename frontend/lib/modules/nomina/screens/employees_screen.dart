import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/employees_provider.dart';
import '../widgets/nomina_widgets.dart';
import 'employee_form_screen.dart';
import 'employee_detail_screen.dart';

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EmployeesProvider(),
      child: const _EmployeesScreenContent(),
    );
  }
}

class _EmployeesScreenContent extends StatelessWidget {
  const _EmployeesScreenContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeesProvider>();
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Empleados',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${provider.total} registros',
              style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
            ),
          ],
        ),
        actions: [
          // Buscador
          SizedBox(
            width: isWide ? 220 : 140,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                controller: provider.searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar empleado...',
                  hintStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: provider.searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 14),
                          onPressed: () {
                            provider.searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Filtros
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filtrar',
                onPressed: () => _showFilterSheet(context, provider),
              ),
              if (provider.hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE31E24),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
          // Nuevo empleado
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              icon: const Icon(Icons.person_add, size: 18),
              label: Text(isWide ? 'Nuevo Empleado' : 'Nuevo'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE31E24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 0,
                ),
              ),
              onPressed: () => _openForm(context, null),
            ),
          ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      if (provider.hasActiveFilters)
                        _ActiveFiltersBar(provider: provider),
                      Expanded(
                        child: provider.isLoading && provider.employees.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : provider.employees.isEmpty
                            ? _EmptyState(provider: provider)
                            : RefreshIndicator(
                                onRefresh: () => provider.loadEmployees(),
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(
                                    bottom: 80,
                                    top: 4,
                                  ),
                                  itemCount:
                                      provider.employees.length +
                                      (provider.currentPage < provider.lastPage
                                          ? 1
                                          : 0),
                                  itemBuilder: (context, index) {
                                    if (index == provider.employees.length) {
                                      return _LoadMoreButton(
                                        provider: provider,
                                      );
                                    }
                                    final emp = provider.employees[index];
                                    return EmployeeCard(
                                      employee: emp,
                                      onTap: () => _openDetail(context, emp.id),
                                      onEdit: () => _openForm(context, emp.id),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
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
                              'Gestión de Empleados',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
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
          : Column(
              children: [
                if (provider.hasActiveFilters)
                  _ActiveFiltersBar(provider: provider),
                Expanded(
                  child: provider.isLoading && provider.employees.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : provider.employees.isEmpty
                      ? _EmptyState(provider: provider)
                      : RefreshIndicator(
                          onRefresh: () => provider.loadEmployees(),
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80, top: 4),
                            itemCount:
                                provider.employees.length +
                                (provider.currentPage < provider.lastPage
                                    ? 1
                                    : 0),
                            itemBuilder: (context, index) {
                              if (index == provider.employees.length) {
                                return _LoadMoreButton(provider: provider);
                              }
                              final emp = provider.employees[index];
                              return EmployeeCard(
                                employee: emp,
                                onTap: () => _openDetail(context, emp.id),
                                onEdit: () => _openForm(context, emp.id),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  void _openForm(BuildContext context, int? employeeId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<EmployeesProvider>(),
          child: EmployeeFormScreen(employeeId: employeeId),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, int id) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<EmployeesProvider>(),
          child: EmployeeDetailScreen(employeeId: id),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, EmployeesProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(provider: provider),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Barra de filtros activos
// ─────────────────────────────────────────────────────
class _ActiveFiltersBar extends StatelessWidget {
  final EmployeesProvider provider;
  const _ActiveFiltersBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (provider.filterStatus != null) {
      chips.add(
        _FilterChip(
          label: _statusLabel(provider.filterStatus!),
          onRemove: () => provider.setFilter(
            departmentId: provider.filterDepartmentId,
            payrollGroupId: provider.filterPayrollGroupId,
          ),
        ),
      );
    }
    if (provider.filterDepartmentId != null) {
      final dept = provider.departments
          .where((d) => d.id == provider.filterDepartmentId)
          .firstOrNull;
      chips.add(
        _FilterChip(
          label: dept?.name ?? 'Departamento',
          onRemove: () => provider.setFilter(
            status: provider.filterStatus,
            payrollGroupId: provider.filterPayrollGroupId,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          ...chips,
          const SizedBox(width: 8),
          TextButton.icon(
            icon: const Icon(Icons.clear_all, size: 14),
            label: const Text('Limpiar', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: const Color(0xFFE31E24),
            ),
            onPressed: provider.clearFilters,
          ),
        ],
      ),
    );
  }

  String _statusLabel(String s) => switch (s) {
    'activo' => 'Activos',
    'vacaciones' => 'Vacaciones',
    'licencia' => 'Licencia',
    'suspendido' => 'Suspendidos',
    'desvinculado' => 'Desvinculados',
    _ => s,
  };
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1E3A5F).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          InkWell(onTap: onRemove, child: const Icon(Icons.close, size: 14)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Estado vacío
// ─────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final EmployeesProvider provider;
  const _EmptyState({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            provider.hasActiveFilters
                ? 'No se encontraron empleados con esos filtros'
                : 'Aún no hay empleados registrados',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          if (provider.hasActiveFilters) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: provider.clearFilters,
              child: const Text('Limpiar filtros'),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Botón cargar más
// ─────────────────────────────────────────────────────
class _LoadMoreButton extends StatelessWidget {
  final EmployeesProvider provider;
  const _LoadMoreButton({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: provider.isLoading
            ? const CircularProgressIndicator()
            : OutlinedButton(
                onPressed: provider.loadNextPage,
                child: const Text('Cargar más'),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Sheet de filtros
// ─────────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final EmployeesProvider provider;
  const _FilterSheet({required this.provider});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _status;
  int? _departmentId;
  int? _payrollGroupId;

  @override
  void initState() {
    super.initState();
    _status = widget.provider.filterStatus;
    _departmentId = widget.provider.filterDepartmentId;
    _payrollGroupId = widget.provider.filterPayrollGroupId;
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtrar Empleados',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Estatus
          const Text(
            'Estatus',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                [
                  null,
                  'activo',
                  'vacaciones',
                  'licencia',
                  'suspendido',
                  'desvinculado',
                ].map((s) {
                  final label = s == null
                      ? 'Todos'
                      : switch (s) {
                          'activo' => 'Activo',
                          'vacaciones' => 'Vacaciones',
                          'licencia' => 'Licencia',
                          'suspendido' => 'Suspendido',
                          'desvinculado' => 'Desvinculado',
                          _ => s,
                        };
                  return ChoiceChip(
                    label: Text(label),
                    selected: _status == s,
                    onSelected: (_) => setState(() => _status = s),
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),

          // Departamento
          if (provider.departments.isNotEmpty) ...[
            const Text(
              'Departamento',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: _departmentId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Todos los departamentos'),
                ),
                ...provider.departments.map(
                  (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
                ),
              ],
              onChanged: (v) => setState(() => _departmentId = v),
            ),
            const SizedBox(height: 16),
          ],

          // Grupo de nómina
          if (provider.payrollGroups.isNotEmpty) ...[
            const Text(
              'Grupo de Nómina',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: _payrollGroupId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Todos los grupos'),
                ),
                ...provider.payrollGroups.map(
                  (g) => DropdownMenuItem(value: g.id, child: Text(g.name)),
                ),
              ],
              onChanged: (v) => setState(() => _payrollGroupId = v),
            ),
            const SizedBox(height: 20),
          ],

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    provider.clearFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE31E24),
                  ),
                  onPressed: () {
                    provider.setFilter(
                      status: _status,
                      departmentId: _departmentId,
                      payrollGroupId: _payrollGroupId,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
