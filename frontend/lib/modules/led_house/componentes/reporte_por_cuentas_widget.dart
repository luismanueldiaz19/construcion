import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants.dart';
import '../screens/ledhouse_detalles_cuentas.dart';

class ReportePorCuentasWidget extends StatefulWidget {
  final Map<String, dynamic> matrizData;
  final int selectedYear;
  final NumberFormat currencyFormatter;

  const ReportePorCuentasWidget({
    super.key,
    required this.matrizData,
    required this.selectedYear,
    required this.currencyFormatter,
  });

  @override
  State<ReportePorCuentasWidget> createState() =>
      _ReportePorCuentasWidgetState();
}

class _ReportePorCuentasWidgetState extends State<ReportePorCuentasWidget> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  List<int> _selectedMonths = [];
  String? _selectedModulo;

  final List<String> _meses = [
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

  Future<void> _downloadMatrizPdf() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generando PDF, por favor espera...')),
    );

    String urlStr =
        '$host/api/v1/ledhouse/estado-resultado/matriz-pdf?year=${widget.selectedYear}';
    
    if (_selectedModulo != null) {
      urlStr += '&modulo=$_selectedModulo';
    }
    if (_selectedMonths.isNotEmpty) {
      urlStr += '&meses=${_selectedMonths.join(",")}';
    }

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
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  int _getMesesVisibles(Map<String, dynamic> data) {
    if (widget.selectedYear < DateTime.now().year) {
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

  String _formatoMonto(double monto) {
    if (monto == 0) return '-';
    if (monto < 0) {
      return '(\$ ${widget.currencyFormatter.format(monto.abs()).replaceAll('\$', '')})';
    }
    return widget.currencyFormatter.format(monto);
  }

  Widget _buildCell(
    String text, {
    required double width,
    bool isHeader = false,
    Alignment alignment = Alignment.center,
    Color? color,
    Color? textColor,
    bool isBold = false,
    bool isLast = false,
    bool isFirst = false,
  }) {
    return Container(
      width: width,
      height: 45, // Aumentado para mejor legibilidad
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: color,
        border: Border(
          bottom: BorderSide(
            color: isHeader ? Colors.transparent : Colors.grey.shade200,
            width: 1.0,
          ),
          right: isLast
              ? BorderSide.none
              : BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      alignment: alignment,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Text(
          text,
          style: TextStyle(
            fontWeight: (isHeader || isBold)
                ? FontWeight.bold
                : FontWeight.w500,
            fontSize: 13,
            color:
                textColor ??
                (isHeader ? Colors.white : Colors.blueGrey.shade800),
            letterSpacing: isHeader ? 0.5 : 0,
          ),
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildCabeceraPrincipal(
    Map<String, dynamic> data,
    double cuentaWidth,
  ) {
    int mesesVisibles = _getMesesVisibles(data);
    List<int> mesesARenderizar = _selectedMonths.isNotEmpty
        ? (_selectedMonths.toList()..sort())
        : List.generate(mesesVisibles, (index) => index + 1);

    const headerColor = Color(0xFF1E293B); // Dark slate
    return Container(
      decoration: const BoxDecoration(
        color: headerColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          _buildCell('CÓDIGO', width: 70, isHeader: true, isFirst: true),
          _buildCell(
            'CUENTA',
            width: cuentaWidth,
            isHeader: true,
            alignment: Alignment.centerLeft,
          ),
          ...mesesARenderizar.map(
            (mesIndex) =>
                _buildCell(_meses[mesIndex - 1].toUpperCase(), width: 110, isHeader: true),
          ),
          _buildCell('TOTAL ANUAL', width: 120, isHeader: true, isLast: true),
        ],
      ),
    );
  }

  List<Widget> _buildModulo(
    Map<String, dynamic> data,
    String moduloNombre,
    double cuentaWidth,
  ) {
    if (!data.containsKey(moduloNombre)) {
      return [];
    }

    if (_selectedModulo != null && moduloNombre.toUpperCase() != _selectedModulo) {
      return [];
    }

    final moduloData = data[moduloNombre];
    final cuentas = moduloData['cuentas'] as List;
    final subtotales = moduloData['subtotales'] as Map<String, dynamic>;
    final totalAnualModulo =
        double.tryParse(moduloData['total_anual_modulo'].toString()) ?? 0;

    List<Widget> filas = [];
    int mesesVisibles = _getMesesVisibles(data);
    List<int> mesesARenderizar = _selectedMonths.isNotEmpty
        ? (_selectedMonths.toList()..sort())
        : List.generate(mesesVisibles, (index) => index + 1);

    // Definir colores pastel según el módulo
    Color bgColor;
    Color textColor;
    if (moduloNombre.toUpperCase() == 'VENTAS') {
      bgColor = const Color(0xFFE8F5E9); // Verde muy suave
      textColor = const Color(0xFF2E7D32); // Verde oscuro
    } else if (moduloNombre.toUpperCase() == 'COSTOS') {
      bgColor = const Color(0xFFFFF3E0); // Naranja muy suave
      textColor = const Color(0xFFE65100); // Naranja oscuro
    } else if (moduloNombre.toUpperCase() == 'GASTOS') {
      bgColor = const Color(0xFFFFEBEE); // Rojo muy suave
      textColor = const Color(0xFFC62828); // Rojo oscuro
    } else {
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue.shade800;
    }

    // Fila del módulo (Cabecera Pastel)
    filas.add(
      Container(
        color: bgColor,
        child: Row(
          children: [
            _buildCell(
              '',
              width: 70,
              isBold: true,
              textColor: textColor,
              color: bgColor,
              isFirst: true,
            ),
            _buildCell(
              moduloNombre.toUpperCase(),
              width: cuentaWidth,
              alignment: Alignment.centerLeft,
              isBold: true,
              textColor: textColor,
              color: bgColor,
            ),
            ...mesesARenderizar.map(
              (mes) => _buildCell(
                '',
                width: 110,
                textColor: textColor,
                color: bgColor,
              ),
            ),
            _buildCell(
              '',
              width: 120,
              textColor: textColor,
              color: bgColor,
              isLast: true,
            ),
          ],
        ),
      ),
    );

    // Calcular máximo del módulo para el Heatmap
    double maxMontoModulo = 0;
    for (var cuenta in cuentas) {
      var montosMeses = cuenta['meses'] as Map<String, dynamic>;
      montosMeses.forEach((k, v) {
        double monto = double.tryParse(v.toString()) ?? 0;
        if (monto.abs() > maxMontoModulo) {
          maxMontoModulo = monto.abs();
        }
      });
    }

    // Filas de las cuentas
    for (int i = 0; i < cuentas.length; i++) {
      var cuenta = cuentas[i];
      var montosMeses = cuenta['meses'] as Map<String, dynamic>;

      filas.add(
        Material(
          color: Colors.transparent,
          child: InkWell(
            onHover: (hovering) {}, // Para el efecto visual
            onTap: () {}, // Puede abrir detalle de cuenta a futuro
            hoverColor: Colors.grey.shade50,
            child: Row(
              children: [
                _buildCell(
                  cuenta['codigo'].toString(),
                  width: 70,
                  isFirst: true,
                  alignment: Alignment.center,
                ),
                _buildCell(
                  cuenta['descripcion'].toString(),
                  width: cuentaWidth,
                  alignment: Alignment.centerLeft,
                ),
                ...mesesARenderizar.map((mes) {
                  double monto =
                      double.tryParse(
                        montosMeses[mes.toString()]?.toString() ?? '0',
                      ) ??
                      0;

                  Color? cellBgColor;
                  Color? cellTextColor;

                  if (monto.abs() > 0 && maxMontoModulo > 0) {
                    double intensity = monto.abs() / maxMontoModulo;
                    // Escala de color: Ventas = Verde, Costos/Gastos = Rojo
                    if (moduloNombre.toUpperCase() == 'VENTAS') {
                      cellBgColor = Colors.green.withOpacity(
                        intensity * 0.85,
                      ); // Hasta 85% opacidad
                    } else {
                      cellBgColor = Colors.red.withOpacity(intensity * 0.85);
                    }

                    // Contraste de texto para colores fuertes
                    if (intensity > 0.5) {
                      cellTextColor = Colors.white;
                    } else if (intensity > 0.2) {
                      cellTextColor = Colors.black87;
                    }
                  }

                  return _buildCell(
                    _formatoMonto(monto),
                    width: 110,
                    alignment: Alignment.centerRight,
                    color: cellBgColor,
                    textColor: cellTextColor,
                  );
                }),
                _buildCell(
                  _formatoMonto(
                    double.tryParse(cuenta['total_anual'].toString()) ?? 0,
                  ),
                  width: 120,
                  alignment: Alignment.centerRight,
                  isBold: true,
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Fila de SUBTOTAL
    filas.add(
      Container(
        color: const Color(0xFFF8FAFC), // Slate 50
        child: Row(
          children: [
            _buildCell('', width: 70, isBold: true, isFirst: true),
            _buildCell(
              'Subtotal $moduloNombre',
              width: 350,
              alignment: Alignment.centerLeft,
              isBold: true,
              textColor: textColor,
            ),
            ...mesesARenderizar.map((mes) {
              double monto =
                  double.tryParse(
                    subtotales[mes.toString()]?.toString() ?? '0',
                  ) ??
                  0;
              return _buildCell(
                _formatoMonto(monto),
                width: 110,
                alignment: Alignment.centerRight,
                isBold: true,
                textColor: textColor,
              );
            }),
            _buildCell(
              _formatoMonto(totalAnualModulo),
              width: 120,
              alignment: Alignment.centerRight,
              isBold: true,
              textColor: textColor,
              isLast: true,
            ),
          ],
        ),
      ),
    );

    return filas;
  }

  void _showMesesFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Seleccionar Meses'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(12, (index) {
                    final mesIndex = index + 1;
                    final isSelected = _selectedMonths.contains(mesIndex);
                    return CheckboxListTile(
                      title: Text(_meses[index]),
                      value: isSelected,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            _selectedMonths.add(mesIndex);
                          } else {
                            _selectedMonths.remove(mesIndex);
                          }
                        });
                        setState(() {});
                      },
                    );
                  }),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() => _selectedMonths.clear());
                    setState(() {});
                  },
                  child: const Text('Limpiar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Moderno
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Reporte Detallado por Cuentas",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Vista analítica de ingresos y egresos del año",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const LedhouseDetallesCuentas(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.analytics_outlined, size: 18),
                      label: const Text("Ver Detalles"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blueGrey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _downloadMatrizPdf,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text("Descargar PDF"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE31E24), // Rojo
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0).copyWith(bottom: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Filtrar por módulo'),
                        value: _selectedModulo,
                        icon: const Icon(Icons.category_outlined, color: Colors.grey, size: 20),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Todos los módulos')),
                          DropdownMenuItem(value: 'VENTAS', child: Text('Ventas')),
                          DropdownMenuItem(value: 'COSTOS', child: Text('Costos')),
                          DropdownMenuItem(value: 'GASTOS', child: Text('Gastos')),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedModulo = val);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextButton.icon(
                      onPressed: _showMesesFilterDialog,
                      icon: const Icon(Icons.calendar_month, color: Colors.grey, size: 20),
                      label: Text(
                        _selectedMonths.isEmpty 
                            ? 'Todos los meses' 
                            : '${_selectedMonths.length} meses seleccionados',
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.normal),
                      ),
                      style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // Tabla con scroll
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                int mesesVisibles = _getMesesVisibles(widget.matrizData);
                int numMesesARenderizar = _selectedMonths.isNotEmpty ? _selectedMonths.length : mesesVisibles;
                // Width of CODIGO(70) + MESES(110*numMesesARenderizar) + TOTAL(120) = 190 + (110*numMesesARenderizar)
                double fixedWidths = 70 + (110 * numMesesARenderizar) + 120.0;
                // Subtract 40 for padding inside SingleChildScrollView and 2 for border width
                double availableCuentaWidth =
                    constraints.maxWidth - 42 - fixedWidths;
                double cuentaWidth = availableCuentaWidth > 350
                    ? availableCuentaWidth
                    : 350.0;

                return Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    scrollDirection: Axis.vertical,
                    child: Scrollbar(
                      controller: _horizontalController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _horizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCabeceraPrincipal(
                                  widget.matrizData,
                                  cuentaWidth,
                                ),
                                ..._buildModulo(
                                  widget.matrizData,
                                  'VENTAS',
                                  cuentaWidth,
                                ),
                                ..._buildModulo(
                                  widget.matrizData,
                                  'COSTOS',
                                  cuentaWidth,
                                ),
                                ..._buildModulo(
                                  widget.matrizData,
                                  'GASTOS',
                                  cuentaWidth,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
