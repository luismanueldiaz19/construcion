import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../models/client.dart';
import '../../../services/client_service.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_status_badge.dart';
import '../../../widgets/app_text_field.dart';
import '../../clients/screens/clients_screen.dart';

/// Selector compacto de cliente con modal de búsqueda y creación rápida.
class ClientSelector extends StatelessWidget {
  final Client? initialClient;
  final ValueChanged<Client?> onChanged;

  const ClientSelector({
    super.key,
    this.initialClient,
    required this.onChanged,
  });

  void _showClientSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ClientSearchModal(
        onSelected: (client) {
          onChanged(client);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasClient = initialClient != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Cliente (Opcional)',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 5),
        InkWell(
          onTap: () => _showClientSearchModal(context),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(minHeight: 42),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasClient ? AppTheme.accentColor : Colors.grey.shade300,
                width: hasClient ? 1.4 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_search_outlined,
                  size: 18,
                  color: hasClient
                      ? AppTheme.accentColor
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    initialClient?.name ?? 'Seleccionar cliente...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: hasClient
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: hasClient
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
                if (hasClient)
                  InkWell(
                    onTap: () => onChanged(null),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ClientSearchModal extends StatefulWidget {
  final ValueChanged<Client> onSelected;

  const _ClientSearchModal({required this.onSelected});

  @override
  State<_ClientSearchModal> createState() => _ClientSearchModalState();
}

class _ClientSearchModalState extends State<_ClientSearchModal> {
  final ClientService _clientService = ClientService();
  final TextEditingController _searchController = TextEditingController();
  List<Client> _clients = [];
  bool _isLoading = false;

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

  Future<void> _loadClients([String search = '']) async {
    setState(() => _isLoading = true);
    try {
      final clients = await _clientService.getClients(
        search: search,
        active: true,
      );
      if (mounted) {
        setState(() => _clients = clients);
      }
    } catch (_) {
      // Silencio intencional en búsqueda incremental
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openCreateClient() async {
    FocusScope.of(context).unfocus();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ClientsScreen(autoOpenAdd: true),
      ),
    );
    _loadClients(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Seleccionar Cliente',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  AppButton(
                    text: 'Crear',
                    icon: Icons.add_rounded,
                    size: AppButtonSize.compact,
                    variant: AppButtonVariant.outlined,
                    borderRadius: 8,
                    onPressed: _openCreateClient,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: AppTextField(
                controller: _searchController,
                hintText: 'Buscar por nombre, documento o código...',
                prefixIconData: Icons.search_rounded,
                onChanged: _loadClients,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppTheme.accentColor,
                      ),
                    )
                  : _clients.isEmpty
                  ? AppEmptyState(
                      icon: Icons.person_off_outlined,
                      title: 'No se encontraron clientes',
                      description:
                          'Intenta con otro término o crea un nuevo cliente.',
                      actionText: 'Nuevo Cliente',
                      onAction: _openCreateClient,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      itemCount: _clients.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final client = _clients[index];
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primaryColor.withValues(
                              alpha: 0.08,
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          title: Text(
                            client.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            client.documentNumber ?? 'Sin documento',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          trailing: AppStatusBadge(
                            label: client.classification,
                            type: AppStatusType.neutral,
                          ),
                          onTap: () => widget.onSelected(client),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
