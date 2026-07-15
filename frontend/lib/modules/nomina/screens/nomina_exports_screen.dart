import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/nomina_export_service.dart';
import '../../../services/nomina_service.dart';
import '../providers/payroll_provider.dart';

enum ReportType {
  nominaConsolidada,
  planillaTss,
  retencionesIsr,
  provisiones,
  historial,
}

class NominaExportsScreen extends StatefulWidget {
  const NominaExportsScreen({super.key});

  @override
  State<NominaExportsScreen> createState() => _NominaExportsScreenState();
}

class _NominaExportsScreenState extends State<NominaExportsScreen> {
  final NominaExportService _exportService = NominaExportService();
  final NominaService _nominaService = NominaService();

  ReportType _selectedReport = ReportType.nominaConsolidada;

  // Parámetros
  int? _selectedPayrollId;
  DateTime _fromDate = DateTime(DateTime.now().year, 1, 1);
  DateTime _toDate = DateTime.now();

  // Estado de los datos consultados
  bool _isLoading = false;
  Map<String, dynamic>? _reportData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PayrollProvider>().loadPayrolls();
    });
  }

  Future<void> _generarConsulta() async {
    setState(() {
      _isLoading = true;
      _reportData = null;
      _errorMessage = null;
    });

    try {
      if (_selectedReport == ReportType.nominaConsolidada) {
        if (_selectedPayrollId == null) {
          throw Exception('Selecciona una nómina para generar el reporte.');
        }
        if (_selectedReport == ReportType.nominaConsolidada) {
          final data = await _nominaService.getReportNominaConsolidada(
            _selectedPayrollId!,
          );
          setState(() {
            _reportData = data;
          });
        } else if (_selectedReport == ReportType.planillaTss) {
          final data = await _nominaService.getReportPlanillaTSS(
            _selectedPayrollId!,
          );
          setState(() {
            _reportData = data;
          });
        } else if (_selectedReport == ReportType.retencionesIsr) {
          final data = await _nominaService.getReportRetencionesISR(
            _selectedPayrollId!,
          );
          setState(() {
            _reportData = data;
          });
        } else if (_selectedReport == ReportType.provisiones) {
          final fromStr = DateFormat('yyyy-MM-dd').format(_fromDate);
          final toStr = DateFormat('yyyy-MM-dd').format(_toDate);
          final data = await _nominaService.getReportProvisiones(
            fromStr,
            toStr,
          );
          setState(() {
            _reportData = data;
          });
        } else if (_selectedReport == ReportType.historial) {
          final fromStr = DateFormat('yyyy-MM-dd').format(_fromDate);
          final toStr = DateFormat('yyyy-MM-dd').format(_toDate);
          final data = await _nominaService.getReportHistorialSalarios(
            fromStr,
            toStr,
          );
          setState(() {
            _reportData = data;
          });
        } else {
          throw Exception(
            'La previsualización en pantalla para este reporte aún no está disponible.',
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _descargarExcel() {
    if (_selectedReport == ReportType.nominaConsolidada) {
      if (_selectedPayrollId != null) {
        _exportService.downloadNominaConsolidada(_selectedPayrollId!);
      }
    } else if (_selectedReport == ReportType.planillaTss) {
      if (_selectedPayrollId != null) {
        _exportService.downloadPlanillaTSS(_selectedPayrollId!);
      }
    } else if (_selectedReport == ReportType.retencionesIsr) {
      if (_selectedPayrollId != null) {
        _exportService.downloadRetencionesISR(_selectedPayrollId!);
      }
    } else if (_selectedReport == ReportType.provisiones) {
      _exportService.downloadProvisiones(
        from: DateFormat('yyyy-MM-dd').format(_fromDate),
        to: DateFormat('yyyy-MM-dd').format(_toDate),
      );
    } else if (_selectedReport == ReportType.historial) {
      _exportService.downloadHistorialSalarios(
        from: DateFormat('yyyy-MM-dd').format(_fromDate),
        to: DateFormat('yyyy-MM-dd').format(_toDate),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Exportaciones y Reportes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SIDEBAR (Master)
          Container(
            width: 250,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _SidebarItem(
                  title: 'Nómina Consolidada',
                  icon: Icons.table_view,
                  isSelected: _selectedReport == ReportType.nominaConsolidada,
                  onTap: () => setState(() {
                    _selectedReport = ReportType.nominaConsolidada;
                    _reportData = null;
                  }),
                ),
                _SidebarItem(
                  title: 'Planilla TSS',
                  icon: Icons.health_and_safety,
                  isSelected: _selectedReport == ReportType.planillaTss,
                  onTap: () => setState(() {
                    _selectedReport = ReportType.planillaTss;
                    _reportData = null;
                  }),
                ),
                _SidebarItem(
                  title: 'Retenciones ISR',
                  icon: Icons.account_balance,
                  isSelected: _selectedReport == ReportType.retencionesIsr,
                  onTap: () => setState(() {
                    _selectedReport = ReportType.retencionesIsr;
                    _reportData = null;
                  }),
                ),
                _SidebarItem(
                  title: 'Provisiones Acum.',
                  icon: Icons.savings,
                  isSelected: _selectedReport == ReportType.provisiones,
                  onTap: () => setState(() {
                    _selectedReport = ReportType.provisiones;
                    _reportData = null;
                  }),
                ),
                _SidebarItem(
                  title: 'Historial Salarios',
                  icon: Icons.history,
                  isSelected: _selectedReport == ReportType.historial,
                  onTap: () => setState(() {
                    _selectedReport = ReportType.historial;
                    _reportData = null;
                  }),
                ),
              ],
            ),
          ),

          // ÁREA PRINCIPAL (Detail)
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 16, bottom: 16, right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Filtros y Botones
                  _buildFiltros(),
                  const Divider(height: 1),
                  // Tabla de Resultados
                  Expanded(child: _buildResultados()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    final provider = context.watch<PayrollProvider>();
    final isPorPeriodo =
        _selectedReport == ReportType.nominaConsolidada ||
        _selectedReport == ReportType.planillaTss ||
        _selectedReport == ReportType.retencionesIsr;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isPorPeriodo)
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<int?>(
                decoration: const InputDecoration(
                  labelText: 'Seleccionar Nómina',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                isExpanded: true,
                value: _selectedPayrollId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Ninguna')),
                  ...provider.payrolls.map((p) {
                    String label = 'Nómina #${p.id}';
                    if (p.period != null) {
                      try {
                        final dt = DateTime.parse(p.period!.startDate);
                        final dtEnd = DateTime.parse(p.period!.endDate);
                        label =
                            '${p.period!.groupName} (${DateFormat('dd/MM/yyyy').format(dt)} a ${DateFormat('dd/MM/yyyy').format(dtEnd)})';
                      } catch (_) {
                        label =
                            '${p.period!.groupName} (${p.period!.startDate})';
                      }
                    }
                    return DropdownMenuItem(
                      value: p.id,
                      child: Text(label, overflow: TextOverflow.ellipsis),
                    );
                  }),
                ],
                onChanged: (v) => setState(() => _selectedPayrollId = v),
              ),
            )
          else ...[
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _fromDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _fromDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Desde Fecha',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: Text(DateFormat('dd/MM/yyyy').format(_fromDate)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _toDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _toDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Hasta Fecha',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: Text(DateFormat('dd/MM/yyyy').format(_toDate)),
                ),
              ),
            ),
          ],
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _generarConsulta,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(),
                  )
                : const Icon(Icons.search),
            label: const Text('Generar Vista'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: () => _descargarExcel(),
            icon: const Icon(Icons.download),
            label: const Text('Descargar Excel'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultados() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }
    if (_reportData == null) {
      return const Center(
        child: Text(
          'Selecciona los parámetros y haz clic en "Generar Vista".',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (_selectedReport == ReportType.nominaConsolidada) {
      return _buildNominaConsolidadaTable();
    } else if (_selectedReport == ReportType.planillaTss) {
      return _buildPlanillaTSSTable();
    } else if (_selectedReport == ReportType.retencionesIsr) {
      return _buildRetencionesISRTable();
    } else if (_selectedReport == ReportType.provisiones) {
      return _buildProvisionesTable();
    } else if (_selectedReport == ReportType.historial) {
      return _buildHistorialSalariosTable();
    }

    return const Center(child: Text('Vista no soportada aún.'));
  }

  Widget _buildHistorialSalariosTable() {
    final meta = _reportData!['meta'];
    final rows = List<Map<String, dynamic>>.from(_reportData!['rows'] ?? []);

    return Column(
      children: [
        // Cabecera del Reporte
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.teal.shade50,
          child: Column(
            children: [
              Text(
                meta['title'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (meta['subtitle'] != null && meta['subtitle'].isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  meta['subtitle'],
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.teal.shade100),
                columns: const [
                  DataColumn(label: Text('Código')),
                  DataColumn(label: Text('Empleado')),
                  DataColumn(label: Text('Departamento')),
                  DataColumn(label: Text('Fecha Efectiva')),
                  DataColumn(
                    label: Text('Salario Anterior', textAlign: TextAlign.right),
                  ),
                  DataColumn(
                    label: Text('Salario Nuevo', textAlign: TextAlign.right),
                  ),
                  DataColumn(
                    label: Text('Diferencia', textAlign: TextAlign.right),
                  ),
                  DataColumn(label: Text('Motivo')),
                  DataColumn(label: Text('Aprobado Por')),
                ],
                rows: rows.map((r) {
                  final fmt = NumberFormat.currency(
                    symbol: '',
                    decimalDigits: 2,
                  );
                  final double dif = (r['diferencia'] ?? 0).toDouble();
                  final Color difColor = dif > 0
                      ? Colors.green
                      : (dif < 0 ? Colors.red : Colors.black);

                  return DataRow(
                    cells: [
                      DataCell(Text(r['codigo'].toString())),
                      DataCell(Text(r['empleado'].toString())),
                      DataCell(Text(r['departamento'].toString())),
                      DataCell(Text(r['fecha_efectiva'].toString())),
                      DataCell(Text(fmt.format(r['salario_anterior']))),
                      DataCell(Text(fmt.format(r['salario_nuevo']))),
                      DataCell(
                        Text(
                          fmt.format(dif),
                          style: TextStyle(
                            color: difColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(Text(r['motivo']?.toString() ?? '—')),
                      DataCell(Text(r['aprobado_por']?.toString() ?? '—')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProvisionesTable() {
    final meta = _reportData!['meta'];
    final rows = List<Map<String, dynamic>>.from(_reportData!['rows'] ?? []);
    final totals = _reportData!['totals'] ?? {};

    return Column(
      children: [
        // Cabecera del Reporte
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.purple.shade50,
          child: Column(
            children: [
              Text(
                meta['title'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                meta['subtitle'] ?? '',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  Colors.purple.shade100,
                ),
                columns: const [
                  DataColumn(label: Text('Código')),
                  DataColumn(label: Text('Empleado')),
                  DataColumn(label: Text('Departamento')),
                  DataColumn(
                    label: Text('Prov. Regalía', textAlign: TextAlign.right),
                  ),
                  DataColumn(
                    label: Text('Prov. Vacaciones', textAlign: TextAlign.right),
                  ),
                  DataColumn(
                    label: Text('Prov. Cesantía', textAlign: TextAlign.right),
                  ),
                  DataColumn(
                    label: Text(
                      'TOTAL PROVISIONES',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
                rows: [
                  ...rows.map((r) {
                    final fmt = NumberFormat.currency(
                      symbol: '',
                      decimalDigits: 2,
                    );
                    return DataRow(
                      cells: [
                        DataCell(Text(r['codigo'].toString())),
                        DataCell(Text(r['empleado'].toString())),
                        DataCell(Text(r['departamento'].toString())),
                        DataCell(Text(fmt.format(r['prov_regalia']))),
                        DataCell(Text(fmt.format(r['prov_vacaciones']))),
                        DataCell(Text(fmt.format(r['prov_cesantia']))),
                        DataCell(
                          Text(
                            fmt.format(r['total_prov']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  // Totales
                  DataRow(
                    color: WidgetStateProperty.all(Colors.grey.shade200),
                    cells: [
                      const DataCell(Text('')),
                      const DataCell(
                        Text(
                          'TOTALES',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const DataCell(Text('')),
                      DataCell(
                        Text(
                          NumberFormat.currency(
                            symbol: '',
                            decimalDigits: 2,
                          ).format(totals['regalia']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          NumberFormat.currency(
                            symbol: '',
                            decimalDigits: 2,
                          ).format(totals['vacaciones']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          NumberFormat.currency(
                            symbol: '',
                            decimalDigits: 2,
                          ).format(totals['cesantia']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          NumberFormat.currency(
                            symbol: '',
                            decimalDigits: 2,
                          ).format(totals['total']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRetencionesISRTable() {
    final meta = _reportData!['meta'];
    final rows = List<Map<String, dynamic>>.from(_reportData!['rows'] ?? []);
    final totals = _reportData!['totals'] ?? {};

    return Column(
      children: [
        // Cabecera del Reporte
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.orange.shade50,
          child: Column(
            children: [
              Text(
                meta['title'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                meta['subtitle'] ?? '',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  Colors.orange.shade100,
                ),
                columns: const [
                  DataColumn(label: Text('Código')),
                  DataColumn(label: Text('Empleado')),
                  DataColumn(label: Text('Departamento')),
                  DataColumn(
                    label: Text('Ingreso Bruto', textAlign: TextAlign.right),
                  ),
                  DataColumn(
                    label: Text('ISR Retenido', textAlign: TextAlign.right),
                  ),
                  DataColumn(
                    label: Text('ISR Anualizado', textAlign: TextAlign.right),
                  ),
                ],
                rows: [
                  ...rows.map((r) {
                    final fmt = NumberFormat.currency(
                      symbol: '',
                      decimalDigits: 2,
                    );
                    return DataRow(
                      cells: [
                        DataCell(Text(r['codigo'].toString())),
                        DataCell(Text(r['empleado'].toString())),
                        DataCell(Text(r['departamento'].toString())),
                        DataCell(Text(fmt.format(r['ingreso_bruto']))),
                        DataCell(
                          Text(
                            fmt.format(r['isr_retenido']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        DataCell(Text(fmt.format(r['isr_anualizado']))),
                      ],
                    );
                  }),
                  // Totales
                  DataRow(
                    color: WidgetStateProperty.all(Colors.grey.shade200),
                    cells: [
                      const DataCell(Text('')),
                      const DataCell(
                        Text(
                          'TOTALES',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const DataCell(Text('')),
                      DataCell(
                        Text(
                          NumberFormat.currency(
                            symbol: '',
                            decimalDigits: 2,
                          ).format(totals['ingreso_bruto']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          NumberFormat.currency(
                            symbol: '',
                            decimalDigits: 2,
                          ).format(totals['isr_retenido']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          NumberFormat.currency(
                            symbol: '',
                            decimalDigits: 2,
                          ).format(totals['isr_anualizado']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanillaTSSTable() {
    final meta = _reportData!['meta'];
    final rows = List<Map<String, dynamic>>.from(_reportData!['rows'] ?? []);
    final totals = _reportData!['totals'] ?? {};

    return Column(
      children: [
        // Cabecera del Reporte
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.green.shade50,
          child: Column(
            children: [
              Text(
                meta['title'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                meta['subtitle'] ?? '',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.green.shade100),
                columns: const [
                  DataColumn(label: Text('No.')),
                  DataColumn(label: Text('No. TSS')),
                  DataColumn(label: Text('Nombre Completo')),
                  DataColumn(label: Text('AFP')),
                  DataColumn(label: Text('ARS')),
                  DataColumn(
                    label: Text(
                      'Salario Cotizable',
                      textAlign: TextAlign.right,
                    ),
                  ),
                  DataColumn(
                    label: Text('AFP Emp.', textAlign: TextAlign.right),
                  ),
                  DataColumn(
                    label: Text('SFS Emp.', textAlign: TextAlign.right),
                  ),
                  DataColumn(
                    label: Text('AFP Patron.', textAlign: TextAlign.right),
                  ),
                  DataColumn(
                    label: Text('SFS Patron.', textAlign: TextAlign.right),
                  ),
                ],
                rows: [
                  ...rows.map((r) {
                    final fmt = NumberFormat.currency(
                      symbol: '',
                      decimalDigits: 2,
                    );
                    return DataRow(
                      cells: [
                        DataCell(Text(r['num'].toString())),
                        DataCell(Text(r['no_tss'].toString())),
                        DataCell(Text(r['nombre'].toString())),
                        DataCell(Text(r['afp'].toString())),
                        DataCell(Text(r['ars'].toString())),
                        DataCell(Text(fmt.format(r['sal_cotizable']))),
                        DataCell(Text(fmt.format(r['afp_emp']))),
                        DataCell(Text(fmt.format(r['sfs_emp']))),
                        DataCell(Text(fmt.format(r['afp_patron']))),
                        DataCell(Text(fmt.format(r['sfs_patron']))),
                      ],
                    );
                  }),
                  // Totales
                  DataRow(
                    color: WidgetStateProperty.all(Colors.grey.shade200),
                    cells: [
                      const DataCell(Text('')),
                      const DataCell(
                        Text(
                          'TOTALES',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      DataCell(
                        Text(
                          NumberFormat.currency(
                            symbol: '',
                            decimalDigits: 2,
                          ).format(totals['sal_cotizable']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          NumberFormat.currency(
                            symbol: '',
                            decimalDigits: 2,
                          ).format(totals['afp_emp']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          NumberFormat.currency(
                            symbol: '',
                            decimalDigits: 2,
                          ).format(totals['sfs_emp']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          NumberFormat.currency(
                            symbol: '',
                            decimalDigits: 2,
                          ).format(totals['afp_patron']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          NumberFormat.currency(
                            symbol: '',
                            decimalDigits: 2,
                          ).format(totals['sfs_patron']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNominaConsolidadaTable() {
    final meta = _reportData!['meta'];
    final rows = List<Map<String, dynamic>>.from(_reportData!['rows'] ?? []);
    final totals = _reportData!['totals'] ?? {};

    return Column(
      children: [
        // Cabecera del Reporte
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Column(
            children: [
              Text(
                meta['title'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                meta['subtitle'] ?? '',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.blue.shade100),
                columns: const [
                  DataColumn(label: Text('Código')),
                  DataColumn(label: Text('Empleado')),
                  DataColumn(label: Text('Dpto.')),
                  DataColumn(
                    label: Text('Salario Base', textAlign: TextAlign.right),
                  ),
                  DataColumn(
                    label: Text('H.E/Var', textAlign: TextAlign.right),
                  ),
                  DataColumn(
                    label: Text('TOTAL BRUTO', textAlign: TextAlign.right),
                  ),
                  DataColumn(
                    label: Text('TSS SFS', textAlign: TextAlign.right),
                  ),
                  DataColumn(label: Text('AFP', textAlign: TextAlign.right)),
                  DataColumn(label: Text('ISR', textAlign: TextAlign.right)),
                  DataColumn(
                    label: Text('Préstamos', textAlign: TextAlign.right),
                  ),
                  DataColumn(
                    label: Text('Total Ded.', textAlign: TextAlign.right),
                  ),
                  DataColumn(
                    label: Text('NETO A PAGAR', textAlign: TextAlign.right),
                  ),
                ],
                rows: [
                  ...rows.map((r) {
                    final fmt = NumberFormat.currency(
                      symbol: '',
                      decimalDigits: 2,
                    );
                    return DataRow(
                      cells: [
                        DataCell(Text(r['codigo'].toString())),
                        DataCell(Text(r['empleado'].toString())),
                        DataCell(Text(r['departamento'].toString())),
                        DataCell(Text(fmt.format(r['sal_base']))),
                        DataCell(Text(fmt.format(r['he_var']))),
                        DataCell(
                          Text(
                            fmt.format(r['bruto']),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(Text(fmt.format(r['tss_sfs']))),
                        DataCell(Text(fmt.format(r['afp']))),
                        DataCell(Text(fmt.format(r['isr']))),
                        DataCell(Text(fmt.format(r['prestamo']))),
                        DataCell(
                          Text(
                            fmt.format(r['total_ded']),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        DataCell(
                          Text(
                            fmt.format(r['neto']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  // Totales
                  DataRow(
                    color: WidgetStateProperty.all(Colors.grey.shade200),
                    cells: [
                      const DataCell(Text('')),
                      const DataCell(
                        Text(
                          'TOTALES',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const DataCell(Text('')),
                      DataCell(
                        Text(
                          NumberFormat.currency(
                            symbol: '',
                            decimalDigits: 2,
                          ).format(totals['sal_base']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          NumberFormat.currency(
                            symbol: '',
                            decimalDigits: 2,
                          ).format(totals['he_var']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          NumberFormat.currency(
                            symbol: '',
                            decimalDigits: 2,
                          ).format(totals['bruto']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          NumberFormat.currency(
                            symbol: '',
                            decimalDigits: 2,
                          ).format(totals['tss_sfs']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          NumberFormat.currency(
                            symbol: '',
                            decimalDigits: 2,
                          ).format(totals['afp']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          NumberFormat.currency(
                            symbol: '',
                            decimalDigits: 2,
                          ).format(totals['isr']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          NumberFormat.currency(
                            symbol: '',
                            decimalDigits: 2,
                          ).format(totals['prestamo']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          NumberFormat.currency(
                            symbol: '',
                            decimalDigits: 2,
                          ).format(totals['total_ded']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          NumberFormat.currency(
                            symbol: '',
                            decimalDigits: 2,
                          ).format(totals['neto']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }
}
