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

    return AlertDialog(
      title: Text('Pagar ${widget.nombre}'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Saldo Adeudado: RD\$ ${fmt.format(widget.saldo)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _montoPrincipalCtrl,
                decoration: const InputDecoration(labelText: 'Monto a Pagar (Principal)', prefixText: 'RD\$ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _montoRecargosCtrl,
                decoration: const InputDecoration(labelText: 'Monto de Recargos o Mora (Opcional)', prefixText: 'RD\$ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Cuenta de Origen (Banco)'),
                items: _bancos.map((b) {
                  return DropdownMenuItem<int>(
                    value: b['id'],
                    child: Text('${b['nombre']} (RD\$ ${fmt.format(b['balance'] ?? 0)})'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _bancoId = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _referenciaCtrl,
                decoration: const InputDecoration(labelText: 'Referencia de Pago (Cheque/Transf.)'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de Pago'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_fechaPago)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _fechaPago,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setState(() => _fechaPago = d);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _procesarPago,
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Registrar Pago'),
        ),
      ],
    );
  }
}
