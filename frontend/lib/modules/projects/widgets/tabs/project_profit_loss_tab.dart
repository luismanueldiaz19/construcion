import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/proyecto.dart';
import '../../../../models/gasto_proyecto.dart';
import '../../../../models/consumo_proyecto.dart';
import '../../../../services/accounting_service.dart';
class ProjectProfitLossTab extends StatefulWidget {
  final Proyecto proyecto;
  final List<GastoProyecto> gastos;
  final List<ConsumoProyecto> consumos;

  const ProjectProfitLossTab({
    super.key,
    required this.proyecto,
    required this.gastos,
    required this.consumos,
  });

  @override
  State<ProjectProfitLossTab> createState() => _ProjectProfitLossTabState();
}

class _ProjectProfitLossTabState extends State<ProjectProfitLossTab> {
  final AccountingService _accountingService = AccountingService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant ProjectProfitLossTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.proyecto.id != oldWidget.proyecto.id ||
        widget.gastos != oldWidget.gastos ||
        widget.consumos != oldWidget.consumos) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _accountingService.getEstadoResultados(
        proyectoId: widget.proyecto.id,
      );
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(dynamic value, {bool isNegative = false}) {
    final val = double.tryParse(value?.toString() ?? '0') ?? 0;
    final f = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);
    final isZero = val.abs() < 0.005;

    if (isZero) {
      return f.format(0.0);
    } else if (isNegative && val > 0) {
      return "(${f.format(val)})";
    } else if (val < 0) {
      return "(${f.format(val.abs())})";
    } else {
      return f.format(val);
    }
  }

  String _formatPeriod(Proyecto p) {
    if (p.fechaInicio != null && p.fechaFin != null) {
      final f = DateFormat('dd/MM/yyyy');
      return "${f.format(p.fechaInicio!)} - ${f.format(p.fechaFin!)}";
    }
    final now = DateTime.now();
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return "${months[now.month - 1]} ${now.year}";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error al cargar el estado de resultados:\n$_errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 950;
        return Column(
          children: [
            if (_isLoading) const LinearProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Row with title, period and refresh button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ESTADO DE RESULTADOS',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1C1E),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Período: ${_formatPeriod(widget.proyecto)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.blueGrey,
                          ),
                          onPressed: _loadData,
                          tooltip: 'Actualizar Estado de Resultados',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 1. Tarjetas Resumen en la Parte Superior
                    _buildSummaryCards(),
                    const SizedBox(height: 16),

                    // Main layout body (Responsive two-column or single column)
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              children: [
                                _buildContractInfoCard(),
                                const SizedBox(height: 16),
                                _buildPresupuestoVsRealCard(),
                                const SizedBox(height: 16),
                                _buildManagementIndicatorsCard(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                _buildReportCard(),
                                const SizedBox(height: 16),
                                _buildExecutiveChartCard(),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildContractInfoCard(),
                          const SizedBox(height: 16),
                          _buildPresupuestoVsRealCard(),
                          const SizedBox(height: 16),
                          _buildManagementIndicatorsCard(),
                          const SizedBox(height: 16),
                          _buildReportCard(),
                          const SizedBox(height: 16),
                          _buildExecutiveChartCard(),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 1. summary metrics cards
  Widget _buildSummaryCards() {
    if (_data == null) return const SizedBox.shrink();

    final ingresos =
        double.tryParse(_data!['ingresos']?.toString() ?? '0') ?? 0;
    final costos = double.tryParse(_data!['costos']?.toString() ?? '0') ?? 0;
    final utilidadBruta =
        double.tryParse(_data!['utilidad_bruta']?.toString() ?? '0') ?? 0;
    final utilidadNeta =
        double.tryParse(_data!['utilidad_neta']?.toString() ?? '0') ?? 0;
    final margen = ingresos > 0 ? (utilidadNeta / ingresos * 100) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        // Adjust column count based on available space
        final int crossAxisCount = width > 800 ? 5 : (width > 500 ? 3 : 2);
        final double childAspectRatio = width > 800 ? 1.4 : 1.6;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: childAspectRatio,
          children: [
            _buildMetricCard(
              'Ingresos Totales',
              _formatCurrency(ingresos),
              Colors.green[700]!,
              Icons.trending_up,
            ),
            _buildMetricCard(
              'Costos Totales',
              _formatCurrency(costos),
              Colors.red[700]!,
              Icons.trending_down,
            ),
            _buildMetricCard(
              'Utilidad Bruta',
              _formatCurrency(utilidadBruta),
              Colors.blue[700]!,
              Icons.account_balance_wallet,
            ),
            _buildMetricCard(
              'Utilidad Neta',
              _formatCurrency(utilidadNeta),
              utilidadNeta >= 0 ? Colors.green[800]! : Colors.red[800]!,
              Icons.monetization_on,
              subtitle: 'Margen: ${margen.toStringAsFixed(2)}%',
            ),
            _buildMetricCard(
              'Margen Neto',
              '${margen.toStringAsFixed(2)}%',
              Colors.teal[700]!,
              Icons.percent,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    Color color,
    IconData icon, {
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(icon, color: color.withOpacity(0.8), size: 16),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else
              const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  // 3. Contract Information and Financial Progress
  Widget _buildContractInfoCard() {
    final contrato =
        widget.proyecto.totalPresupuestoConGlobales ??
        widget.proyecto.presupuestoEstimado;
        
    // Ingreso neto contable (sin impuestos)
    final ingresosNetos =
        double.tryParse(_data?['ingresos']?.toString() ?? '0') ?? 0;
        
    // Total de dinero recibido del cliente
    final cobrado = widget.proyecto.totalCobrado ?? 0;
    
    // Lo que falta por cobrar del proyecto entero
    final pendiente = contrato - cobrado;
    
    // Porcentaje de dinero recibido vs el total del contrato
    final avanceFinanciero = contrato > 0 ? (cobrado / contrato * 100) : 0.0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Contrato y Cobros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2F33),
              ),
            ),
            const Divider(height: 24),
            _buildContractRow(
              'Monto Total del Proyecto',
              _formatCurrency(contrato),
              Colors.black87,
            ),
            _buildContractRow(
              'Total Cobrado al Cliente',
              _formatCurrency(cobrado),
              Colors.green[700]!,
            ),
            _buildContractRow(
              'Balance Pendiente de Pago',
              _formatCurrency(pendiente),
              pendiente > 0 ? Colors.orange[800]! : Colors.grey[700]!,
              isBold: true,
            ),
            const SizedBox(height: 8),
            _buildContractRow(
              'Ingresos Contables (Sin Impuestos)',
              _formatCurrency(ingresosNetos),
              Colors.blue[800]!,
            ),
            const SizedBox(height: 20),
            // 4. Financial Progress indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Avance Financiero (Cobrado / Proyecto)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${avanceFinanciero.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (avanceFinanciero / 100).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractRow(
    String label,
    String value,
    Color valueColor, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey[800],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // 5. Comparación Presupuesto vs Real
  Widget _buildPresupuestoVsRealCard() {
    double moPresupuesto = 0.0;
    double equiposPresupuesto = 0.0;
    double materialesPresupuesto = 0.0;

    for (var partida in widget.proyecto.partidas) {
      for (var sub in partida.subpartidas) {
        final desc = sub.descripcion.toLowerCase();
        if (desc.contains('mano de obra') ||
            desc.contains('mo ') ||
            desc.contains(' mo') ||
            desc.contains('jornal') ||
            desc.contains('albañil') ||
            desc.contains('pintor') ||
            desc.contains('personal') ||
            desc.contains('labor')) {
          moPresupuesto += sub.totalPresupuestado;
        } else if (desc.contains('alquiler') ||
            desc.contains('equipo') ||
            desc.contains('herramienta') ||
            desc.contains('maquinaria') ||
            desc.contains('mezcladora') ||
            desc.contains('andamio')) {
          equiposPresupuesto += sub.totalPresupuestado;
        } else {
          materialesPresupuesto += sub.totalPresupuestado;
        }
      }
    }

    final double moReal = widget.gastos
        .where((g) => g.tipoGasto.toLowerCase().contains('mano de obra'))
        .fold(0.0, (sum, g) => sum + g.monto);
    final double equiposReal = widget.gastos
        .where(
          (g) =>
              g.tipoGasto.toLowerCase().contains('alquiler') ||
              g.tipoGasto.toLowerCase().contains('equipo'),
        )
        .fold(0.0, (sum, g) => sum + g.monto);
    final double materialesReal = widget.consumos.fold(
      0.0,
      (sum, c) => sum + c.total,
    );

    final double totalPresupuesto =
        moPresupuesto + equiposPresupuesto + materialesPresupuesto;
    final double totalReal = moReal + equiposReal + materialesReal;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparativa Presupuesto vs Real (Costo Directo)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2F33),
              ),
            ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(2),
              },
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              children: [
                TableRow(
                  children: [
                    _buildTableHeaderCell('Concepto'),
                    _buildTableHeaderCell('Presupuesto'),
                    _buildTableHeaderCell('Real'),
                    _buildTableHeaderCell('Diferencia'),
                  ],
                ),
                _buildTableRow(
                  'Materiales',
                  materialesPresupuesto,
                  materialesReal,
                ),
                _buildTableRow('Mano de Obra', moPresupuesto, moReal),
                _buildTableRow(
                  'Equipos y Herramientas',
                  equiposPresupuesto,
                  equiposReal,
                ),
                _buildTableRow(
                  'Total Directo',
                  totalPresupuesto,
                  totalReal,
                  isTotal: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  TableRow _buildTableRow(
    String concepto,
    double presupuesto,
    double real, {
    bool isTotal = false,
  }) {
    final dif = presupuesto - real;
    final isOverrun = dif < 0; // Negative means overrun (Real > Presupuesto)
    final textStyle = TextStyle(
      fontSize: 12,
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      color: isTotal ? const Color(0xFF1A1C1E) : Colors.black87,
    );

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(concepto, style: textStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(_formatCurrency(presupuesto), style: textStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(_formatCurrency(real), style: textStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            _formatCurrency(dif, isNegative: isOverrun),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isZero(dif)
                  ? Colors.black87
                  : (isOverrun ? Colors.red[700] : Colors.green[700]),
            ),
          ),
        ),
      ],
    );
  }

  bool isZero(double value) {
    return value.abs() < 0.005;
  }

  // 9. Agregar Indicadores de Gestión
  Widget _buildManagementIndicatorsCard() {
    if (_data == null) return const SizedBox.shrink();

    final ingresos =
        double.tryParse(_data!['ingresos']?.toString() ?? '0') ?? 0;
    final utilidadBruta =
        double.tryParse(_data!['utilidad_bruta']?.toString() ?? '0') ?? 0;
    final utilidadNeta =
        double.tryParse(_data!['utilidad_neta']?.toString() ?? '0') ?? 0;
    final contrato =
        widget.proyecto.totalPresupuestoConGlobales ??
        widget.proyecto.presupuestoEstimado;

    final double moReal = widget.gastos
        .where((g) => g.tipoGasto.toLowerCase().contains('mano de obra'))
        .fold(0.0, (sum, g) => sum + g.monto);
    final double equiposReal = widget.gastos
        .where(
          (g) =>
              g.tipoGasto.toLowerCase().contains('alquiler') ||
              g.tipoGasto.toLowerCase().contains('equipo'),
        )
        .fold(0.0, (sum, g) => sum + g.monto);
    final double materialesReal = widget.consumos.fold(
      0.0,
      (sum, c) => sum + c.total,
    );
    final totalReal = moReal + equiposReal + materialesReal;

    final margenBruto = ingresos > 0 ? (utilidadBruta / ingresos * 100) : 0.0;
    final margenNeto = ingresos > 0 ? (utilidadNeta / ingresos * 100) : 0.0;
    final cobrado = widget.proyecto.totalCobrado ?? 0;
    final cuentasPorCobrar = ingresos - cobrado;
    final costoRealVsPresupuesto = contrato > 0
        ? (totalReal / contrato * 100)
        : 0.0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Indicadores Financieros y Gestión',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2F33),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildIndicatorBadge(
                  'Margen Bruto',
                  '${margenBruto.toStringAsFixed(1)}%',
                  Colors.blue,
                ),
                _buildIndicatorBadge(
                  'Margen Neto',
                  '${margenNeto.toStringAsFixed(1)}%',
                  margenNeto >= 0 ? Colors.green : Colors.red,
                ),
                _buildIndicatorBadge(
                  'Cuentas por Cobrar',
                  _formatCurrency(cuentasPorCobrar),
                  Colors.orange,
                ),
                _buildIndicatorBadge(
                  'Costo Real vs Presupuesto',
                  '${costoRealVsPresupuesto.toStringAsFixed(1)}%',
                  costoRealVsPresupuesto <= 100 ? Colors.teal : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // 8. Gráfico Ejecutivo
  Widget _buildExecutiveChartCard() {
    if (_data == null) return const SizedBox.shrink();

    final ingresos =
        double.tryParse(_data!['ingresos']?.toString() ?? '0') ?? 0;
    final costos = double.tryParse(_data!['costos']?.toString() ?? '0') ?? 0;
    final utilidadNeta =
        double.tryParse(_data!['utilidad_neta']?.toString() ?? '0') ?? 0;

    final maxVal = [
      ingresos,
      costos,
      utilidadNeta.abs(),
    ].reduce((curr, next) => curr > next ? curr : next);
    final double maxBarHeight = 110.0;

    double hIngresos = maxVal > 0 ? (ingresos / maxVal * maxBarHeight) : 0.0;
    double hCostos = maxVal > 0 ? (costos / maxVal * maxBarHeight) : 0.0;
    double hUtilidad = maxVal > 0
        ? (utilidadNeta.abs() / maxVal * maxBarHeight)
        : 0.0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gráfico Ejecutivo de Flujo (Ingresos vs Costos vs Utilidad)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2F33),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBarCol(
                  'Ingresos',
                  hIngresos,
                  _formatCurrency(ingresos),
                  Colors.green,
                ),
                _buildBarCol(
                  'Costos',
                  hCostos,
                  _formatCurrency(costos),
                  Colors.red,
                ),
                _buildBarCol(
                  utilidadNeta >= 0 ? 'Utilidad Neta' : 'Pérdida Neta',
                  hUtilidad,
                  _formatCurrency(utilidadNeta),
                  utilidadNeta >= 0 ? Colors.blue : Colors.red[900]!,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildBarCol(
    String label,
    double height,
    String valueText,
    Color color,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          valueText,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 32,
          height: height.clamp(4.0, 110.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard() {
    if (_data == null)
      return const Center(child: Text('No hay datos disponibles'));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Text(
                    'ESTADO DE RESULTADOS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PROYECTO ESPECÍFICO',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fecha del reporte: ${_data!['fecha_reporte']}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const Divider(height: 30, thickness: 1.5),
                ],
              ),
            ),
            _buildSectionTitle('INGRESOS OPERACIONALES'),
            _buildLine(
              'Ingresos por Proyectos / Construcción',
              _data!['ingresos'],
              isSub: true,
            ),
            const SizedBox(height: 12),
            _buildTotalLine('TOTAL INGRESOS', _data!['ingresos']),

            const SizedBox(height: 24),
            _buildSectionTitle('COSTOS DE VENTAS'),
            _buildLine(
              'Costos de Construcción (Materiales y MO)',
              _data!['costos'],
              isSub: true,
            ),
            const SizedBox(height: 12),
            _buildTotalLine('TOTAL COSTOS', _data!['costos'], isNegative: true),

            const Divider(height: 30, thickness: 1.5, color: Colors.black12),
            _buildTotalLine(
              'UTILIDAD BRUTA',
              _data!['utilidad_bruta'],
              isBold: true,
              color: Colors.blue[900],
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('GASTOS OPERATIVOS'),
            _buildLine(
              'Gastos Administrativos y Otros',
              _data!['gastos'],
              isSub: true,
            ),
            const SizedBox(height: 12),
            _buildTotalLine('TOTAL GASTOS', _data!['gastos'], isNegative: true),

            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'UTILIDAD NETA DEL PERIODO',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    _formatCurrency(_data!['utilidad_neta']),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _data!['utilidad_neta'] >= 0
                          ? Colors.green[700]
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildLine(String label, dynamic value, {bool isSub = false}) {
    final val = double.tryParse(value?.toString() ?? '0') ?? 0;
    return Padding(
      padding: EdgeInsets.only(left: isSub ? 16 : 0, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[800], fontSize: 12),
            ),
          ),
          Text(_formatCurrency(val), style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTotalLine(
    String label,
    dynamic value, {
    bool isNegative = false,
    bool isBold = false,
    Color? color,
  }) {
    final val = double.tryParse(value?.toString() ?? '0') ?? 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
        Text(
          _formatCurrency(val, isNegative: isNegative),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }
}


