import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/auth_provider.dart';
import '../providers/ledhouse_provider.dart';
import '../models/ledhouse_estado_resultado_model.dart';

class AddRegistroDialogWidget extends StatefulWidget {
  final LedhouseEstadoResultado? registro;
  const AddRegistroDialogWidget({super.key, this.registro});

  @override
  State<AddRegistroDialogWidget> createState() =>
      _AddRegistroDialogWidgetState();
}

class _AddRegistroDialogWidgetState extends State<AddRegistroDialogWidget> {
  final _formKey = GlobalKey<FormState>();

  final _codigoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _montoController = TextEditingController();

  String _selectedModulo = 'VENTAS';
  DateTime _selectedDate = DateTime.now();

  bool _isSaving = false;
  bool _isNegative = false;

  @override
  void initState() {
    super.initState();
    if (widget.registro != null) {
      _codigoController.text = widget.registro!.codigoCuenta;
      _descripcionController.text = widget.registro!.descripcionDeCuenta;
      _montoController.text = widget.registro!.monto.abs().toString();
      _isNegative = widget.registro!.monto < 0;
      _selectedModulo = widget.registro!.modulo;
      try {
        _selectedDate = DateTime.parse(widget.registro!.fecha);
      } catch (e) {
        _selectedDate = DateTime.now();
      }
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = Provider.of<LedhouseProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String currentUsername = authProvider.username ?? 'Admin';

    final data = {
      'codigo_cuenta': _codigoController.text.toUpperCase().trim(),
      'modulo': _selectedModulo.toUpperCase().trim(),
      'descripcion_de_cuenta': _descripcionController.text.toUpperCase().trim(),
      'monto': double.parse(_montoController.text.trim()) * (_isNegative ? -1 : 1),
      'fecha': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'registed_by': currentUsername,
    };

    bool success = false;
    if (widget.registro != null) {
      success = await provider.updateRegistro(widget.registro!.id, data);
    } else {
      success = await provider.createRegistro(data);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro guardado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE31E24), width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.add_chart, color: Color(0xFFE31E24), size: 28),
                      const SizedBox(width: 12),
                      Text(
                        widget.registro != null ? 'Editar Registro' : 'Añadir Nuevo Registro',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0C336B),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 32),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INFORMACIÓN GENERAL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _codigoController,
                              decoration: _inputDecoration(
                                'Código Cuenta *',
                                Icons.tag,
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Requerido'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _selectedModulo,
                              decoration: _inputDecoration(
                                'Módulo *',
                                Icons.category_outlined,
                              ),
                              items: ['VENTAS', 'COSTOS', 'GASTOS'].map((m) {
                                return DropdownMenuItem(
                                  value: m,
                                  child: Text(m),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedModulo = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descripcionController,
                        decoration: _inputDecoration(
                          'Descripción *',
                          Icons.description_outlined,
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _montoController,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+(\.\d{0,2})?$'),
                                ),
                              ],
                              decoration: _inputDecoration(
                                'Monto *',
                                Icons.attach_money,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Requerido';
                                }
                                if (double.tryParse(val) == null) {
                                  return 'Monto inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: Color(
                                            0xFFE31E24,
                                          ), // color principal
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (date != null) {
                                  setState(() => _selectedDate = date);
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: IgnorePointer(
                                child: TextFormField(
                                  key: ValueKey(_selectedDate),
                                  initialValue: DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(_selectedDate),
                                  decoration: _inputDecoration(
                                    'Fecha',
                                    Icons.calendar_today_outlined,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: _isNegative,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _isNegative = val);
                              }
                            },
                            activeColor: const Color(0xFFE31E24),
                          ),
                          const Text(
                            'Es un monto negativo (resta)',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'CANCELAR',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C336B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              widget.registro != null ? 'Actualizar' : 'Guardar',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
    );
  }
}
