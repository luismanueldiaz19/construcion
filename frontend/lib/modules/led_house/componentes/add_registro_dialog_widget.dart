import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/auth_provider.dart';
import '../providers/ledhouse_provider.dart';
import '../providers/cuenta_catalogo_provider.dart';
import '../models/ledhouse_estado_resultado_model.dart';
import '../models/cuenta_catalogo_model.dart';

class AddRegistroDialogWidget extends StatefulWidget {
  final LedhouseEstadoResultado? registro;
  const AddRegistroDialogWidget({super.key, this.registro});

  @override
  State<AddRegistroDialogWidget> createState() =>
      _AddRegistroDialogWidgetState();
}

class _AddRegistroDialogWidgetState extends State<AddRegistroDialogWidget> {
  final _formKey = GlobalKey<FormState>();

  final _montoController = TextEditingController();

  String? _codigoSeleccionado;
  String? _selectedMonth;

  bool _isSaving = false;
  bool _isNegative = false;

  final List<String> meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cp = Provider.of<CuentaCatalogoProvider>(context, listen: false);
      if (cp.cuentas.isEmpty) {
        cp.fetchCuentas();
      }
    });

    if (widget.registro != null) {
      _codigoSeleccionado = widget.registro!.codigoCuenta;
      _montoController.text = widget.registro!.monto.abs().toString();
      _isNegative = widget.registro!.monto < 0;
      try {
        DateTime d = DateTime.parse(widget.registro!.fecha);
        _selectedMonth = meses[d.month - 1];
      } catch (e) {
        _selectedMonth = meses[DateTime.now().month - 1];
      }
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_codigoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, selecciona una cuenta del catálogo válida.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona un mes.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final provider = Provider.of<LedhouseProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String currentUsername = authProvider.username ?? 'Admin';

    int monthIndex = meses.indexOf(_selectedMonth!) + 1;
    int year = DateTime.now().year;
    if (widget.registro != null) {
      try {
        year = DateTime.parse(widget.registro!.fecha).year;
      } catch (e) {}
    }
    DateTime lastDay = DateTime(year, monthIndex + 1, 0);
    String fechaStr = DateFormat('yyyy-MM-dd').format(lastDay);

    final data = {
      'codigo_cuenta': _codigoSeleccionado,
      'monto':
          double.parse(_montoController.text.trim()) * (_isNegative ? -1 : 1),
      'fecha': fechaStr,
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
                      const Icon(
                        Icons.add_chart,
                        color: Color(0xFFE31E24),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.registro != null
                            ? 'Editar Registro'
                            : 'Añadir Nuevo Registro',
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
                      Consumer<CuentaCatalogoProvider>(
                        builder: (context, cp, child) {
                          if (cp.isLoading && cp.cuentas.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          return Autocomplete<CuentaCatalogo>(
                            initialValue: widget.registro != null
                                ? TextEditingValue(
                                    text:
                                        '${widget.registro!.codigoCuenta} - ${widget.registro!.descripcionDeCuenta}',
                                  )
                                : TextEditingValue.empty,
                            displayStringForOption: (option) =>
                                '${option.codigo} - ${option.descripcion}',
                            optionsBuilder:
                                (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return cp.cuentas;
                                  }
                                  return cp.cuentas.where((
                                    CuentaCatalogo option,
                                  ) {
                                    return option.codigo.toUpperCase().contains(
                                          textEditingValue.text.toUpperCase(),
                                        ) ||
                                        option.descripcion
                                            .toUpperCase()
                                            .contains(
                                              textEditingValue.text
                                                  .toUpperCase(),
                                            );
                                  });
                                },
                            onSelected: (CuentaCatalogo selection) {
                              setState(() {
                                _codigoSeleccionado = selection.codigo;
                              });
                            },
                            fieldViewBuilder:
                                (
                                  context,
                                  controller,
                                  focusNode,
                                  onEditingComplete,
                                ) {
                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: _inputDecoration(
                                      'Buscar Cuenta (Código o Descripción) *',
                                      Icons.search,
                                    ),
                                    validator: (val) {
                                      if (val == null || val.isEmpty)
                                        return 'Requerido';
                                      return null;
                                    },
                                    onChanged: (val) {
                                      if (_codigoSeleccionado != null) {
                                        _codigoSeleccionado = null;
                                      }
                                    },
                                  );
                                },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            child: DropdownButtonFormField<String>(
                              value: _selectedMonth,
                              hint: const Text('Mes'),
                              items: meses
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(m),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedMonth = val;
                                });
                              },
                              decoration: _inputDecoration(
                                'Mes *',
                                Icons.calendar_today,
                              ),
                              validator: (val) =>
                                  val == null ? 'Requerido' : null,
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
                              widget.registro != null
                                  ? 'Actualizar'
                                  : 'Guardar',
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
