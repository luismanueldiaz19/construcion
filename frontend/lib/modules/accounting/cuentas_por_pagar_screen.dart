import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';
import '../../services/accounting_service.dart';
import '../../core/constants.dart';

class CuentasPorPagarScreen extends StatefulWidget {
  const CuentasPorPagarScreen({super.key});

  @override
  State<CuentasPorPagarScreen> createState() => _CuentasPorPagarScreenState();
}

class _CuentasPorPagarScreenState extends State<CuentasPorPagarScreen> {
  final AccountingService _accountingService = AccountingService();
  List<dynamic> _cuentas = [];
  List<dynamic> _bancos = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _filter = '';

  // Advanced filters
  String? _filterProveedor;
  double? _filterMinMonto;
  double? _filterMaxMonto;
  bool _filterSoloVencidas = false;
  String _sortBy =
      'fecha_vencimiento'; // 'fecha_vencimiento', 'monto_total', 'saldo'
  bool _sortAscending = true;

  dynamic _selectedCuenta;
  int? _selectedBancoId;
  DateTime _fechaPago = DateTime.now();
  final _montoController = TextEditingController();
  final _refController = TextEditingController();
  double _porcentajePago = 100.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _refController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _accountingService.getCuentasPorPagar();
      final bancosData = await _accountingService.getBancos();
      if (!mounted) return;
      setState(() {
        _cuentas = data;
        _bancos = bancosData;

        // Sincronizar cuenta seleccionada si existe
        if (_selectedCuenta != null) {
          final updated = _cuentas.firstWhere(
            (c) => c['id'] == _selectedCuenta['id'],
            orElse: () => null,
          );
          if (updated != null) {
            _selectedCuenta = updated;
            _montoController.text = updated['saldo'].toString();
          } else {
            _selectedCuenta = null;
          }
        }

        // Banco predeterminado
        if (_selectedBancoId == null && _bancos.isNotEmpty) {
          final primerBanco = _bancos.firstWhere(
            (b) => b['nombre'].toString().toLowerCase().contains('banco'),
            orElse: () => _bancos[0],
          );
          _selectedBancoId = primerBanco['id'];
        }

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  List<dynamic> get _filteredCuentas {
    Iterable<dynamic> filtered = _cuentas;

    // 1. Texto de búsqueda (Proveedor o Factura)
    if (_filter.isNotEmpty) {
      filtered = filtered.where((c) {
        final proveedor =
            c['proveedor']?['nombre']?.toString().toLowerCase() ?? '';
        final factura = c['compra']?['id']?.toString() ?? '';
        return proveedor.contains(_filter.toLowerCase()) ||
            factura.contains(_filter);
      });
    }

    // 2. Filtro por Proveedor específico
    if (_filterProveedor != null && _filterProveedor!.isNotEmpty) {
      filtered = filtered.where(
        (c) => c['proveedor']?['nombre'] == _filterProveedor,
      );
    }

    // 3. Filtro por Monto
    if (_filterMinMonto != null) {
      filtered = filtered.where(
        (c) =>
            (double.tryParse(c['saldo'].toString()) ?? 0) >= _filterMinMonto!,
      );
    }
    if (_filterMaxMonto != null) {
      filtered = filtered.where(
        (c) =>
            (double.tryParse(c['saldo'].toString()) ?? 0) <= _filterMaxMonto!,
      );
    }

    // 4. Filtro Solo Vencidas
    if (_filterSoloVencidas) {
      filtered = filtered.where((c) {
        final fechaVenc = c['fecha_vencimiento'];
        if (fechaVenc == null) return false;
        return DateTime.parse(fechaVenc).isBefore(DateTime.now()) &&
            c['estado'] != 'Pagado';
      });
    }

    // 5. Ordenamiento
    List<dynamic> list = filtered.toList();
    list.sort((a, b) {
      dynamic valA = a[_sortBy];
      dynamic valB = b[_sortBy];

      if (_sortBy == 'fecha_vencimiento') {
        valA = valA != null ? DateTime.parse(valA) : DateTime(2100);
        valB = valB != null ? DateTime.parse(valB) : DateTime(2100);
      } else {
        valA = double.tryParse(valA.toString()) ?? 0;
        valB = double.tryParse(valB.toString()) ?? 0;
      }

      return _sortAscending ? valA.compareTo(valB) : valB.compareTo(valA);
    });

    return list;
  }

  Future<void> _submitPago(bool isBottomSheet) async {
    final monto = double.tryParse(_montoController.text) ?? 0;
    final saldo = double.tryParse(_selectedCuenta['saldo'].toString()) ?? 0;

    if (monto <= 0 || _selectedBancoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete los campos correctamente'),
        ),
      );
      return;
    }

    if (monto > (saldo + 0.01)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El monto no puede exceder el saldo (\$${saldo.toStringAsFixed(2)})',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _accountingService.registrarPagoCompra({
        'cuenta_por_pagar_id': _selectedCuenta['id'],
        'monto': monto,
        'fecha': DateFormat('yyyy-MM-dd').format(_fechaPago),
        'metodo_pago': 'Transferencia',
        'referencia': _refController.text,
        'banco_id': _selectedBancoId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pago registrado con éxito'),
            backgroundColor: Colors.green,
          ),
        );

        if (isBottomSheet) {
          Navigator.pop(context);
        } else {
          setState(() {
            _selectedCuenta = null;
          });
        }
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _openPaymentBottomSheet(dynamic cuenta) {
    setState(() {
      _selectedCuenta = cuenta;
      _porcentajePago = 100.0;
      _montoController.text = cuenta['saldo'].toString();
      _refController.text = '';
      _fechaPago = DateTime.now();
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: _buildPaymentFormPanel(isBottomSheet: true),
          ),
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _selectedCuenta = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: '\$');
    final width = MediaQuery.of(context).size.width;
    final isLargeScreen = width > 950;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        title: const Text('Cuentas por Pagar (CXP)'),
        actions: [
          IconButton(
            onPressed: _showFiltersBottomSheet,
            icon: Icon(
              Icons.filter_list,
              color:
                  (_filterProveedor != null ||
                      _filterMinMonto != null ||
                      _filterMaxMonto != null ||
                      _filterSoloVencidas)
                  ? Colors.orange
                  : null,
            ),
          ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar Datos',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isLargeScreen
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildSummaryCards(f),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Buscar por proveedor o factura...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (v) => setState(() => _filter = v),
                        ),
                      ),
                      Expanded(
                        child: _filteredCuentas.isEmpty
                            ? const Center(
                                child: Text(
                                  'No hay cuentas por pagar pendientes',
                                ),
                              )
                            : _buildCardView(f, isLargeScreen),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 16.0,
                    right: 16.0,
                    bottom: 16.0,
                  ),
                  child: SizedBox(
                    width: 460,
                    child: _selectedCuenta != null
                        ? _buildPaymentFormPanel(isBottomSheet: false)
                        : _buildPlaceholderPanel(),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _buildSummaryCards(f),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por proveedor o factura...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (v) => setState(() => _filter = v),
                  ),
                ),
                Expanded(
                  child: _filteredCuentas.isEmpty
                      ? const Center(
                          child: Text('No hay cuentas por pagar pendientes'),
                        )
                      : _buildCardView(f, isLargeScreen),
                ),
              ],
            ),
    );
  }

  Widget _buildCardView(NumberFormat f, bool isLargeScreen) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredCuentas.length,
      itemBuilder: (context, index) {
        final cuenta = _filteredCuentas[index];
        return _buildCuentaCard(cuenta, f, isLargeScreen);
      },
    );
  }

  Widget _buildTableView(NumberFormat f, bool isLargeScreen) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                showCheckboxColumn: false,
                headingRowColor: WidgetStateProperty.all(Colors.blueGrey[50]),
                columns: const [
                  DataColumn(
                    label: Text(
                      'Factura #',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Proveedor',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Vencimiento',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Estado',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Monto Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Saldo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: _filteredCuentas.map((cuenta) {
                  final saldo =
                      double.tryParse(cuenta['saldo'].toString()) ?? 0;
                  final montoTotal =
                      double.tryParse(cuenta['monto_total'].toString()) ?? 0;
                  final fechaVenc = cuenta['fecha_vencimiento'];
                  final isVencida =
                      fechaVenc != null &&
                      DateTime.parse(fechaVenc).isBefore(DateTime.now()) &&
                      cuenta['estado'] != 'Pagado';

                  final bool isSelected =
                      _selectedCuenta != null &&
                      _selectedCuenta['id'] == cuenta['id'];

                  return DataRow(
                    selected: isSelected,
                    onSelectChanged: (selected) {
                      if (selected != null && selected) {
                        if (isLargeScreen) {
                          setState(() {
                            _selectedCuenta = cuenta;
                            _porcentajePago = 100.0;
                            _montoController.text = cuenta['saldo'].toString();
                            _refController.text = '';
                            _fechaPago = DateTime.now();
                          });
                        } else {
                          _openPaymentBottomSheet(cuenta);
                        }
                      }
                    },
                    cells: [
                      DataCell(Text('#${cuenta['compra_id']}')),
                      DataCell(Text(cuenta['proveedor']?['nombre'] ?? 'N/A')),
                      DataCell(
                        Text(
                          fechaVenc ?? 'N/A',
                          style: TextStyle(
                            color: isVencida ? Colors.red : Colors.black,
                          ),
                        ),
                      ),
                      DataCell(_buildStatusBadge(cuenta['estado'], isVencida)),
                      DataCell(Text(f.format(montoTotal))),
                      DataCell(
                        Text(
                          f.format(saldo),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(NumberFormat f) {
    double totalPendiente = _cuentas.fold(
      0,
      (sum, item) => sum + (double.tryParse(item['saldo'].toString()) ?? 0),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildSummaryItem(
            'Total Pendiente (CXP)',
            f.format(totalPendiente),
            Colors.red[700]!,
            Icons.account_balance_wallet,
          ),
          const SizedBox(width: 16),
          _buildSummaryItem(
            'Facturas Activas',
            _cuentas.where((c) => c['estado'] != 'Pagado').length.toString(),
            Colors.blue[700]!,
            Icons.receipt_long,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCuentaCard(dynamic cuenta, NumberFormat f, bool isLargeScreen) {
    final saldo = double.tryParse(cuenta['saldo'].toString()) ?? 0;
    final montoTotal = double.tryParse(cuenta['monto_total'].toString()) ?? 0;
    final fechaVenc = cuenta['fecha_vencimiento'];
    final isVencida =
        fechaVenc != null &&
        DateTime.parse(fechaVenc).isBefore(DateTime.now()) &&
        cuenta['estado'] != 'Pagado';

    final bool isSelected =
        _selectedCuenta != null && _selectedCuenta['id'] == cuenta['id'];

    Color cardColor = isSelected
        ? AppTheme.primaryColor.withValues(alpha: 0.02)
        : Colors.white;

    return Card(
      color: cardColor,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.accentColor : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (isLargeScreen) {
            setState(() {
              _selectedCuenta = cuenta;
              _porcentajePago = 100.0;
              _montoController.text = cuenta['saldo'].toString();
              _refController.text = '';
              _fechaPago = DateTime.now();
            });
          } else {
            _openPaymentBottomSheet(cuenta);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            ListTile(
              title: Text(
                cuenta['proveedor']?['nombre'] ?? 'Proveedor Desconocido',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Factura #${cuenta['compra_id']} - Vence: ${fechaVenc ?? 'N/A'}',
              ),
              trailing: _buildStatusBadge(cuenta['estado'], isVencida),
            ),
            const Divider(height: 0),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Factura',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        f.format(montoTotal),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Saldo Pendiente',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        f.format(saldo),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isVencida ? Colors.red : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPdf(int pagoId) async {
    final url = Uri.parse('$host/api/v1/pagos-compras/$pagoId/pdf');
    try {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el PDF')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al abrir PDF: $e')));
    }
  }

  Widget _buildStatusBadge(String status, bool isVencida) {
    Color color = Colors.grey;
    String text = status;

    if (isVencida) {
      color = Colors.red;
      text = 'VENCIDA';
    } else if (status == 'Pendiente') {
      color = Colors.orange;
    } else if (status == 'Parcial') {
      color = Colors.blue;
    } else if (status == 'Pagado') {
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPaymentFormPanel({required bool isBottomSheet}) {
    final double saldo =
        double.tryParse(_selectedCuenta['saldo'].toString()) ?? 0;
    final List<dynamic> pagos = _selectedCuenta['pagos'] as List? ?? [];
    final f = NumberFormat.currency(symbol: '\$');

    Widget formContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información de Saldo
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo Pendiente:',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                f.format(saldo),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Slider de porcentaje de pago
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Porcentaje a Pagar:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '${_porcentajePago.round()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primaryColor,
                      inactiveTrackColor: Colors.grey[200],
                      thumbColor: AppTheme.accentColor,
                      overlayColor: AppTheme.accentColor.withValues(
                        alpha: 0.12,
                      ),
                      valueIndicatorColor: AppTheme.primaryColor,
                      valueIndicatorTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Slider(
                      value: _porcentajePago,
                      min: 0.0,
                      max: 100.0,
                      divisions: 100,
                      label: '${_porcentajePago.round()}%',
                      onChanged: (val) {
                        setState(() {
                          _porcentajePago = val;
                          final nuevoMonto = saldo * (val / 100.0);
                          _montoController.text = nuevoMonto.toStringAsFixed(2);
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            // Botones rápidos (Chips)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [25, 50, 75, 100].map((pct) {
                final bool isSelected = _porcentajePago.round() == pct;
                return ChoiceChip(
                  label: Text('$pct%'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _porcentajePago = pct.toDouble();
                        final nuevoMonto = saldo * (pct / 100.0);
                        _montoController.text = nuevoMonto.toStringAsFixed(2);
                      });
                    }
                  },
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.bold,
                    fontSize: 12,
                  ),
                  backgroundColor: Colors.grey[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey[200]!,
                    ),
                  ),
                  showCheckmark: false,
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Campo de Monto
        TextField(
          controller: _montoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          onChanged: (val) {
            final double typedMonto = double.tryParse(val) ?? 0;
            if (saldo > 0) {
              setState(() {
                _porcentajePago = ((typedMonto / saldo) * 100.0).clamp(
                  0.0,
                  100.0,
                );
              });
            }
          },
          decoration: InputDecoration(
            labelText: 'Monto a Pagar',
            prefixIcon: const Icon(Icons.attach_money),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),

        // Cuenta Destino / Banco Origen
        DropdownButtonFormField<int>(
          value: _selectedBancoId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Banco / Origen de Fondos',
            prefixIcon: const Icon(Icons.account_balance),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: _bancos
              .map(
                (b) => DropdownMenuItem<int>(
                  value: b['id'],
                  child: Text(
                    b['nombre'],
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: _isSubmitting
              ? null
              : (v) => setState(() => _selectedBancoId = v),
        ),
        const SizedBox(height: 16),

        // Referencia / Cheque
        TextField(
          controller: _refController,
          decoration: InputDecoration(
            labelText: 'Referencia / No. Cheque',
            prefixIcon: const Icon(Icons.confirmation_number_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Fecha de Pago
        InkWell(
          onTap: _isSubmitting
              ? null
              : () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _fechaPago,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _fechaPago = picked);
                  }
                },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fecha de Pago',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(_fechaPago),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Botón de Confirmar Pago
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : () => _submitPago(isBottomSheet),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'CONFIRMAR Y REGISTRAR PAGO',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
        ),

        // Historial de Pagos
        const Divider(height: 40),
        Row(
          children: [
            const Icon(Icons.history, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Historial de Pagos (${pagos.length})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (pagos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No se han registrado pagos para esta factura.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          Column(
            children: pagos.map<Widget>((pago) {
              final pMonto = double.tryParse(pago['monto'].toString()) ?? 0;
              final pFecha =
                  DateTime.tryParse(pago['fecha'].toString()) ?? DateTime.now();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_upward,
                        size: 16,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pago['metodo_pago'] ?? 'Pago',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Fecha: ${DateFormat('dd/MM/yyyy').format(pFecha)} ${pago['referencia'] != null && pago['referencia'].toString().isNotEmpty ? "- Ref: ${pago['referencia']}" : ""}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '-${f.format(pMonto)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.picture_as_pdf_outlined,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          onPressed: () => _openPdf(pago['id']),
                          tooltip: 'Descargar Recibo',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );

    final headerSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.add_card, color: AppTheme.accentColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Registrar Pago / Abono',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Factura #${_selectedCuenta['compra_id']} - ${_selectedCuenta['proveedor']?['nombre']}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isBottomSheet)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            else
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedCuenta = null),
                tooltip: 'Deseleccionar',
              ),
          ],
        ),
        const Divider(height: 24),
      ],
    );

    if (isBottomSheet) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [headerSection, formContent],
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            headerSection,
            Expanded(child: SingleChildScrollView(child: formContent)),
          ],
        ),
      );
    }
  }

  Widget _buildPlaceholderPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Selección de Factura',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona una factura de la izquierda para ver su detalle, registrar un pago o ver su historial de pagos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final uniqueProveedores = _cuentas
              .map((c) => c['proveedor']?['nombre'])
              .where((n) => n != null)
              .toSet()
              .toList();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filtros Avanzados',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _filterProveedor = null;
                          _filterMinMonto = null;
                          _filterMaxMonto = null;
                          _filterSoloVencidas = false;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Limpiar'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text(
                  'Proveedor',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  isExpanded: true,
                  value: _filterProveedor,
                  hint: const Text('Todos los proveedores'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    ...uniqueProveedores.map(
                      (p) => DropdownMenuItem(
                        value: p.toString(),
                        child: Text(p.toString()),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    setModalState(() => _filterProveedor = v);
                    setState(() => _filterProveedor = v);
                  },
                ),
                const SizedBox(height: 16),

                const Text(
                  'Rango de Saldo Pendiente',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Min \$'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        onChanged: (v) {
                          final val = double.tryParse(v);
                          setState(() => _filterMinMonto = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Max \$'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        onChanged: (v) {
                          final val = double.tryParse(v);
                          setState(() => _filterMaxMonto = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                CheckboxListTile(
                  title: const Text('Solo Facturas Vencidas'),
                  value: _filterSoloVencidas,
                  onChanged: (v) {
                    setModalState(() => _filterSoloVencidas = v!);
                    setState(() => _filterSoloVencidas = v!);
                  },
                ),

                const SizedBox(height: 16),
                const Text(
                  'Ordenar por',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Fecha Venc.'),
                      selected: _sortBy == 'fecha_vencimiento',
                      onSelected: (v) =>
                          setState(() => _sortBy = 'fecha_vencimiento'),
                    ),
                    ChoiceChip(
                      label: const Text('Monto'),
                      selected: _sortBy == 'monto_total',
                      onSelected: (v) =>
                          setState(() => _sortBy = 'monto_total'),
                    ),
                    ChoiceChip(
                      label: const Text('Saldo'),
                      selected: _sortBy == 'saldo',
                      onSelected: (v) => setState(() => _sortBy == 'saldo'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('APLICAR FILTROS'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
