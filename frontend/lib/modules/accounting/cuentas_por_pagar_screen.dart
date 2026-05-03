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
  bool _isLoading = true;
  String _filter = '';

  // Advanced filters
  String? _filterProveedor;
  double? _filterMinMonto;
  double? _filterMaxMonto;
  bool _filterSoloVencidas = false;
  String _sortBy =
      'fecha_vencimiento'; // 'fecha_vencimiento', 'monto_total', 'saldo'
  final bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _accountingService.getCuentasPorPagar();
      setState(() {
        _cuentas = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: '\$');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.grid_view), text: 'Tarjetas'),
              Tab(icon: Icon(Icons.table_chart), text: 'Tabla'),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildSummaryCards(f),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar por proveedor o factura...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (v) => setState(() => _filter = v),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredCuentas.isEmpty
                  ? const Center(
                      child: Text('No hay cuentas por pagar pendientes'),
                    )
                  : TabBarView(
                      children: [_buildCardView(f), _buildTableView(f)],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardView(NumberFormat f) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredCuentas.length,
      itemBuilder: (context, index) {
        final cuenta = _filteredCuentas[index];
        return _buildCuentaCard(cuenta, f);
      },
    );
  }

  Widget _buildTableView(NumberFormat f) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.blueGrey[50]),
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
            DataColumn(
              label: Text(
                'Acciones',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: _filteredCuentas.map((cuenta) {
            final saldo = double.tryParse(cuenta['saldo'].toString()) ?? 0;
            final montoTotal =
                double.tryParse(cuenta['monto_total'].toString()) ?? 0;
            final fechaVenc = cuenta['fecha_vencimiento'];
            final isVencida =
                fechaVenc != null &&
                DateTime.parse(fechaVenc).isBefore(DateTime.now()) &&
                cuenta['estado'] != 'Pagado';

            return DataRow(
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
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (saldo > 0)
                        IconButton(
                          icon: const Icon(Icons.payment, color: Colors.blue),
                          onPressed: () => _showPagoDialog(cuenta),
                          tooltip: 'Pagar',
                        ),
                      if (cuenta['pagos'] != null &&
                          (cuenta['pagos'] as List).isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.history,
                            color: Colors.blueGrey,
                          ),
                          onPressed: () => _showHistorialDialog(cuenta, f),
                          tooltip: 'Ver Historial',
                        ),
                      if (saldo <= 0)
                        const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showHistorialDialog(dynamic cuenta, NumberFormat f) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Historial de Pagos - Fac. #${cuenta['compra_id']}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: (cuenta['pagos'] as List).length,
            itemBuilder: (context, index) {
              final pago = cuenta['pagos'][index];
              return ListTile(
                title: Text(
                  'Pago #${pago['id']} - ${f.format(double.tryParse(pago['monto'].toString()) ?? 0)}',
                ),
                subtitle: Text(
                  'Fecha: ${pago['fecha']} - ${pago['metodo_pago']}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  onPressed: () => _openPdf(pago['id']),
                ),
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

  Widget _buildSummaryCards(NumberFormat f) {
    double totalPendiente = _cuentas.fold(
      0,
      (sum, item) => sum + (double.tryParse(item['saldo'].toString()) ?? 0),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blueGrey[50],
      child: Row(
        children: [
          _buildSummaryItem(
            'Total Pendiente',
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
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
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

  Widget _buildCuentaCard(dynamic cuenta, NumberFormat f) {
    final saldo = double.tryParse(cuenta['saldo'].toString()) ?? 0;
    final montoTotal = double.tryParse(cuenta['monto_total'].toString()) ?? 0;
    final fechaVenc = cuenta['fecha_vencimiento'];
    final isVencida =
        fechaVenc != null &&
        DateTime.parse(fechaVenc).isBefore(DateTime.now()) &&
        cuenta['estado'] != 'Pagado';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          if (saldo > 0)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showPagoDialog(cuenta),
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text('REGISTRAR PAGO / ABONO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          if (cuenta['pagos'] != null && (cuenta['pagos'] as List).isNotEmpty)
            ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              title: const Text(
                'Historial de Pagos',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              children: (cuenta['pagos'] as List).map((pago) {
                return ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  title: Text('Pago #${pago['id']} - ${pago['metodo_pago']}'),
                  subtitle: Text(
                    'Fecha: ${pago['fecha']} ${pago['referencia'] != null ? "- Ref: ${pago['referencia']}" : ""}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        f.format(
                          double.tryParse(pago['monto'].toString()) ?? 0,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _openPdf(pago['id']),
                        tooltip: 'Descargar Recibo',
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _openPdf(int pagoId) async {
    final url = Uri.parse('$host/api/v1/pagos-compras/$pagoId/pdf');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el PDF')),
        );
      }
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
        color: color.withOpacity(0.1),
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

  void _showPagoDialog(dynamic cuenta) async {
    final TextEditingController montoController = TextEditingController(
      text: cuenta['saldo'].toString(),
    );
    final TextEditingController refController = TextEditingController();
    DateTime fechaPago = DateTime.now();
    int? selectedBancoId;
    List<dynamic> bancos = [];
    bool isSubmitting = false;

    try {
      bancos = await _accountingService.getBancos();
    } catch (e) {
      print('Error al cargar bancos: $e');
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Registrar Pago'),
              Text(
                'Proveedor: ${cuenta['proveedor']?['nombre']}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: montoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Monto a Pagar',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedBancoId,
                  decoration: const InputDecoration(
                    labelText: 'Banco / Origen de Fondos',
                    border: OutlineInputBorder(),
                  ),
                  items: bancos
                      .map(
                        (b) => DropdownMenuItem<int>(
                          value: b['id'],
                          child: Text(b['nombre']),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedBancoId = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: refController,
                  decoration: const InputDecoration(
                    labelText: 'Referencia / No. Cheque',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: fechaPago,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setDialogState(() => fechaPago = d);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha de Pago',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd/MM/yyyy').format(fechaPago)),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
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
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (selectedBancoId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Seleccione un banco')),
                        );
                        return;
                      }
                      setDialogState(() => isSubmitting = true);
                      try {
                        await _accountingService.registrarPagoCompra({
                          'cuenta_por_pagar_id': cuenta['id'],
                          'monto': double.parse(montoController.text),
                          'fecha': DateFormat('yyyy-MM-dd').format(fechaPago),
                          'metodo_pago': 'Transferencia',
                          'referencia': refController.text,
                          'banco_id': selectedBancoId,
                        });
                        if (mounted) {
                          Navigator.pop(context);
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pago registrado con éxito'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                foregroundColor: Colors.white,
              ),
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('GUARDAR PAGO'),
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
                      onSelected: (v) => setState(() => _sortBy = 'saldo'),
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
