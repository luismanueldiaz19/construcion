import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants.dart';
import '../providers/ledhouse_provider.dart';
import '../componentes/ganancia_neta_chart_widget.dart';
import '../componentes/evolucion_mensual_chart_widget.dart';
import '../componentes/resumen_anual_widget.dart';
import '../componentes/add_registro_dialog_widget.dart';
import '../componentes/reporte_por_cuentas_widget.dart';
import 'ledhouse_detalles_cuentas.dart';

class LedhouseDetallesScreen extends StatefulWidget {
  const LedhouseDetallesScreen({super.key});

  @override
  State<LedhouseDetallesScreen> createState() => _LedhouseDetallesScreenState();
}

class _LedhouseDetallesScreenState extends State<LedhouseDetallesScreen> {
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _moduloController = TextEditingController();

  String? _startDate;
  String? _endDate;
  String _selectedRange = 'Todo el año';
  String _selectedModuloFilter = 'TODOS';
  final currencyFormatter = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );
  // final ScrollController _tableScrollController = ScrollController();
  final int _selectedYear = DateTime.now().year;

  @override
  void dispose() {
    _codigoController.dispose();
    _moduloController.dispose();
    // _tableScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyQuickFilter('Todo el año');
      _fetchMatriz();
    });
  }

  void _fetchMatriz() {
    Provider.of<LedhouseProvider>(
      context,
      listen: false,
    ).fetchMatrizAnual(year: _selectedYear);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado Financiero LED-HOUSE'),
        backgroundColor: const Color(0xFFFFFFFF),
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),

          IconButton(
            tooltip: 'Añadir Registro',
            onPressed: _showAddRegistroDialog,
            icon: const Icon(Icons.add_circle_outline),
            color: const Color(0xFFE31E24), // Rojo
          ),
          IconButton(
            tooltip: 'Importar Excel',
            onPressed: _importExcel,
            icon: const Icon(Icons.file_upload),
            color: Colors.green, // Verde
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Consumer<LedhouseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.registros.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.isMatrizLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.matrizData.isEmpty) {
            return const Center(child: Text('No hay datos para este año.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (provider.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      provider.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                _buildCharts(provider),
                SizedBox(
                  height: 1000,
                  child: ReportePorCuentasWidget(
                    matrizData: provider.matrizData,
                    selectedYear: _selectedYear,
                    currencyFormatter: currencyFormatter,
                  ),
                ),
              ],
            ),
          );
        },
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              EvolucionMensualChartWidget(
                monthlyData: monthlyData,
                sortedMonths: sortedMonths,
                maxBarY: maxBarY,
                currencyFormatter: currencyFormatter,
              ),

              const SizedBox(height: 16),
              GananciaNetaChartWidget(
                monthlyData: monthlyData,
                sortedMonths: sortedMonths,
                currencyFormatter: currencyFormatter,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: ResumenAnualWidget(
            ventas: ventas,
            costos: costos,
            gastos: gastos,
            utilidad: utilidad,
            margenUtilidad: margenUtilidad,
            pieChartData: provider.pieChartData,
            currencyFormatter: currencyFormatter,
          ),
        ),
      ],
    );
  }

  void _showAddRegistroDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddRegistroDialogWidget(),
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
}

final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
