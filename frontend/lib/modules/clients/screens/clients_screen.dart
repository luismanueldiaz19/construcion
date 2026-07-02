import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../providers/clients_provider.dart';
import '../widgets/client_metrics_cards.dart';
import '../widgets/client_filter_sheet.dart';
import '../widgets/client_list.dart';
import '../widgets/client_form.dart';

class ClientsScreen extends StatelessWidget {
  final bool autoOpenAdd;

  const ClientsScreen({super.key, this.autoOpenAdd = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = ClientsProvider();
        if (autoOpenAdd) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.startAddingClient();
          });
        }
        return provider;
      },
      child: const _ClientsScreenContent(),
    );
  }
}

class _ClientsScreenContent extends StatefulWidget {
  const _ClientsScreenContent();

  @override
  State<_ClientsScreenContent> createState() => _ClientsScreenContentState();
}

class _ClientsScreenContentState extends State<_ClientsScreenContent> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Synchronize controller with provider's search query (if cleared from somewhere else)
    final provider = context.watch<ClientsProvider>();
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
      constraints: const BoxConstraints(maxWidth: 700),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: context.read<ClientsProvider>(),
          child: Builder(
            builder: (sheetContext) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ClientForm(
                        isBottomSheet: true,
                        onCancel: () {
                          sheetContext.read<ClientsProvider>().cancelForm();
                          Navigator.pop(sheetContext);
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ).then((_) {
      if (mounted) {
        context.read<ClientsProvider>().cancelForm();
      }
    });
  }

  void _onCreateClientPressed(BuildContext context, bool isLargeScreen) {
    final provider = context.read<ClientsProvider>();
    provider.startAddingClient();
    if (!isLargeScreen) {
      _showFormBottomSheet(context);
    }
  }

  void _onEditClientPressed(BuildContext context, client, bool isLargeScreen) {
    final provider = context.read<ClientsProvider>();
    provider.selectClientForEdit(client);
    if (!isLargeScreen) {
      _showFormBottomSheet(context);
    }
  }

  Widget _buildFilterChips(BuildContext context) {
    final provider = context.watch<ClientsProvider>();
    if (!provider.isFilterActive) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: [
          const Text(
            'Filtros activos: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                if (provider.searchQuery.isNotEmpty)
                  Chip(
                    label: Text('Buscar: "${provider.searchQuery}"'),
                    onDeleted: () {
                      provider.setSearchQuery('');
                      _searchController.clear();
                    },
                    backgroundColor: Colors.blue[50],
                  ),
                if (provider.selectedType != 'Todos')
                  Chip(
                    label: Text('Tipo: ${provider.selectedType}'),
                    onDeleted: () => provider.setFilters(type: 'Todos'),
                    backgroundColor: Colors.orange[50],
                  ),
                if (provider.selectedClassification != 'Todos')
                  Chip(
                    label: Text(
                      'Clasificación: ${provider.selectedClassification}',
                    ),
                    onDeleted: () =>
                        provider.setFilters(classification: 'Todos'),
                    backgroundColor: Colors.purple[50],
                  ),
                if (provider.selectedStatus != 'Todos')
                  Chip(
                    label: Text('Estado: ${provider.selectedStatus}'),
                    onDeleted: () => provider.setFilters(status: 'Todos'),
                    backgroundColor: Colors.teal[50],
                  ),
                TextButton(
                  onPressed: () {
                    provider.clearFilters();
                    _searchController.clear();
                  },
                  child: const Text('Limpiar todo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final provider = context.read<ClientsProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => provider.setSearchQuery(value),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, código, RNC...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
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
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppTheme.accentColor),
          ),
          // Subtle shadow for the search bar to match the premium theme
        ),
      ),
    );
  }

  Widget _buildPlaceholderForm(BuildContext context, bool isLargeScreen) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Detalles del Cliente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Seleccione un cliente de la lista para ver o editar sus datos, o presione "Nuevo Cliente" para registrar uno.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _onCreateClientPressed(context, isLargeScreen),
            icon: const Icon(Icons.person_add, size: 20),
            label: const Text('Registrar Cliente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isLargeScreen = width > 1150;
    final provider = context.watch<ClientsProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Directorio de Clientes'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          OutlinedButton.icon(
            onPressed: () => ClientFilterSheet.show(context),
            icon: Icon(
              provider.isFilterActive
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
              color: provider.isFilterActive
                  ? AppTheme.accentColor
                  : AppTheme.textSecondary,
              size: 20,
            ),
            label: Text(
              'Filtrar',
              style: TextStyle(
                color: provider.isFilterActive
                    ? AppTheme.accentColor
                    : AppTheme.textSecondary,
                fontWeight: provider.isFilterActive
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: provider.isFilterActive
                    ? AppTheme.accentColor
                    : Colors.grey[300]!,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _onCreateClientPressed(context, isLargeScreen),
            icon: const Icon(Icons.person_add),
            label: const Text('Nuevo Cliente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.loadClients,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                const ClientMetricsCards(),
                _buildSearchBar(context),
                _buildFilterChips(context),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 8.0,
                            top: 8.0,
                            bottom: 8.0,
                          ),
                          child: ClientList(
                            isLargeScreen: isLargeScreen,
                            onEditClient: (client) => _onEditClientPressed(
                              context,
                              client,
                              isLargeScreen,
                            ),
                          ),
                        ),
                      ),
                      if (isLargeScreen)
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 24.0,
                              bottom: 24.0,
                              right: 24.0,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child:
                                  (provider.isAddingClient ||
                                      provider.editingClient != null)
                                  ? Container(
                                      key: const ValueKey('client_form'),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.02,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClientForm(
                                        isBottomSheet: false,
                                        onCancel: provider.cancelForm,
                                      ),
                                    )
                                  : _buildPlaceholderForm(
                                      context,
                                      isLargeScreen,
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
