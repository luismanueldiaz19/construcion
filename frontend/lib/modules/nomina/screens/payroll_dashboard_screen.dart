import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/auth_provider.dart';
import '../providers/payroll_provider.dart';
import '../widgets/nomina_widgets.dart';
import '../../../models/payroll.dart';
import 'payroll_details_dialog.dart';

class PayrollDashboardScreen extends StatelessWidget {
  const PayrollDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PayrollProvider(),
      child: const _PayrollDashboardContent(),
    );
  }
}

class _PayrollDashboardContent extends StatefulWidget {
  const _PayrollDashboardContent();

  @override
  State<_PayrollDashboardContent> createState() =>
      _PayrollDashboardContentState();
}

class _PayrollDashboardContentState extends State<_PayrollDashboardContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PayrollProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Gestión de Nómina',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: const Color(0xFFE31E24),
          unselectedLabelColor: const Color(0xFF666666),
          indicatorColor: const Color(0xFFE31E24),
          tabs: const [
            Tab(text: 'Nóminas en Proceso'),
            Tab(text: 'Periodos de Pago'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo Periodo'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE31E24),
              ),
              onPressed: () => _showCreatePeriodDialog(context, provider),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _PayrollsTab(provider: provider),
          _PeriodsTab(provider: provider),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────
  //  Diálogo: Crear Periodo de Pago
  // ────────────────────────────────────────────────────────
  void _showCreatePeriodDialog(BuildContext context, PayrollProvider provider) {
    int? groupId;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 15));

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text(
              'Nuevo Periodo de Nómina',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(
                      labelText: 'Grupo de Nómina *',
                      border: OutlineInputBorder(),
                    ),
                    value: groupId,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Seleccione un grupo'),
                      ),
                      ...provider.payrollGroups.map(
                        (g) => DropdownMenuItem(
                          value: g.id,
                          child: Text('${g.name} (${g.frequencyLabel})'),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => groupId = v),
                  ),
                  const SizedBox(height: 16),

                  // FECHA INICIO
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2099),
                      );
                      if (picked != null) {
                        setState(() => startDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de Inicio',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(DateFormat('dd/MM/yyyy').format(startDate)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // FECHA FIN
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2099),
                      );
                      if (picked != null) {
                        setState(() => endDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de Fin (y Pago)',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(DateFormat('dd/MM/yyyy').format(endDate)),
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
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE31E24),
                ),
                onPressed: () async {
                  if (groupId == null) return;

                  Navigator.pop(context);
                  final p = await provider.createPeriod({
                    'payroll_group_id': groupId,
                    'start_date': DateFormat('yyyy-MM-dd').format(startDate),
                    'end_date': DateFormat('yyyy-MM-dd').format(endDate),
                    'payment_date': DateFormat('yyyy-MM-dd').format(endDate),
                    'fiscal_year': endDate.year,
                    'period_number': endDate.month,
                  });

                  if (p != null && mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Periodo creado exitosamente.'),
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(provider.error ?? 'Error al crear'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Crear Periodo'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
//  TAB 1: Nóminas en Proceso (Payrolls)
// ────────────────────────────────────────────────────────
class _PayrollsTab extends StatelessWidget {
  final PayrollProvider provider;
  const _PayrollsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingPayrolls) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.payrolls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payments_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay nóminas en proceso.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Primero crea un periodo y genera el borrador de nómina.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final fmt = NumberFormat('#,##0.00');

    return RefreshIndicator(
      onRefresh: () => provider.loadPayrolls(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.payrolls.length,
        itemBuilder: (context, index) {
          final p = provider.payrolls[index];
          String fallbackName = 'Periodo';
          if (p.period != null) {
            if (p.period!.groupName != null &&
                p.period!.groupName!.isNotEmpty) {
              fallbackName = p.period!.groupName!;
            } else {
              final match = provider.payrollGroups.where(
                (g) => g.id == p.period!.payrollGroupId,
              );
              if (match.isNotEmpty) {
                fallbackName = match.first.name;
              }
            }
          }

          final periodLabel = p.period != null
              ? '$fallbackName - ${_fmtDate(p.period!.startDate)} a ${_fmtDate(p.period!.endDate)}'
              : 'Nómina #${p.id}';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      periodLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (p.status != 'pagado' && p.status != 'cerrado')
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        final ok = await provider.deletePayroll(p.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Nómina eliminada.'
                                    : (provider.error ?? 'Error al eliminar'),
                              ),
                              backgroundColor: ok ? null : Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  PayrollStatusBadge(p.status),
                ],
              ),
              subtitle: Text(
                'Total Neto: RD\$ ${fmt.format(p.totalNet)}  |  Total Bruto: RD\$ ${fmt.format(p.totalGross)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
              ),
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Resumen
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _resRow(
                              'Costo Empleador (Total):',
                              p.totalEmployerCost,
                              fmt,
                              bold: true,
                            ),
                            const SizedBox(height: 4),
                            _resRow(
                              'Retenciones TSS:',
                              p.totalTssEmployee,
                              fmt,
                            ),
                            _resRow('Retenciones ISR:', p.totalIsr, fmt),
                            _resRow(
                              'Otras Deducciones:',
                              p.totalDeductions -
                                  p.totalTssEmployee -
                                  p.totalIsr,
                              fmt,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Acciones (Workflow)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (p.status == 'borrador' || p.status == 'calculado')
                            FilledButton.icon(
                              icon: const Icon(Icons.calculate, size: 16),
                              label: const Text('Calcular'),
                              onPressed: () => _handleAction(
                                context,
                                provider,
                                'calculate',
                                p,
                              ),
                            ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.list_alt, size: 16),
                            label: const Text('Revisar Detalle'),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) =>
                                    PayrollDetailsDialog(payrollId: p.id),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          if (p.status == 'calculado')
                            OutlinedButton.icon(
                              icon: const Icon(Icons.fact_check, size: 16),
                              label: const Text('Marcar Revisada'),
                              onPressed: () =>
                                  _handleAction(context, provider, 'review', p),
                            ),
                          if (p.status == 'revisado')
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                              ),
                              icon: const Icon(Icons.verified, size: 16),
                              label: const Text('Aprobar Nómina'),
                              onPressed: () => _handleAction(
                                context,
                                provider,
                                'approve',
                                p,
                              ),
                            ),
                          if (p.status == 'aprobado')
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF00796B),
                              ),
                              icon: const Icon(Icons.payments, size: 16),
                              label: const Text('Pagar Nómina'),
                              onPressed: () =>
                                  _handleAction(context, provider, 'pay', p),
                            ),
                          if (p.status == 'pagado')
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF1A1C1E),
                              ),
                              icon: const Icon(Icons.lock, size: 16),
                              label: const Text('Cerrar'),
                              onPressed: () =>
                                  _handleAction(context, provider, 'close', p),
                            ),
                          if (p.status == 'cerrado' && context.read<AuthProvider>().username == 'ludeveloper')
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                icon: const Icon(Icons.delete_forever, size: 16),
                                label: const Text('Eliminar Nómina'),
                                onPressed: () =>
                                    _handleAction(context, provider, 'force_delete', p),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _resRow(
    String label,
    double val,
    NumberFormat fmt, {
    bool bold = false,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          'RD\$ ${fmt.format(val)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    PayrollProvider provider,
    String action,
    Payroll p,
  ) async {
    // Confirmación simple para acciones que cambian estado (excepto calcular que es idempotente)
    if (action != 'calculate') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Confirmar Acción'),
          content: Text(
            '¿Está seguro que desea cambiar el estado de la nómina a la siguiente etapa?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Procesando...')));

    bool ok = false;
    switch (action) {
      case 'calculate':
        ok = await provider.calculate(p.id);
        break;
      case 'review':
        ok = await provider.review(p.id);
        break;
      case 'approve':
        ok = await provider.approve(p.id);
        break;
      case 'pay':
        ok = await provider.markPaid(p.id);
        break;
      case 'close':
        ok = await provider.close(p.id);
        break;
      case 'force_delete':
        ok = await provider.forceDelete(p.id);
        break;
    }

    if (context.mounted) {
      if (ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Operación exitosa.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Error.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _fmtDate(String d) {
    final dt = DateTime.tryParse(d);
    return dt != null ? DateFormat('dd/MM/yyyy').format(dt) : d;
  }
}

// ────────────────────────────────────────────────────────
//  TAB 2: Periodos de Pago (Periods)
// ────────────────────────────────────────────────────────
class _PeriodsTab extends StatelessWidget {
  final PayrollProvider provider;
  const _PeriodsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingPeriods) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.periods.isEmpty) {
      return const Center(child: Text('No hay periodos registrados.'));
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadPeriods(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.periods.length,
        itemBuilder: (context, index) {
          final p = provider.periods[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                '${p.groupName} - ${_fmtDate(p.startDate)} a ${_fmtDate(p.endDate)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Estado: ${p.statusLabel} | Frecuencia: ${p.groupFrequency}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (p.status == 'abierto')
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        final ok = await provider.deletePeriod(p.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Periodo eliminado.'
                                    : (provider.error ?? 'Error al eliminar'),
                              ),
                              backgroundColor: ok ? null : Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  if (p.status == 'abierto')
                    FilledButton.tonal(
                      child: const Text('Generar Nómina'),
                      onPressed: () => _generateDraft(context, provider, p.id),
                    )
                  else
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _generateDraft(
    BuildContext context,
    PayrollProvider provider,
    int periodId,
  ) async {
    final payroll = await provider.createDraft(
      periodId,
      notes: 'Generado automáticamente',
    );
    if (context.mounted) {
      if (payroll != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Borrador generado. Vaya a Nóminas en Proceso.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _fmtDate(String d) {
    final dt = DateTime.tryParse(d);
    return dt != null ? DateFormat('dd/MM/yyyy').format(dt) : d;
  }
}
