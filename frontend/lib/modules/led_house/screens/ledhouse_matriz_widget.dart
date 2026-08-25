import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/ledhouse_provider.dart';

class LedhouseMatrizWidget extends StatefulWidget {
  const LedhouseMatrizWidget({super.key});

  @override
  State<LedhouseMatrizWidget> createState() => _LedhouseMatrizWidgetState();
}

class _LedhouseMatrizWidgetState extends State<LedhouseMatrizWidget> {
  int _selectedYear = DateTime.now().year;
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _tableScrollController = ScrollController();
  final currencyFormatter = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  final List<String> _meses = [
    'ENERO',
    'FEBRERO',
    'MARZO',
    'ABRIL',
    'MAYO',
    'JUNIO',
    'JULIO',
    'AGOSTO',
    'SEPTIEMBRE',
    'OCTUBRE',
    'NOVIEMBRE',
    'DICIEMBRE',
  ];

  int _getMesesVisibles(Map<String, dynamic> data) {
    if (_selectedYear < DateTime.now().year) {
      return 12;
    }
    int maxMonth = 1;
    for (var modulo in data.values) {
      if (modulo is Map<String, dynamic> && modulo.containsKey('cuentas')) {
        for (var cuenta in (modulo['cuentas'] as List)) {
          var meses = cuenta['meses'] as Map<String, dynamic>;
          meses.forEach((k, v) {
            if ((double.tryParse(v.toString()) ?? 0) != 0) {
              int m = int.tryParse(k) ?? 1;
              if (m > maxMonth) maxMonth = m;
            }
          });
        }
      }
    }
    return maxMonth;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMatriz();
    });
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  void _fetchMatriz() {
    Provider.of<LedhouseProvider>(
      context,
      listen: false,
    ).fetchMatrizAnual(year: _selectedYear);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LedhouseProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.registros.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Expanded(child: _buildDataTable(provider)),
            // Cabecera con selector de año y botón refrescar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Año: ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  DropdownButton<int>(
                    value: _selectedYear,
                    dropdownColor: Colors.white,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    underline: Container(),
                    icon: const Icon(
                      Icons.calendar_today,
                      color: Colors.black54,
                    ),
                    items: List.generate(10, (index) {
                      int year = DateTime.now().year - index + 2;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedYear = val);
                        _fetchMatriz();
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _fetchMatriz,
                    tooltip: 'Actualizar',
                  ),
                ],
              ),
            ),
          ],
        );
      },
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

  String _formatoMontoCorta(double monto) {
    if (monto >= 1000000) {
      return '\$${(monto / 1000000).toStringAsFixed(1)}M';
    } else if (monto >= 1000) {
      return '\$${(monto / 1000).toStringAsFixed(1)}K';
    }
    return '\$${monto.toStringAsFixed(0)}';
  }

  Widget _buildSummaryRow(
    String label,
    double value,
    Color color, {
    bool isPercentage = false,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          isPercentage
              ? '${value.toStringAsFixed(2)}%'
              : currencyFormatter.format(value),
          style: TextStyle(
            color: color,
            fontSize: isBold ? 16 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCabeceraPrincipal(Map<String, dynamic> data) {
    int mesesVisibles = _getMesesVisibles(data);
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _buildCell('Código Cuenta', width: 60, isHeader: true),
          _buildCell('Descripción de la Cuenta', width: 200, isHeader: true),
          ..._meses
              .take(mesesVisibles)
              .map((mes) => _buildCell(mes, width: 80, isHeader: true)),
          _buildCell(
            'TOTAL ANUAL',
            width: 90,
            isHeader: true,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildModulo(Map<String, dynamic> data, String moduloNombre) {
    if (!data.containsKey(moduloNombre)) {
      return [];
    }

    final moduloData = data[moduloNombre];
    final cuentas = moduloData['cuentas'] as List;
    final subtotales = moduloData['subtotales'] as Map<String, dynamic>;
    final totalAnualModulo =
        double.tryParse(moduloData['total_anual_modulo'].toString()) ?? 0;

    List<Widget> filas = [];
    int mesesVisibles = _getMesesVisibles(data);

    // Fila del módulo (Cabecera Celeste)
    filas.add(
      Container(
        color: Colors.lightBlue,
        child: Row(
          children: [
            _buildCell(
              '',
              width: 60,
              isHeader: true,
              textColor: Colors.white,
              color: Colors.lightBlue,
            ),
            _buildCell(
              moduloNombre,
              width: 200,
              isHeader: true,
              textColor: Colors.white,
              color: Colors.lightBlue,
            ),
            ..._meses
                .take(mesesVisibles)
                .map(
                  (mes) => _buildCell(
                    mes,
                    width: 80,
                    isHeader: true,
                    textColor: Colors.white,
                    color: Colors.lightBlue,
                  ),
                ),
            _buildCell(
              'TOTAL',
              width: 90,
              isHeader: true,
              textColor: Colors.white,
              color: Colors.lightBlue,
            ),
          ],
        ),
      ),
    );

    // Filas de las cuentas
    for (int i = 0; i < cuentas.length; i++) {
      var cuenta = cuentas[i];
      var montosMeses = cuenta['meses'] as Map<String, dynamic>;

      bool isEven = i % 2 == 0;
      Color rowColor = isEven ? Colors.white : Colors.grey.shade50;

      filas.add(
        Container(
          color: rowColor,
          child: Row(
            children: [
              _buildCell(cuenta['codigo'].toString(), width: 60),
              _buildCell(
                cuenta['descripcion'].toString(),
                width: 200,
                alignment: Alignment.centerLeft,
              ),
              ...List.generate(mesesVisibles, (index) {
                int mes = index + 1;
                double monto =
                    double.tryParse(
                      montosMeses[mes.toString()]?.toString() ?? '0',
                    ) ??
                    0;
                return _buildCell(
                  _formatoMonto(monto),
                  width: 80,
                  alignment: Alignment.centerRight,
                );
              }),
              _buildCell(
                _formatoMonto(
                  double.tryParse(cuenta['total_anual'].toString()) ?? 0,
                ),
                width: 90,
                alignment: Alignment.centerRight,
                isBold: true,
              ),
            ],
          ),
        ),
      );
    }

    // Fila de SUBTOTAL
    filas.add(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black, width: 1.5),
            bottom: BorderSide(color: Colors.black, width: 1.5),
          ),
        ),
        child: Row(
          children: [
            _buildCell('', width: 60, isBold: true),
            _buildCell(
              'SUBTOTAL',
              width: 200,
              alignment: Alignment.centerLeft,
              isBold: true,
            ),
            ...List.generate(mesesVisibles, (index) {
              int mes = index + 1;
              double monto =
                  double.tryParse(
                    subtotales[mes.toString()]?.toString() ?? '0',
                  ) ??
                  0;
              return _buildCell(
                _formatoMonto(monto),
                width: 80,
                alignment: Alignment.centerRight,
                isBold: true,
              );
            }),
            _buildCell(
              _formatoMonto(totalAnualModulo),
              width: 90,
              alignment: Alignment.centerRight,
              isBold: true,
            ),
          ],
        ),
      ),
    );

    return filas;
  }

  Widget _buildCell(
    String text, {
    required double width,
    bool isHeader = false,
    Alignment alignment = Alignment.center,
    Color? color,
    Color? textColor,
    bool isBold = false,
  }) {
    return Container(
      width: width,
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.grey.shade400, width: 0.5),
      ),
      alignment: alignment,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: (isHeader || isBold)
              ? FontWeight.bold
              : FontWeight.normal,
          fontSize: isHeader ? 10 : 9.5,
          color: textColor ?? Colors.black,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
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

  String _formatoMonto(double monto) {
    if (monto == 0) return '';
    if (monto < 0) {
      return '(\$ ${currencyFormatter.format(monto.abs()).replaceAll('\$', '')})';
    }
    return currencyFormatter.format(monto);
  }
}
