import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../models/client.dart';
import '../../../services/client_service.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_confirm_dialog.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_status_badge.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/cliente_dialog.dart';
import '../../clients/widgets/client_detail_sheet.dart';

/// Directorio moderno y compacto de Clientes dentro del Home unificado.
class HomeClientesScreen extends StatefulWidget {
  const HomeClientesScreen({super.key});

  @override
  State<HomeClientesScreen> createState() => _HomeClientesScreenState();
}

class _HomeClientesScreenState extends State<HomeClientesScreen> {
  final ClientService _clientService = ClientService();
  final TextEditingController _searchController = TextEditingController();

  List<Client> _clients = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedFilter = 'Activos';

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final clients = await _clientService.getClients();
      if (mounted) {
        setState(() {
          _clients = clients;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar clientes: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<Client> get _filteredClients {
    return _clients.where((c) {
      if (_selectedFilter == 'Activos' && !c.active) return false;
      if (_selectedFilter == 'Inactivos' && c.active) return false;
      if (_selectedFilter == 'Empresas' && c.type != 'empresa') return false;
      if (_selectedFilter == 'Personas' && c.type != 'persona_fisica') {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = c.name.toLowerCase().contains(q);
        final matchesCode = c.code.toLowerCase().contains(q);
        final matchesDoc = c.documentNumber?.toLowerCase().contains(q) ?? false;
        final matchesPhone = (c.phone?.toLowerCase().contains(q) ?? false) ||
            (c.mobile?.toLowerCase().contains(q) ?? false);
        return matchesName || matchesCode || matchesDoc || matchesPhone;
      }
      return true;
    }).toList();
  }

  Future<void> _openForm([Client? client]) async {
    final saved = await showDialog<Client>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ClienteDialog(client: client),
    );
    if (saved != null) {
      _loadClients();
    }
  }

  Future<void> _toggleStatus(Client client) async {
    if (client.id == null) return;
    final confirmed = await AppConfirmDialog.show(
      context,
      title: client.active ? '¿Desactivar cliente?' : '¿Activar cliente?',
      message: client.active
          ? 'El cliente "${client.name}" quedará inactivo y no aparecerá en selecciones rápidas.'
          : 'El cliente "${client.name}" volverá a estar disponible.',
      confirmText: client.active ? 'Desactivar' : 'Activar',
      isDestructive: client.active,
    );
    if (!confirmed) return;

    try {
      await _clientService.toggleActive(client.id!);
      if (mounted) {
        AppAlert.showToast(
          context,
          client.active ? 'Cliente desactivado.' : 'Cliente activado.',
          type: AppAlertType.success,
        );
      }
      _loadClients();
    } catch (e) {
      if (mounted) {
        AppAlert.showToast(
          context,
          'Error al cambiar estado: $e',
          type: AppAlertType.error,
        );
      }
    }
  }

  AppStatusType _classificationType(String cls) {
    switch (cls.toLowerCase()) {
      case 'excelente':
        return AppStatusType.active;
      case 'bueno':
        return AppStatusType.info;
      case 'regular':
        return AppStatusType.pending;
      case 'riesgoso':
        return AppStatusType.inactive;
      default:
        return AppStatusType.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredClients;
    final totalActivos = _clients.where((c) => c.active).length;
    final totalEmpresas = _clients.where((c) => c.type == 'empresa').length;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_nuevo_cliente',
        onPressed: () => _openForm(),
        tooltip: 'Nuevo Cliente',
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          // Barra superior de búsqueda y filtros
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _searchController,
                  hintText: 'Buscar cliente, RNC, código o teléfono...',
                  prefixIconData: Icons.search_rounded,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 17),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Activos',
                        selected: _selectedFilter == 'Activos',
                        onTap: () =>
                            setState(() => _selectedFilter = 'Activos'),
                      ),
                      _FilterChip(
                        label: 'Todos',
                        selected: _selectedFilter == 'Todos',
                        onTap: () => setState(() => _selectedFilter = 'Todos'),
                      ),
                      _FilterChip(
                        label: 'Empresas',
                        selected: _selectedFilter == 'Empresas',
                        onTap: () =>
                            setState(() => _selectedFilter = 'Empresas'),
                      ),
                      _FilterChip(
                        label: 'Personas',
                        selected: _selectedFilter == 'Personas',
                        onTap: () =>
                            setState(() => _selectedFilter = 'Personas'),
                      ),
                      _FilterChip(
                        label: 'Inactivos',
                        selected: _selectedFilter == 'Inactivos',
                        onTap: () =>
                            setState(() => _selectedFilter = 'Inactivos'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Franja compacta de KPIs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MiniKpi(
                    label: 'Total',
                    value: '${_clients.length}',
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniKpi(
                    label: 'Activos',
                    value: '$totalActivos',
                    color: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniKpi(
                    label: 'Empresas',
                    value: '$totalEmpresas',
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),

          // Lista principal
          Expanded(
            child: _buildListContent(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent(List<Client> filtered) {
    if (_isLoading && _clients.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppTheme.accentColor,
        ),
      );
    }

    if (_error != null && _clients.isEmpty) {
      return AppEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'No se pudieron cargar los clientes',
        description: _error,
        actionText: 'Reintentar',
        onAction: _loadClients,
      );
    }

    if (filtered.isEmpty) {
      return AppEmptyState(
        icon: Icons.contact_phone_outlined,
        title: _searchQuery.isNotEmpty
            ? 'Sin resultados para "$_searchQuery"'
            : 'No hay clientes en "$_selectedFilter"',
        description:
            'Prueba cambiando el filtro o registra un nuevo cliente.',
        actionText: 'Nuevo Cliente',
        onAction: () => _openForm(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClients,
      color: AppTheme.accentColor,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 84),
        itemCount: filtered.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
        itemBuilder: (context, index) {
          final c = filtered[index];
          final contactInfo = [
            if (c.documentNumber != null && c.documentNumber!.isNotEmpty)
              c.documentNumber!,
            if (c.mobile != null && c.mobile!.isNotEmpty)
              c.mobile!
            else if (c.phone != null && c.phone!.isNotEmpty)
              c.phone!,
          ].join(' · ');

          return InkWell(
            onTap: () => ClientDetailSheet.show(
              context,
              client: c,
              onEdit: () => _openForm(c),
              onToggleStatus: () => _toggleStatus(c),
            ),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: (c.active
                              ? AppTheme.primaryColor
                              : const Color(0xFF94A3B8))
                          .withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      c.type == 'empresa'
                          ? Icons.business_rounded
                          : Icons.person_outline_rounded,
                      size: 18,
                      color: c.active
                          ? AppTheme.primaryColor
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          contactInfo.isNotEmpty ? contactInfo : c.code,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppStatusBadge(
                        label: c.classification.toUpperCase(),
                        type: _classificationType(c.classification),
                      ),
                      if (!c.active) ...[
                        const SizedBox(height: 3),
                        const AppStatusBadge(
                          label: 'INACTIVO',
                          type: AppStatusType.inactive,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    tooltip: 'Editar cliente',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 17,
                      color: AppTheme.ledhouseBlue,
                    ),
                    onPressed: () => _openForm(c),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AppTheme.accentColor : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppTheme.accentColor : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniKpi extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniKpi({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
