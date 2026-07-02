import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_theme.dart';
import '../providers/suppliers_provider.dart';

class SupplierFilterSheet extends StatefulWidget {
  const SupplierFilterSheet({super.key});

  static void show(BuildContext context) {
    final provider = context.read<SuppliersProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const SupplierFilterSheet(),
      ),
    );
  }

  @override
  State<SupplierFilterSheet> createState() => _SupplierFilterSheetState();
}

class _SupplierFilterSheetState extends State<SupplierFilterSheet> {
  late String _selectedType;
  late String _selectedClassification;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    final provider = context.read<SuppliersProvider>();
    _selectedType = provider.selectedType;
    _selectedClassification = provider.selectedClassification;
    _selectedStatus = provider.selectedStatus;
  }

  void _apply() {
    final provider = context.read<SuppliersProvider>();
    provider.setFilters(
      type: _selectedType,
      classification: _selectedClassification,
      status: _selectedStatus,
    );
    Navigator.pop(context);
  }

  void _clear() {
    setState(() {
      _selectedType = 'Todos';
      _selectedClassification = 'Todos';
      _selectedStatus = 'Todos';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtros de Proveedores',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: InputDecoration(
              labelText: 'Tipo de Proveedor',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'Todos', child: Text('Todos los tipos')),
              DropdownMenuItem(value: 'persona_fisica', child: Text('Persona Física')),
              DropdownMenuItem(value: 'empresa', child: Text('Empresa')),
              DropdownMenuItem(value: 'gobierno', child: Text('Gobierno')),
              DropdownMenuItem(value: 'institucion', child: Text('Institución')),
            ],
            onChanged: (val) => setState(() => _selectedType = val!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedClassification,
            decoration: InputDecoration(
              labelText: 'Clasificación',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'Todos', child: Text('Todas las clasificaciones')),
              DropdownMenuItem(value: 'excelente', child: Text('Excelente')),
              DropdownMenuItem(value: 'bueno', child: Text('Bueno')),
              DropdownMenuItem(value: 'regular', child: Text('Regular')),
              DropdownMenuItem(value: 'riesgoso', child: Text('Riesgoso')),
            ],
            onChanged: (val) => setState(() => _selectedClassification = val!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'Estado de Actividad',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'Todos', child: Text('Todos los estados')),
              DropdownMenuItem(value: 'Activos', child: Text('Solo Activos')),
              DropdownMenuItem(value: 'Inactivos', child: Text('Solo Inactivos')),
            ],
            onChanged: (val) => setState(() => _selectedStatus = val!),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clear,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('LIMPIAR'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('APLICAR'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
