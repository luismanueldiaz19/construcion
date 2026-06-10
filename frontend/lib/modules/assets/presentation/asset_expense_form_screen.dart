import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/assets_provider.dart';
import '../models/asset_expense.dart';
import '../models/asset.dart';

class AssetExpenseFormScreen extends StatefulWidget {
  final Asset asset;

  const AssetExpenseFormScreen({Key? key, required this.asset}) : super(key: key);

  @override
  State<AssetExpenseFormScreen> createState() => _AssetExpenseFormScreenState();
}

class _AssetExpenseFormScreenState extends State<AssetExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mileageController = TextEditingController();
  final _gallonsController = TextEditingController();
  
  String _selectedType = 'Combustible';
  DateTime? _expenseDate;

  bool _isSaving = false;

  final List<String> _expenseTypes = [
    'Combustible',
    'Mantenimiento',
    'Reparación',
    'Gasto de Gomas',
    'Repuesto',
    'Otro'
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _expenseDate) {
      setState(() {
        _expenseDate = picked;
      });
    }
  }

  void _saveExpense() async {
    if (_formKey.currentState!.validate() && _expenseDate != null) {
      setState(() {
        _isSaving = true;
      });

      final newExpense = AssetExpense(
        id: 0,
        assetId: widget.asset.id,
        expenseType: _selectedType,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        date: _expenseDate!.toIso8601String().split('T')[0],
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        mileage: int.tryParse(_mileageController.text),
        gallons: double.tryParse(_gallonsController.text),
      );

      try {
        await Provider.of<AssetsProvider>(context, listen: false).registerExpense(newExpense);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gasto registrado exitosamente')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    } else if (_expenseDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona la fecha del gasto'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _mileageController.dispose();
    _gallonsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1A1C1E);
    final accentColor = const Color(0xFFE31E24);
    
    // Check if the current category looks like a vehicle
    final isVehicle = widget.asset.category?.name.toLowerCase().contains('vehicul') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar Gasto: ${widget.asset.name}'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detalles del Gasto',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Gasto',
                      border: OutlineInputBorder(),
                    ),
                    items: _expenseTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedType = val!;
                      });
                    },
                    validator: (value) => value == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'Costo Total (\$)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Fecha del Gasto',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              _expenseDate == null
                                  ? 'Seleccionar fecha'
                                  : "${_expenseDate!.year}-${_expenseDate!.month.toString().padLeft(2, '0')}-${_expenseDate!.day.toString().padLeft(2, '0')}",
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descripción / Motivo (ej. Tapada de goma)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  
                  // Only show mileage/gallons if it might be a vehicle or if user chose Combustible
                  if (isVehicle || _selectedType == 'Combustible') ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Datos Adicionales del Vehículo',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _mileageController,
                            decoration: const InputDecoration(
                              labelText: 'Kilometraje Actual',
                              border: OutlineInputBorder(),
                              suffixText: 'km',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        if (_selectedType == 'Combustible') ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _gallonsController,
                              decoration: const InputDecoration(
                                labelText: 'Cantidad de Combustible',
                                border: OutlineInputBorder(),
                                suffixText: 'galones/litros',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isSaving ? null : _saveExpense,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Guardar Gasto', style: TextStyle(fontSize: 16)),
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
