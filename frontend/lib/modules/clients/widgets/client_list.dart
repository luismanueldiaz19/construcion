import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../../models/client.dart';
import '../providers/clients_provider.dart';

class ClientList extends StatelessWidget {
  final bool isLargeScreen;
  final Function(Client) onEditClient;

  const ClientList({
    super.key,
    required this.isLargeScreen,
    required this.onEditClient,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientsProvider>(
      builder: (context, provider, child) {
        if (provider.filteredClients.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 64, color: Colors.black26),
                SizedBox(height: 16),
                Text(
                  'No se encontraron clientes.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        // Use a responsive grid or list depending on the screen size
        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: isLargeScreen ? 450 : 600,
            mainAxisExtent: 180, // Fixed height for cards
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: provider.filteredClients.length,
          itemBuilder: (context, index) {
            final client = provider.filteredClients[index];
            final isSelected = provider.editingClient?.id == client.id;
            return _ClientCard(
              client: client,
              isSelected: isSelected,
              onEdit: () => onEditClient(client),
              onToggleStatus: (val) async {
                try {
                  await provider.toggleClientStatus(client);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(val ? 'Cliente activado' : 'Cliente inactivado'),
                        backgroundColor: val ? Colors.green : Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al cambiar estado: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            );
          },
        );
      },
    );
  }
}

class _ClientCard extends StatefulWidget {
  final Client client;
  final bool isSelected;
  final VoidCallback onEdit;
  final Function(bool) onToggleStatus;

  const _ClientCard({
    required this.client,
    required this.isSelected,
    required this.onEdit,
    required this.onToggleStatus,
  });

  @override
  State<_ClientCard> createState() => _ClientCardState();
}

class _ClientCardState extends State<_ClientCard> {
  bool _isHovered = false;

  String _translateType(String type) {
    switch (type) {
      case 'persona_fisica':
        return 'Persona Física';
      case 'empresa':
        return 'Empresa';
      case 'gobierno':
        return 'Gobierno';
      case 'institucion':
        return 'Institución';
      default:
        return type;
    }
  }

  String _translateClassification(String classification) {
    switch (classification) {
      case 'excelente':
        return 'Excelente';
      case 'bueno':
        return 'Bueno';
      case 'regular':
        return 'Regular';
      case 'riesgoso':
        return 'Riesgoso';
      default:
        return classification;
    }
  }

  Color _getClassificationColor(String classification) {
    switch (classification) {
      case 'excelente':
        return Colors.green;
      case 'bueno':
        return Colors.blue;
      case 'regular':
        return Colors.orange;
      case 'riesgoso':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    final f = NumberFormat.currency(symbol: '\$ ');
    final classColor = _getClassificationColor(client.classification);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isSelected
                ? AppTheme.accentColor
                : (_isHovered ? Colors.grey[300]! : Colors.transparent),
            width: widget.isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isSelected
                  ? AppTheme.accentColor.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.04),
              blurRadius: _isHovered ? 20 : 10,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: widget.onEdit,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Name and Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          client.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: client.active ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: client.active ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          client.active ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            color: client.active ? Colors.green[700] : Colors.red[700],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    client.code,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Info Rows
                  Row(
                    children: [
                      Icon(Icons.badge_outlined, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          client.documentNumber ?? 'N/A',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.category_outlined, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _translateType(client.type),
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  // Footer: Classification, Credit, Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: classColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _translateClassification(client.classification),
                              style: TextStyle(
                                color: classColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          if (client.creditLimit > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                f.format(client.creditLimit),
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            child: Switch(
                              value: client.active,
                              activeThumbColor: AppTheme.accentColor,
                              onChanged: widget.onToggleStatus,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: widget.isSelected ? AppTheme.accentColor : Colors.grey[400],
                          ),
                        ],
                      ),
                    ],
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
