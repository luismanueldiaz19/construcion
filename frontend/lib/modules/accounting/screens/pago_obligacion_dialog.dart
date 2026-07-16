import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/accounting_service.dart';

class PagoObligacionDialog extends StatefulWidget {
  final int cuentaId;
  final String nombre;
  final double saldo;

  const PagoObligacionDialog({
    super.key,
    required this.cuentaId,
    required this.nombre,
    required this.saldo,
  });

  @override
  State<PagoObligacionDialog> createState() => _PagoObligacionDialogState();
}

class _PagoObligacionDialogState extends State<PagoObligacionDialog> {
  final AccountingService _service = AccountingService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  List<dynamic> _bancos = [];
  int? _bancoId;
  DateTime _fechaPago = DateTime.now();
  
  final _montoPrincipalCtrl = TextEditingController();
  final _montoRecargosCtrl = TextEditingController(text: '0');
  final _referenciaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _montoPrincipalCtrl.text = widget.saldo.toString();
    _loadBancos();
  }

  Future<void> _loadBancos() async {
    try {
      final res = await _service.getBancos();
      setState(() => _bancos = res);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _procesarPago() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bancoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una cuenta de banco para pagar')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _service.pagarObligacion({
        'cuenta_id': widget.cuentaId,
        'banco_id': _bancoId,
        'monto_principal': double.parse(_montoPrincipalCtrl.text),
        'monto_recargos': double.tryParse(_montoRecargosCtrl.text) ?? 0,
        'fecha': DateFormat('yyyy-MM-dd').format(_fechaPago),
        'referencia': _referenciaCtrl.text,
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');

    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 450,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1C1E), // AppTheme.primaryColor
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pagar ${widget.nombre}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // Body
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Resumen de Deuda
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE31E24).withOpacity(0.05), // AppTheme.accentColor light
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE31E24).withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'SALDO ADEUDADO',
                            style: TextStyle(
                              color: Color(0xFFE31E24),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'RD\$ ${fmt.format(widget.saldo)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1C1E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Formularios
                    TextFormField(
                      controller: _montoPrincipalCtrl,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Monto a Pagar (Principal)',
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _montoRecargosCtrl,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Monto de Recargos o Mora (Opcional)',
                        prefixIcon: const Icon(Icons.money_off),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Cuenta de Origen (Banco)',
                        prefixIcon: const Icon(Icons.account_balance),
                      ),
                      items: _bancos.map((b) {
                        return DropdownMenuItem<int>(
                          value: b['id'],
                          child: Text(
                            '${b['nombre']} (RD\$ ${fmt.format(b['balance'] ?? 0)})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _bancoId = v),
                      validator: (v) => v == null ? 'Seleccione un banco' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _referenciaCtrl,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Referencia de Pago (Cheque/Transf.)',
                        prefixIcon: const Icon(Icons.receipt_long),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _fechaPago,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setState(() => _fechaPago = d);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.grey),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Fecha de Pago', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                                Text(DateFormat('dd/MM/yyyy').format(_fechaPago), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      foregroundColor: Colors.grey.shade700,
                    ),
                    child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _procesarPago,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24), // AppTheme.accentColor
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text('Registrar Pago', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
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
}
