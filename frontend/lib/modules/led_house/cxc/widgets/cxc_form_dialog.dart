import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_theme.dart';
import '../models/cxc_model.dart';
import '../providers/cxc_provider.dart';
import '../../providers/ledhouse_cliente_provider.dart';

class CxcFormDialog extends StatefulWidget {
  final CxcModel? cxc;
  final int? preselectedClienteId;

  const CxcFormDialog({super.key, this.cxc, this.preselectedClienteId});

  @override
  State<CxcFormDialog> createState() => _CxcFormDialogState();
}

class _CxcFormDialogState extends State<CxcFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _documentoController = TextEditingController();
  int? _selectedClienteId;
  final _montoFacturaController = TextEditingController();
  final _montoPagadoController = TextEditingController();

  DateTime? _fechaFactura;
  DateTime _fechaVencimiento = DateTime.now();
  String _estado = 'pendiente';
  bool _isSaving = false;

  bool get _isEditing => widget.cxc != null;

  @override
  void initState() {
    super.initState();
    if (widget.cxc != null) {
      _documentoController.text = widget.cxc!.documento;
      _selectedClienteId = widget.cxc!.clienteId;
      _montoFacturaController.text = widget.cxc!.montoFactura.toString();
      _montoPagadoController.text = widget.cxc!.montoPagado.toString();
      _estado = widget.cxc!.estado;
      try {
        _fechaVencimiento = DateTime.parse(widget.cxc!.fechaVencimiento);
      } catch (_) {}
      try {
        if (widget.cxc!.fechaFactura != null) {
          _fechaFactura = DateTime.parse(widget.cxc!.fechaFactura!);
        }
      } catch (_) {}
    } else if (widget.preselectedClienteId != null) {
      _selectedClienteId = widget.preselectedClienteId;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LedhouseClienteProvider>(
        context,
        listen: false,
      ).fetchClientes();
    });
  }

  @override
  void dispose() {
    _documentoController.dispose();
    _montoFacturaController.dispose();
    _montoPagadoController.dispose();
    super.dispose();
  }

  void _calculateFechaVencimiento() {
    if (_fechaFactura == null || _selectedClienteId == null) return;
    
    final provider = Provider.of<LedhouseClienteProvider>(context, listen: false);
    final index = provider.clientes.indexWhere((c) => c.id == _selectedClienteId);
    
    if (index != -1) {
      final cliente = provider.clientes[index];
      final dias = cliente.diasCredito ?? 0;
      if (dias > 0) {
        setState(() {
          _fechaVencimiento = _fechaFactura!.add(Duration(days: dias));
        });
      }
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Expanded(child: Text('Debe seleccionar un cliente')),
            ],
          ),
          backgroundColor: AppTheme.dangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = Provider.of<CxcProvider>(context, listen: false);

    final data = {
      'documento': _documentoController.text.trim(),
      'cliente_id': _selectedClienteId,
      'monto_factura': double.parse(_montoFacturaController.text.trim()),
      'monto_pagado': _montoPagadoController.text.isEmpty
          ? 0
          : double.parse(_montoPagadoController.text.trim()),
      if (_fechaFactura != null)
        'fecha_factura': DateFormat('yyyy-MM-dd').format(_fechaFactura!),
      'fecha_vencimiento': DateFormat('yyyy-MM-dd').format(_fechaVencimiento),
      'estado': _estado,
    };

    bool success;
    if (widget.cxc == null) {
      success = await provider.createCxc(data);
    } else {
      success = await provider.updateCxc(widget.cxc!.id!, data);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Error: ${provider.error}')),
            ],
          ),
          backgroundColor: AppTheme.dangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ───────────────────────────────────────────
              _buildDialogHeader(),

              // ── Form ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _documentoController,
                              label: 'Documento',
                              hint: 'Ej: FAC-001',
                              icon: Icons.receipt_long_rounded,
                              iconColor: AppTheme.successColor,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Requerido'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Estado',
                              value: _estado,
                              icon: Icons.flag_rounded,
                              iconColor: AppTheme.successColor,
                              items: ['pendiente', 'pagado', 'cancelado'],
                              onChanged: (v) {
                                if (v != null) setState(() => _estado = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Consumer<LedhouseClienteProvider>(
                        builder: (context, provider, child) {
                          if (provider.isLoading && provider.clientes.isEmpty) {
                            return const SizedBox(
                              height: 56,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cliente',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownMenu<int>(
                                enabled: widget.preselectedClienteId == null && !_isEditing,
                                initialSelection: _selectedClienteId,
                                expandedInsets: EdgeInsets.zero,
                                inputDecorationTheme: InputDecorationTheme(
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: AppTheme.successColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                leadingIcon: Container(
                                  margin: const EdgeInsets.all(10),
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppTheme.successColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.person_rounded, color: AppTheme.successColor, size: 18),
                                ),
                                enableFilter: true,
                                enableSearch: true,
                                menuHeight: 300,
                                hintText: 'Seleccione un cliente',
                                textStyle: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
                                dropdownMenuEntries: provider.clientes.map((c) {
                                  return DropdownMenuEntry<int>(
                                    value: c.id ?? 0,
                                    label: c.nombre,
                                  );
                                }).toList(),
                                onSelected: (val) {
                                  setState(() => _selectedClienteId = val);
                                  _calculateFechaVencimiento();
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _montoFacturaController,
                              label: 'Monto Factura',
                              hint: '0.00',
                              icon: Icons.attach_money_rounded,
                              iconColor: AppTheme.successColor,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+(\.\d{0,2})?$')),
                              ],
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Requerido'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              controller: _montoPagadoController,
                              label: 'Monto Pagado',
                              hint: '0.00',
                              icon: Icons.money_off_rounded,
                              iconColor: Colors.grey.shade600,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+(\.\d{0,2})?$')),
                              ],
                              optional: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fecha Factura',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _fechaFactura ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: AppTheme.successColor,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (date != null) {
                                setState(() => _fechaFactura = date);
                                _calculateFechaVencimiento();
                              }
                            },
                            child: IgnorePointer(
                              child: TextFormField(
                                key: ValueKey(_fechaFactura),
                                initialValue: _fechaFactura != null 
                                  ? DateFormat('dd/MM/yyyy').format(_fechaFactura!)
                                  : '',
                                style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
                                decoration: InputDecoration(
                                  hintText: 'Seleccione...',
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(10),
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppTheme.successColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.event_available_rounded, color: AppTheme.successColor, size: 18),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: AppTheme.successColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fecha Vencimiento',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 8),
                          IgnorePointer(
                            child: TextFormField(
                              key: ValueKey(_fechaVencimiento),
                              initialValue: DateFormat('dd/MM/yyyy').format(_fechaVencimiento),
                              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
                              decoration: InputDecoration(
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(10),
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.calendar_today_rounded, color: Colors.grey.shade600, size: 18),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF3F4F6),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 28),

                      // ── Buttons ─────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                side: BorderSide(color: Colors.grey.shade300),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.successColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      _isEditing
                                          ? 'Guardar cambios'
                                          : 'Crear cuenta',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.successColor, Colors.teal.shade700],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Editar Cuenta' : 'Nueva Cuenta',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isEditing
                      ? 'Actualiza los datos de cobro'
                      : 'Completa los datos de cobro',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context, false),
            icon: Icon(
              Icons.close_rounded,
              color: Colors.white.withOpacity(0.7),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    Color iconColor = AppTheme.successColor,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool optional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Opcional',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppTheme.successColor,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFEA4335),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFEA4335),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppTheme.successColor,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items: items.map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(e.toUpperCase(), style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
