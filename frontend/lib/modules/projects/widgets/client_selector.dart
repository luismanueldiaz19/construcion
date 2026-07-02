import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../models/client.dart';
import '../../../services/client_service.dart';
import '../../clients/screens/clients_screen.dart';

class ClientSelector extends StatefulWidget {
  final Client? initialClient;
  final Function(Client?) onChanged;

  const ClientSelector({
    super.key,
    this.initialClient,
    required this.onChanged,
  });

  @override
  State<ClientSelector> createState() => _ClientSelectorState();
}

class _ClientSelectorState extends State<ClientSelector> {
  Client? _selectedClient;

  @override
  void initState() {
    super.initState();
    _selectedClient = widget.initialClient;
  }

  void _showClientSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ClientSearchModal(
        onSelected: (client) {
          setState(() {
            _selectedClient = client;
          });
          widget.onChanged(client);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showClientSearchModal,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedClient != null
                ? AppTheme.primaryColor
                : Colors.grey.withValues(alpha: 0.2),
            width: _selectedClient != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.person_search_outlined,
              color: _selectedClient != null
                  ? AppTheme.primaryColor
                  : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cliente (Opcional)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedClient?.name ?? 'Seleccionar Cliente',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: _selectedClient != null
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _selectedClient != null
                          ? Colors.black87
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedClient != null)
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                onPressed: () {
                  setState(() => _selectedClient = null);
                  widget.onChanged(null);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _ClientSearchModal extends StatefulWidget {
  final Function(Client) onSelected;

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

  Future<void> _loadClients([String search = '']) async {
    setState(() => _isLoading = true);
    try {
      final clients = await _clientService.getClients(
        search: search,
        active: true,
      );
      setState(() {
        _clients = clients;
      });
    } catch (e) {
      // Handle error silently
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Text(
                  'Seleccionar Cliente',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text(
                    'Crear',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                  onPressed: () async {
                    // Cierra el teclado antes de navegar si está abierto
                    FocusScope.of(context).unfocus();

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ClientsScreen(autoOpenAdd: true),
                      ),
                    );
                    // Recargar los clientes al regresar de la pantalla de creación
                    _loadClients();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, documento o código...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                _loadClients(val);
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _clients.isEmpty
                ? const Center(child: Text('No se encontraron clientes'))
                : ListView.builder(
                    itemCount: _clients.length,
                    itemBuilder: (context, index) {
                      final client = _clients[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withValues(
                            alpha: 0.1,
                          ),
                          child: Icon(
                            Icons.person,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        title: Text(
                          client.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${client.documentNumber ?? "Sin doc"} • ${client.classification}',
                        ),
                        onTap: () => widget.onSelected(client),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
