import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_theme.dart';
import '../../../../widgets/app_button.dart';
import '../providers/suppliers_provider.dart';

/// Modal ultra-compacto y moderno para filtrar proveedores.
/// Aplica estrictamente las directrices de [flutter-small-widgets].
class SupplierFilterSheet extends StatefulWidget {
  const SupplierFilterSheet({super.key});

  static void show(BuildContext context) {
    final provider = context.read<SuppliersProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: ChangeNotifierProvider.value(
              value: provider,
              child: const SupplierFilterSheet(),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const SupplierFilterSheet(),
        ),
      );
    }
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
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera compacta
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppTheme.accentColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Filtros de Proveedores',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                tooltip: 'Cerrar',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),

          // Selector: Tipo de Proveedor
          DropdownButtonFormField<String>(
            initialValue: _selectedType,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: _dropdownDecoration('Tipo de Proveedor', Icons.apartment_rounded),
            items: const [
              DropdownMenuItem(value: 'Todos', child: Text('Todos los tipos')),
              DropdownMenuItem(value: 'persona_fisica', child: Text('Persona Física')),
              DropdownMenuItem(value: 'empresa', child: Text('Empresa')),
              DropdownMenuItem(value: 'gobierno', child: Text('Gobierno')),
              DropdownMenuItem(value: 'institucion', child: Text('Institución')),
            ],
            onChanged: (val) => setState(() => _selectedType = val!),
          ),
          const SizedBox(height: 8),

          // Selector: Clasificación
          DropdownButtonFormField<String>(
            initialValue: _selectedClassification,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: _dropdownDecoration('Clasificación', Icons.star_outline_rounded),
            items: const [
              DropdownMenuItem(value: 'Todos', child: Text('Todas las clasificaciones')),
              DropdownMenuItem(value: 'excelente', child: Text('Excelente')),
              DropdownMenuItem(value: 'bueno', child: Text('Bueno')),
              DropdownMenuItem(value: 'regular', child: Text('Regular')),
              DropdownMenuItem(value: 'riesgoso', child: Text('Riesgoso')),
            ],
            onChanged: (val) => setState(() => _selectedClassification = val!),
          ),
          const SizedBox(height: 8),

          // Selector: Estado de Actividad
          DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: _dropdownDecoration('Estado de Actividad', Icons.toggle_on_outlined),
            items: const [
              DropdownMenuItem(value: 'Todos', child: Text('Todos los estados')),
              DropdownMenuItem(value: 'Activos', child: Text('Solo Activos')),
              DropdownMenuItem(value: 'Inactivos', child: Text('Solo Inactivos')),
            ],
            onChanged: (val) => setState(() => _selectedStatus = val!),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),

          // Botones inferiores compactos
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                text: 'Limpiar',
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.compact,
                onPressed: _clear,
              ),
              const SizedBox(width: 8),
              AppButton(
                text: 'Aplicar Filtros',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.compact,
                onPressed: _apply,
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label, IconData icon) {
    return InputDecoration(
      isDense: true,
      labelText: label,
      labelStyle: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
      prefixIcon: Icon(icon, size: 16, color: const Color(0xFF64748B)),
      prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.accentColor, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }
}
