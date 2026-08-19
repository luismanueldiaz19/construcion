import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/cxp_model.dart';
import '../providers/cxp_provider.dart';

class CxpFormDialog extends StatefulWidget {
  final CxpModel? cxp;

  const CxpFormDialog({super.key, this.cxp});

  @override
  State<CxpFormDialog> createState() => _CxpFormDialogState();
}

class _CxpFormDialogState extends State<CxpFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _documentoController = TextEditingController();
  final _proveedorController = TextEditingController();
  final _montoFacturaController = TextEditingController();
  final _montoPagadoController = TextEditingController();
  
  DateTime _fechaVencimiento = DateTime.now();
  String _estado = 'pendiente';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.cxp != null) {
      _documentoController.text = widget.cxp!.documento;
      _proveedorController.text = widget.cxp!.proveedor;
      _montoFacturaController.text = widget.cxp!.montoFactura.toString();
      _montoPagadoController.text = widget.cxp!.montoPagado.toString();
      _estado = widget.cxp!.estado;
      try {
        _fechaVencimiento = DateTime.parse(widget.cxp!.fechaVencimiento);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _documentoController.dispose();
    _proveedorController.dispose();
    _montoFacturaController.dispose();
    _montoPagadoController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    final provider = Provider.of<CxpProvider>(context, listen: false);

    final data = {
      'documento': _documentoController.text.trim(),
      'proveedor': _proveedorController.text.trim(),
      'monto_factura': double.parse(_montoFacturaController.text.trim()),
      'monto_pagado': _montoPagadoController.text.isEmpty ? 0 : double.parse(_montoPagadoController.text.trim()),
      'fecha_vencimiento': DateFormat('yyyy-MM-dd').format(_fechaVencimiento),
      'estado': _estado,
    };

    bool success;
    if (widget.cxp == null) {
      success = await provider.createCxp(data);
    } else {
      success = await provider.updateCxp(widget.cxp!.id!, data);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Guardado exitosamente'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${provider.error}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.cxp == null ? 'Nueva Cuenta por Pagar' : 'Editar Cuenta por Pagar',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _documentoController,
                      decoration: _inputDecoration('Documento', Icons.receipt),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _estado,
                      decoration: _inputDecoration('Estado', Icons.flag),
                      items: ['pendiente', 'pagado', 'cancelado'].map((e) {
                        return DropdownMenuItem(value: e, child: Text(e.toUpperCase()));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _estado = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _proveedorController,
                decoration: _inputDecoration('Proveedor', Icons.store),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _montoFacturaController,
                      decoration: _inputDecoration('Monto Factura', Icons.attach_money),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+(\.\d{0,2})?$'))],
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _montoPagadoController,
                      decoration: _inputDecoration('Monto Pagado', Icons.money_off),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+(\.\d{0,2})?$'))],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _fechaVencimiento,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => _fechaVencimiento = date);
                },
                child: IgnorePointer(
                  child: TextFormField(
                    key: ValueKey(_fechaVencimiento),
                    initialValue: DateFormat('dd/MM/yyyy').format(_fechaVencimiento),
                    decoration: _inputDecoration('Fecha Vencimiento', Icons.calendar_today),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Guardar', style: TextStyle(color: Colors.white)),
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
