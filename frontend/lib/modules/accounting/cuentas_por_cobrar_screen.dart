import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../services/api_service.dart';

class CuentasPorCobrarScreen extends StatefulWidget {
  const CuentasPorCobrarScreen({super.key});

  @override
  State<CuentasPorCobrarScreen> createState() => _CuentasPorCobrarScreenState();
}

class _CuentasPorCobrarScreenState extends State<CuentasPorCobrarScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _cuentas = [];
  bool _isLoading = true;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getCuentasPorCobrar();
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
    if (_filter.isEmpty) return _cuentas;
    return _cuentas.where((c) {
      final proyecto = c['proyecto'].toString().toLowerCase();
      final cliente = c['cliente'].toString().toLowerCase();
      return proyecto.contains(_filter.toLowerCase()) ||
          cliente.contains(_filter.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        title: const Text('Cuentas por Cobrar (CXC)'),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCards(f),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por proyecto o cliente...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCuentas.isEmpty
                ? const Center(
                    child: Text('No hay cuentas por cobrar pendientes'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredCuentas.length,
                    itemBuilder: (context, index) {
                      final cuenta = _filteredCuentas[index];
                      return _buildCuentaCard(cuenta, f);
                    },
                  ),
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
            'Total por Cobrar',
            f.format(totalPendiente),
            Colors.green[700]!,
            Icons.account_balance_wallet,
          ),
          const SizedBox(width: 16),
          _buildSummaryItem(
            'Proyectos con Saldo',
            _cuentas
                .where((c) => (double.tryParse(c['saldo'].toString()) ?? 0) > 0)
                .length
                .toString(),
            Colors.blue[700]!,
            Icons.business,
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
    final double saldo = double.tryParse(cuenta['saldo'].toString()) ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    cuenta['proyecto'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: saldo <= 0 ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cuenta['estado'],
                    style: TextStyle(
                      color: saldo <= 0
                          ? Colors.green[700]
                          : Colors.orange[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Cliente: ${cuenta['cliente']}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMontoCol(
                  'Total Contrato',
                  f.format(
                    double.tryParse(cuenta['monto_total'].toString()) ?? 0,
                  ),
                  Colors.black87,
                ),
                _buildMontoCol(
                  'Pagado',
                  f.format(
                    double.tryParse(cuenta['monto_pagado'].toString()) ?? 0,
                  ),
                  Colors.green[700]!,
                ),
                _buildMontoCol(
                  'Pendiente',
                  f.format(double.tryParse(cuenta['saldo'].toString()) ?? 0),
                  Colors.red[700]!,
                ),
              ],
            ),
            if (saldo > 0) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showPagoDialog(cuenta),
                  icon: const Icon(Icons.add_card),
                  label: const Text('REGISTRAR PAGO CLIENTE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMontoCol(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showPagoDialog(dynamic cuenta) async {
    final TextEditingController montoController = TextEditingController(
      text: cuenta['saldo'].toString(),
    );
    final TextEditingController conceptoController = TextEditingController();
    DateTime fechaPago = DateTime.now();
    String metodoPago = 'Transferencia';
    int? selectedBancoId;
    List<dynamic> bancos = [];
    bool isSubmitting = false;

    // Precarga de bancos
    try {
      bancos = await _apiService.getBancos();
      if (bancos.isNotEmpty) {
        final primerBanco = bancos.firstWhere(
          (b) => b['nombre'].toString().toLowerCase().contains('banco'),
          orElse: () => bancos[0],
        );
        selectedBancoId = primerBanco['id'];
      }
    } catch (e) {
      print('Error al cargar bancos: $e');
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // Evita cerrar accidentalmente mientras envía
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cabecera elegante
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF003366),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.add_card,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Registrar Cobro',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                cuenta['proyecto'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Información de Saldo
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Saldo Pendiente:',
                                style: TextStyle(color: Colors.blueGrey),
                              ),
                              Text(
                                NumberFormat.currency(symbol: '\$').format(
                                  double.tryParse(cuenta['saldo'].toString()) ??
                                      0,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Campo de Monto
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
                          decoration: InputDecoration(
                            labelText: 'Monto a Recibir',
                            prefixIcon: const Icon(Icons.attach_money),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Método de Pago y Banco
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: DropdownButtonFormField<String>(
                                value: metodoPago,
                                isExpanded:
                                    true, // Asegura que el contenido use el espacio disponible
                                decoration: InputDecoration(
                                  labelText: 'Método',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: ['Transferencia', 'Cheque']
                                    .map(
                                      (m) => DropdownMenuItem(
                                        value: m,
                                        child: Text(
                                          m,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: isSubmitting
                                    ? null
                                    : (v) =>
                                          setModalState(() => metodoPago = v!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 6,
                              child: DropdownButtonFormField<int>(
                                value: selectedBancoId,
                                isExpanded:
                                    true, // Evita desbordamiento interno
                                decoration: InputDecoration(
                                  labelText: 'Cuenta Destino',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: bancos
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
                                onChanged: isSubmitting
                                    ? null
                                    : (v) => setModalState(
                                        () => selectedBancoId = v,
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Fecha de Pago
                        InkWell(
                          onTap: isSubmitting
                              ? null
                              : () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: fechaPago,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null)
                                    setModalState(() => fechaPago = picked);
                                },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Fecha de Recibo',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(fechaPago),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Comentario
                        TextField(
                          controller: conceptoController,
                          decoration: InputDecoration(
                            labelText: 'Referencia / Nota',
                            prefixIcon: const Icon(Icons.note_alt_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Botones de Acción
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final monto =
                                        double.tryParse(montoController.text) ??
                                        0;
                                    final saldo =
                                        double.tryParse(
                                          cuenta['saldo'].toString(),
                                        ) ??
                                        0;

                                    if (monto <= 0 || selectedBancoId == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Por favor complete los campos correctamente',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    if (monto > (saldo + 0.01)) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'El monto no puede exceder el saldo (\$${saldo.toStringAsFixed(2)})',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    setModalState(() => isSubmitting = true);
                                    try {
                                      await _apiService.createPago({
                                        'proyecto_id': cuenta['id'],
                                        'monto': monto,
                                        'fecha': DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(fechaPago),
                                        'metodo_pago': metodoPago,
                                        'banco_id': selectedBancoId,
                                        'comentario': conceptoController.text,
                                      });
                                      if (mounted) {
                                        Navigator.pop(context);
                                        _loadData();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              '✅ Pago registrado correctamente',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setModalState(() => isSubmitting = false);
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'CONFIRMAR Y REGISTRAR COBRO',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
