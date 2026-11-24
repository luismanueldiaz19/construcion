import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_theme.dart';
import '../../../../models/proveedor.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_screen_wrapper.dart';
import '../../../../widgets/app_text_field.dart';
import '../providers/suppliers_provider.dart';
import '../widgets/supplier_metrics_cards.dart';
import '../widgets/supplier_filter_sheet.dart';
import '../widgets/supplier_table.dart';
import '../widgets/supplier_form.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SuppliersProvider(),
      child: const _SuppliersScreenContent(),
    );
  }
}

class _SuppliersScreenContent extends StatefulWidget {
  const _SuppliersScreenContent();

  @override
  State<_SuppliersScreenContent> createState() =>
      _SuppliersScreenContentState();
}

class _SuppliersScreenContentState extends State<_SuppliersScreenContent> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SuppliersProvider>();
      provider.addListener(_onProviderChanged);
    });
  }

  void _onProviderChanged() {
    if (!mounted) return;
    final provider = context.read<SuppliersProvider>();
    if (_searchController.text != provider.searchQuery) {
      _searchController.text = provider.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _handleOpenForm(BuildContext context, {Proveedor? proveedorToEdit}) {
    final provider = context.read<SuppliersProvider>();
    if (proveedorToEdit != null) {
      provider.selectProveedorForEdit(proveedorToEdit);
    } else {
      provider.startAddingProveedor();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 600),
            child: ChangeNotifierProvider.value(
              value: context.read<SuppliersProvider>(),
              child: SupplierForm(
                onClose: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterBar(BuildContext context, SuppliersProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Buscador libre y botón de filtrar unidos en la misma fila
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _searchController,
                hintText: 'Buscar por nombre, código o RNC...',
                prefixIconData: Icons.search_rounded,
                borderRadius: 8,
                onChanged: (val) => provider.setSearchQuery(val),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          size: 16,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            AppButton(
              text: 'Filtrar',
              icon: Icons.tune_rounded,
              variant: provider.isFilterActive
                  ? AppButtonVariant.primary
                  : AppButtonVariant.outlined,
              size: AppButtonSize.compact,
              onPressed: () => SupplierFilterSheet.show(context),
            ),
          ],
        ),

        // Chips informativos de filtros activos
        if (provider.isFilterActive) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                'Filtros Activos:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10.5,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Wrap(
                  spacing: 5.0,
                  runSpacing: 3.0,
                  children: [
                    if (provider.selectedType != 'Todos')
                      Chip(
                        label: Text(
                          'Tipo: ${provider.selectedType}',
                          style: const TextStyle(fontSize: 9.5),
                        ),
                        onDeleted: () => provider.setFilters(type: 'Todos'),
                        backgroundColor: Colors.blue.shade50,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    if (provider.selectedClassification != 'Todos')
                      Chip(
                        label: Text(
                          'Clasificación: ${provider.selectedClassification}',
                          style: const TextStyle(fontSize: 9.5),
                        ),
                        onDeleted: () =>
                            provider.setFilters(classification: 'Todos'),
                        backgroundColor: Colors.blue.shade50,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    if (provider.selectedStatus != 'Todos')
                      Chip(
                        label: Text(
                          'Estado: ${provider.selectedStatus}',
                          style: const TextStyle(fontSize: 9.5),
                        ),
                        onDeleted: () => provider.setFilters(status: 'Todos'),
                        backgroundColor: Colors.blue.shade50,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: provider.clearFilters,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 22),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: const Text(
                  'Limpiar todo',
                  style: TextStyle(color: Colors.red, fontSize: 10.5),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildContent(SuppliersProvider provider) {
    return Scrollbar(
      controller: _verticalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _verticalScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SupplierMetricsCards(),
            const SizedBox(height: 6),
            SupplierTable(
              selectedProveedor: provider.editingProveedor,
              onEdit: (prov) => _handleOpenForm(context, proveedorToEdit: prov),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SuppliersProvider>();
    final int count = provider.filteredProveedores.length;

    return AppScreenWrapper(
      title: 'Directorio de Proveedores',
      subtitle: '$count proveedores encontrados',
      actions: [
        // Botón Nuevo Proveedor con AppButton
        AppButton(
          text: 'Nuevo Proveedor',
          icon: Icons.person_add_rounded,
          variant: AppButtonVariant.primary,
          size: AppButtonSize.compact,
          onPressed: () => _handleOpenForm(context),
        ),
      ],
      filterBar: _buildFilterBar(context, provider),
      // Modo 1: Pantalla ancha (Desktop) con scroll vertical fluido y tabla full-width
      desktopView: _buildContent(provider),
      // Modo 2: Pantalla móvil con el mismo comportamiento adaptativo
      mobileView: _buildContent(provider),
    );
  }
}
