import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants.dart';
import '../../../core/auth_provider.dart';
import '../providers/ledhouse_provider.dart';

class LedhouseEstadoResultadoScreen extends StatefulWidget {
  const LedhouseEstadoResultadoScreen({super.key});

  @override
  State<LedhouseEstadoResultadoScreen> createState() =>
      _LedhouseEstadoResultadoScreenState();
}

class _LedhouseEstadoResultadoScreenState
    extends State<LedhouseEstadoResultadoScreen> {
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _moduloController = TextEditingController();

  String? _startDate;
  String? _endDate;
  String _selectedRange = 'Todo el año';
  String _selectedModuloFilter = 'TODOS';

  final ScrollController _tableScrollController = ScrollController();

  @override
  void dispose() {
    _codigoController.dispose();
    _moduloController.dispose();
    _tableScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyQuickFilter('Todo el año');
    });
  }

  void _applyQuickFilter(String range) {
    setState(() {
      _selectedRange = range;
      final now = DateTime.now();

      const meses = [
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

      if (meses.contains(range)) {
        int monthIndex = meses.indexOf(range) + 1;
        _startDate = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime(now.year, monthIndex, 1));
        _endDate = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime(now.year, monthIndex + 1, 0));
      } else {
        switch (range) {
          case 'Este mes':
            _startDate = DateFormat('yyyy-MM-01').format(now);
            _endDate = DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime(now.year, now.month + 1, 0));
            break;
          case 'Mes pasado':
            final lastMonth = DateTime(now.year, now.month - 1, 1);
            _startDate = DateFormat('yyyy-MM-01').format(lastMonth);
            _endDate = DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime(lastMonth.year, lastMonth.month + 1, 0));
            break;
          case '3 meses':
            final threeMonthsAgo = DateTime(now.year, now.month - 2, 1);
            _startDate = DateFormat('yyyy-MM-01').format(threeMonthsAgo);
            _endDate = DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime(now.year, now.month + 1, 0));
            break;
          case '6 meses':
            final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
            _startDate = DateFormat('yyyy-MM-01').format(sixMonthsAgo);
            _endDate = DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime(now.year, now.month + 1, 0));
            break;
          case 'Todo el año':
            _startDate = DateFormat('yyyy-01-01').format(now);
            _endDate = DateFormat('yyyy-12-31').format(now);
            break;
        }
      }
    });
    _fetchData();
  }

  void _fetchData() {
    final provider = Provider.of<LedhouseProvider>(context, listen: false);
    final modulo = _selectedModuloFilter == 'TODOS'
        ? null
        : _selectedModuloFilter;
    final codigo = _codigoController.text.trim().isEmpty
        ? null
        : _codigoController.text.trim();

    provider.fetchEstadoResultados(
      startDate: _startDate,
      endDate: _endDate,
      modulo: modulo,
      codigoCuenta: codigo,
    );
    provider.fetchSummary(
      startDate: _startDate,
      endDate: _endDate,
      modulo: modulo,
      codigoCuenta: codigo,
    );
  }

  Future<void> _downloadPdf() async {
    final provider = Provider.of<LedhouseProvider>(context, listen: false);

    if (provider.registros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay registros para generar el reporte.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final modulo = _selectedModuloFilter == 'TODOS'
        ? ''
        : _selectedModuloFilter;
    final codigo = _codigoController.text.trim();

    final queryParams = <String>[];
    if (_startDate != null) queryParams.add('start_date=$_startDate');
    if (_endDate != null) queryParams.add('end_date=$_endDate');
    if (modulo.isNotEmpty) queryParams.add('modulo=$modulo');
    if (codigo.isNotEmpty) queryParams.add('codigo_cuenta=$codigo');

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.join('&')}'
        : '';
    final urlStr = '$host/api/v1/ledhouse/estado-resultado/pdf$queryString';
    final url = Uri.parse(urlStr);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se pudo abrir el PDF.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado Financiero LED-HOUSE'),
        backgroundColor: const Color(0xFFFFFFFF),
        foregroundColor: Colors.black,
      ),
      body: Consumer<LedhouseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.registros.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilters(),
                const SizedBox(height: 20),
                if (provider.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      provider.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                _buildSummaryCards(provider),
                const SizedBox(height: 20),
                _buildCharts(provider),
                const SizedBox(height: 20),
                _buildDataTable(provider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'btnImport',
            onPressed: _importExcel,
            backgroundColor: Colors.green,
            icon: const Icon(Icons.file_upload, color: Colors.white),
            label: const Text(
              'Importar Excel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'btnAdd',
            onPressed: _showAddRegistroDialog,
            backgroundColor: const Color(0xFFE31E24),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showAddRegistroDialog() {
    showDialog(
      context: context,
      builder: (context) => const _AddRegistroDialog(),
    ).then((_) {
      _fetchData(); // Recargar datos si se agregó algo
    });
  }

  Future<void> _importExcel() async {
    final bool? shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Instrucciones de Importación'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El archivo Excel (.xlsx o .csv) debe tener exactamente el siguiente orden de columnas:',
            ),
            SizedBox(height: 8),
            Text('1. Código de Cuenta'),
            Text('2. Módulo (VENTAS, COSTOS o GASTOS)'),
            Text('3. Descripción de Cuenta'),
            Text('4. Monto'),
            Text('5. Fecha (Formato: YYYY-MM-DD)'),
            SizedBox(height: 16),
            Text('Nota: La primera fila se ignorará (puedes poner títulos).'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'Entendido, buscar archivo',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes == null) {
          throw Exception("No se pudieron leer los bytes del archivo.");
        }

        if (!mounted) return;

        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        final provider = Provider.of<LedhouseProvider>(context, listen: false);
        final response = await provider.importRegistros(file.bytes!, file.name);

        if (!mounted) return;
        Navigator.pop(context); // Close loading

        if (response != null && response['message'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.green,
            ),
          );
          if (response['errors'] != null &&
              (response['errors'] as List).isNotEmpty) {
            _showErrorsDialog(List<String>.from(response['errors']));
          }
          _fetchData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error ?? "Error desconocido al importar."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showErrorsDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Algunos registros fallaron'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: errors.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.error, color: Colors.red),
                title: Text(errors[index]),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final List<String> opcionesFiltro = [
      'Este mes',
      'Mes pasado',
      '3 meses',
      '6 meses',
      'Todo el año',
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

    return Row(
      children: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.calendar_month),
          tooltip: 'Filtro de Fecha',
          onSelected: (range) {
            _applyQuickFilter(range);
          },
          itemBuilder: (context) => opcionesFiltro
              .map(
                (range) => PopupMenuItem(
                  value: range,
                  child: Text(
                    range,
                    style: TextStyle(
                      fontWeight: _selectedRange == range
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color:
                          [
                            'Este mes',
                            'Mes pasado',
                            '3 meses',
                            '6 meses',
                            'Todo el año',
                          ].contains(range)
                          ? Colors.black
                          : Colors
                                .blueGrey, // Para diferenciar visualmente los meses estáticos
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: DropdownButtonFormField<String>(
            value: _selectedModuloFilter,
            decoration: const InputDecoration(
              labelText: 'Módulo',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              'TODOS',
              'VENTAS',
              'COSTOS',
              'GASTOS',
            ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedModuloFilter = val);
                _fetchData();
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: _codigoController,
            decoration: const InputDecoration(
              labelText: 'Código Cuenta',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) => _fetchData(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _fetchData,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
          style: IconButton.styleFrom(backgroundColor: Colors.blue.shade50),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _downloadPdf,
          icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
          tooltip: 'Descargar PDF',
          style: IconButton.styleFrom(backgroundColor: Colors.red.shade50),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(LedhouseProvider provider) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    double ventas = 0;
    double costos = 0;
    double gastos = 0;

    for (var data in provider.pieChartData) {
      String modulo = data['modulo'].toString().toUpperCase();
      double amount = double.tryParse(data['total'].toString()) ?? 0;

      if (modulo == 'VENTAS') ventas = amount;
      if (modulo == 'COSTOS') costos = amount;
      if (modulo == 'GASTOS') gastos = amount;
    }

    double utilidad = ventas - costos - gastos;
    double margenUtilidad = ventas > 0 ? (utilidad / ventas) * 100 : 0;

    return Card(
      color: const Color(0xFF1A1C1E),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ventas',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Text(
                  currencyFormatter.format(ventas),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Utilidad Neta',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Text(
                  currencyFormatter.format(utilidad),
                  style: TextStyle(
                    color: utilidad >= 0
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Margen de Util.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Text(
                  '${margenUtilidad.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: margenUtilidad >= 0
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts(LedhouseProvider provider) {
    if (provider.barChartData.isEmpty && provider.pieChartData.isEmpty) {
      return const SizedBox.shrink();
    }

    final currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    // Procesar datos para el gráfico de barras por mes y pilar
    final Map<String, Map<String, double>> monthlyData = {};
    for (var data in provider.barChartData) {
      String mes = data['mes']?.toString() ?? '';
      if (mes.isEmpty) continue;
      String modulo = data['modulo']?.toString().toUpperCase() ?? '';
      double total = double.tryParse(data['total'].toString()) ?? 0;

      monthlyData.putIfAbsent(
        mes,
        () => {'VENTAS': 0.0, 'COSTOS': 0.0, 'GASTOS': 0.0, 'GANANCIA': 0.0},
      );
      if (['VENTAS', 'COSTOS', 'GASTOS'].contains(modulo)) {
        monthlyData[mes]![modulo] = (monthlyData[mes]![modulo] ?? 0) + total;
      }
    }

    double maxBarY = 0;
    monthlyData.forEach((mes, values) {
      values['GANANCIA'] =
          (values['VENTAS'] ?? 0) -
          (values['COSTOS'] ?? 0) -
          (values['GASTOS'] ?? 0);

      // Encontrar el valor máximo para escalar el gráfico
      for (var val in values.values) {
        if (val.abs() > maxBarY) maxBarY = val.abs();
      }
    });

    final sortedMonths = monthlyData.keys.toList()..sort();

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Evolución Mensual',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem(Colors.green, 'Ventas'),
                          const SizedBox(width: 12),
                          _buildLegendItem(Colors.orange, 'Costos'),
                          const SizedBox(width: 12),
                          _buildLegendItem(Colors.red, 'Gastos'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            maxY: maxBarY > 0 ? maxBarY * 1.2 : 100,
                            alignment: BarChartAlignment.spaceAround,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (group) =>
                                    Colors.white.withOpacity(0.9),
                                tooltipPadding: const EdgeInsets.all(8),
                                tooltipMargin: 8,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  String label = '';
                                  if (rodIndex == 0) label = 'Ventas: ';
                                  if (rodIndex == 1) label = 'Costos: ';
                                  if (rodIndex == 2) label = 'Gastos: ';

                                  return BarTooltipItem(
                                    '$label${currencyFormatter.format(rod.toY)}',
                                    const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= 0 &&
                                        value.toInt() < sortedMonths.length) {
                                      String mesStr =
                                          sortedMonths[value.toInt()];
                                      final parts = mesStr.split('-');
                                      if (parts.length == 2) {
                                        const months = [
                                          'Ene',
                                          'Feb',
                                          'Mar',
                                          'Abr',
                                          'May',
                                          'Jun',
                                          'Jul',
                                          'Ago',
                                          'Sep',
                                          'Oct',
                                          'Nov',
                                          'Dic',
                                        ];
                                        int monthIndex =
                                            int.tryParse(parts[1]) ?? 0;
                                        if (monthIndex >= 1 &&
                                            monthIndex <= 12) {
                                          mesStr = months[monthIndex - 1];
                                        }
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          mesStr,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                  reservedSize: 30,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 60,
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0) return const Text('');
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: Text(
                                        currencyFormatter.format(value),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: const FlGridData(show: true),
                            borderData: FlBorderData(show: false),
                            barGroups: sortedMonths.asMap().entries.map((
                              entry,
                            ) {
                              int index = entry.key;
                              var values = monthlyData[entry.value]!;
                              return BarChartGroupData(
                                x: index,
                                barsSpace: 4,
                                barRods: [
                                  BarChartRodData(
                                    toY: values['VENTAS'] ?? 0,
                                    color: Colors.green,
                                    width: 8,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  BarChartRodData(
                                    toY: values['COSTOS'] ?? 0,
                                    color: Colors.orange,
                                    width: 8,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  BarChartRodData(
                                    toY: values['GASTOS'] ?? 0,
                                    color: Colors.red,
                                    width: 8,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Distribución por Módulo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                            sections: provider.pieChartData.map((data) {
                              double total =
                                  double.tryParse(data['total'].toString()) ??
                                  0;
                              return PieChartSectionData(
                                color: _getColorForModule(data['modulo']),
                                value: total,
                                title:
                                    '${data['modulo']}\n${currencyFormatter.format(total)}',
                                radius: 60,
                                titleStyle: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Evolución de Ganancias Neta',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 150,
                  child: LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (group) =>
                              Colors.white.withOpacity(0.9),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                currencyFormatter.format(spot.y),
                                TextStyle(
                                  color: spot.y >= 0
                                      ? Colors.blue.shade700
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      gridData: const FlGridData(show: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < sortedMonths.length) {
                                String mesStr = sortedMonths[value.toInt()];
                                final parts = mesStr.split('-');
                                if (parts.length == 2) {
                                  const months = [
                                    'Ene',
                                    'Feb',
                                    'Mar',
                                    'Abr',
                                    'May',
                                    'Jun',
                                    'Jul',
                                    'Ago',
                                    'Sep',
                                    'Oct',
                                    'Nov',
                                    'Dic',
                                  ];
                                  int monthIndex = int.tryParse(parts[1]) ?? 0;
                                  if (monthIndex >= 1 && monthIndex <= 12) {
                                    mesStr = months[monthIndex - 1];
                                  }
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    mesStr,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                            reservedSize: 30,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const Text('');
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  currencyFormatter.format(value),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: sortedMonths.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              monthlyData[entry.value]!['GANANCIA'] ?? 0,
                            );
                          }).toList(),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withOpacity(0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getColorForModule(String modulo) {
    switch (modulo.toUpperCase()) {
      case 'VENTAS':
        return Colors.green;
      case 'COSTOS':
        return Colors.orange;
      case 'GASTOS':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildDataTable(LedhouseProvider provider) {
    if (provider.registros.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text('No hay registros encontrados.')),
        ),
      );
    }

    final currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalle de Registros',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 450),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Scrollbar(
                thumbVisibility: true,
                controller: _tableScrollController,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  controller: _tableScrollController,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      headingRowColor: WidgetStateProperty.all(
                        Colors.grey.shade200,
                      ),
                      dividerThickness: 0.5,
                      dataRowMaxHeight: 50,
                      columns: const [
                        DataColumn(label: Text('Fecha')),
                        DataColumn(label: Text('Código')),
                        DataColumn(label: Text('Módulo')),
                        DataColumn(label: Text('Descripción')),
                        DataColumn(label: Text('Monto')),
                        DataColumn(label: Text('Registrado por')),
                      ],
                      rows: provider.registros.asMap().entries.map((entry) {
                        int index = entry.key;
                        var r = entry.value;
                        return DataRow(
                          color: WidgetStateProperty.resolveWith<Color?>((
                            Set<WidgetState> states,
                          ) {
                            if (states.contains(WidgetState.hovered)) {
                              return Colors.blue.withOpacity(0.1);
                            }
                            return index.isEven
                                ? Colors.white
                                : Colors.grey.shade50;
                          }),
                          cells: [
                            DataCell(Text(r.fecha)),
                            DataCell(Text(r.codigoCuenta)),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getColorForModule(
                                    r.modulo,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  r.modulo,
                                  style: TextStyle(
                                    color: _getColorForModule(r.modulo),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(r.descripcionDeCuenta)),
                            DataCell(
                              Text(
                                currencyFormatter.format(r.monto),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(Text(r.registedBy ?? 'N/A')),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddRegistroDialog extends StatefulWidget {
  const _AddRegistroDialog();

  @override
  State<_AddRegistroDialog> createState() => _AddRegistroDialogState();
}

class _AddRegistroDialogState extends State<_AddRegistroDialog> {
  final _formKey = GlobalKey<FormState>();

  final _codigoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _montoController = TextEditingController();

  String _selectedModulo = 'VENTAS';
  DateTime _selectedDate = DateTime.now();

  bool _isSaving = false;

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = Provider.of<LedhouseProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String currentUsername = authProvider.username ?? 'Admin';

    final data = {
      'codigo_cuenta': _codigoController.text.toUpperCase().trim(),
      'modulo': _selectedModulo.toUpperCase().trim(),
      'descripcion_de_cuenta': _descripcionController.text.toUpperCase().trim(),
      'monto': double.parse(_montoController.text.trim()),
      'fecha': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'registed_by': currentUsername,
    };

    final success = await provider.createRegistro(data);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro guardado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE31E24), width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.add_chart, color: Color(0xFFE31E24), size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Nuevo Registro',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1C1E),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 32),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INFORMACIÓN GENERAL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _codigoController,
                              decoration: _inputDecoration(
                                'Código Cuenta *',
                                Icons.tag,
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Requerido'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _selectedModulo,
                              decoration: _inputDecoration(
                                'Módulo *',
                                Icons.category_outlined,
                              ),
                              items: ['VENTAS', 'COSTOS', 'GASTOS'].map((m) {
                                return DropdownMenuItem(
                                  value: m,
                                  child: Text(m),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedModulo = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descripcionController,
                        decoration: _inputDecoration(
                          'Descripción *',
                          Icons.description_outlined,
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _montoController,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+(\.\d{0,2})?$'),
                                ),
                              ],
                              decoration: _inputDecoration(
                                'Monto *',
                                Icons.attach_money,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Requerido';
                                }
                                if (double.tryParse(val) == null) {
                                  return 'Monto inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: Color(
                                            0xFFE31E24,
                                          ), // color principal
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (date != null) {
                                  setState(() => _selectedDate = date);
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: IgnorePointer(
                                child: TextFormField(
                                  key: ValueKey(_selectedDate),
                                  initialValue: DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(_selectedDate),
                                  decoration: _inputDecoration(
                                    'Fecha',
                                    Icons.calendar_today_outlined,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'CANCELAR',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE31E24),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'GUARDAR',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
