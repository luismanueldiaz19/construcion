import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_theme.dart';
import '../providers/suppliers_provider.dart';
import '../widgets/supplier_metrics_cards.dart';
import '../widgets/supplier_filter_sheet.dart';
import '../widgets/supplier_list.dart';
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

  @override
  void initState() {
    super.initState();
    // Sync local search controller with provider's search query if it changes
    // from filters clearing
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
    super.dispose();
  }

  void _showFormBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: context.read<SuppliersProvider>(),
          child: const SupplierForm(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SuppliersProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Directorio de Proveedores'),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        actions: [
          OutlinedButton.icon(
            onPressed: () => SupplierFilterSheet.show(context),
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (provider.isFilterActive)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            label: const Text('Filtrar'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: provider.isFilterActive
                    ? AppTheme.accentColor
                    : Colors.grey.shade300,
              ),
              foregroundColor: provider.isFilterActive
                  ? AppTheme.accentColor
                  : Colors.black87,
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () {
              provider.startAddingProveedor();
              _showFormBottomSheet(context);
            },
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: const Text('Nuevo Proveedor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: Column(
        children: [
          const SupplierMetricsCards(),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => provider.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, código o RNC...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.accentColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // Filters visual indicators (Chips)
          if (provider.isFilterActive)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 4.0,
              ),
              child: Row(
                children: [
                  const Text(
                    'Filtros Activos:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: [
                        if (provider.selectedType != 'Todos')
                          Chip(
                            label: Text(
                              'Tipo: ${provider.selectedType}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            onDeleted: () => provider.setFilters(type: 'Todos'),
                            backgroundColor: Colors.blue[50],
                            padding: EdgeInsets.zero,
                          ),
                        if (provider.selectedClassification != 'Todos')
                          Chip(
                            label: Text(
                              'Clasificación: ${provider.selectedClassification}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            onDeleted: () =>
                                provider.setFilters(classification: 'Todos'),
                            backgroundColor: Colors.blue[50],
                            padding: EdgeInsets.zero,
                          ),
                        if (provider.selectedStatus != 'Todos')
                          Chip(
                            label: Text(
                              'Estado: ${provider.selectedStatus}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            onDeleted: () =>
                                provider.setFilters(status: 'Todos'),
                            backgroundColor: Colors.blue[50],
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: provider.clearFilters,
                    child: const Text(
                      'Limpiar todo',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Cards List
          Expanded(child: SupplierList(onShowForm: _showFormBottomSheet)),
        ],
      ),
    );
  }
}
