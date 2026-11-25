import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/app_theme.dart';
import '../../../models/client.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_status_badge.dart';

/// Modal inferior compacto para ver el detalle completo de un Cliente.
class ClientDetailSheet extends StatelessWidget {
  final Client client;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  const ClientDetailSheet({
    super.key,
    required this.client,
    required this.onEdit,
    required this.onToggleStatus,
  });

  static Future<void> show(
    BuildContext context, {
    required Client client,
    required VoidCallback onEdit,
    required VoidCallback onToggleStatus,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClientDetailSheet(
        client: client,
        onEdit: onEdit,
        onToggleStatus: onToggleStatus,
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'empresa':
        return 'Empresa';
      case 'gobierno':
        return 'Gobierno';
      case 'institucion':
        return 'Institución';
      default:
        return 'Persona Física';
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
    final currencyFmt = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);
    final locationParts = [
      if (client.address != null && client.address!.isNotEmpty) client.address!,
      if (client.sector != null && client.sector!.isNotEmpty) client.sector!,
      if (client.city != null && client.city!.isNotEmpty) client.city!,
      if (client.province != null && client.province!.isNotEmpty)
        client.province!,
    ];

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      client.type == 'empresa'
                          ? Icons.business_rounded
                          : Icons.person_outline_rounded,
                      size: 19,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            AppStatusBadge(
                              label: client.active ? 'ACTIVO' : 'INACTIVO',
                              type: client.active
                                  ? AppStatusType.active
                                  : AppStatusType.inactive,
                            ),
                            AppStatusBadge(
                              label: client.classification.toUpperCase(),
                              type: _classificationType(client.classification),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close_rounded, size: 19),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InfoRow('Código', client.code),
                    _InfoRow('Tipo', _typeLabel(client.type)),
                    if (client.commercialName != null &&
                        client.commercialName!.isNotEmpty)
                      _InfoRow('Nombre Comercial', client.commercialName!),
                    _InfoRow(
                      'RNC / Cédula',
                      client.documentNumber ?? 'No registrado',
                    ),
                    if (client.phone != null && client.phone!.isNotEmpty)
                      _InfoRow('Teléfono', client.phone!),
                    if (client.mobile != null && client.mobile!.isNotEmpty)
                      _InfoRow('Celular', client.mobile!),
                    if (client.email != null && client.email!.isNotEmpty)
                      _InfoRow('Correo', client.email!),
                    if (client.contactName != null &&
                        client.contactName!.isNotEmpty)
                      _InfoRow(
                        'Contacto',
                        '${client.contactName!}${client.contactPosition != null ? ' (${client.contactPosition})' : ''}',
                      ),
                    if (locationParts.isNotEmpty)
                      _InfoRow('Ubicación', locationParts.join(', ')),
                    const Divider(height: 18, color: Color(0xFFE2E8F0)),
                    _InfoRow(
                      'Límite de Crédito',
                      currencyFmt.format(client.creditLimit),
                    ),
                    _InfoRow('Días de Crédito', '${client.creditDays} días'),
                    if (client.notes != null && client.notes!.isNotEmpty) ...[
                      const Divider(height: 18, color: Color(0xFFE2E8F0)),
                      const Text(
                        'Notas',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        client.notes!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: client.active ? 'Desactivar' : 'Activar',
                        icon: client.active
                            ? Icons.block_rounded
                            : Icons.check_circle_outline_rounded,
                        variant: AppButtonVariant.outlined,
                        size: AppButtonSize.compact,
                        borderRadius: 9,
                        isFullWidth: true,
                        onPressed: () {
                          Navigator.of(context).pop();
                          onToggleStatus();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        text: 'Editar',
                        icon: Icons.edit_outlined,
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.compact,
                        borderRadius: 9,
                        isFullWidth: true,
                        onPressed: () {
                          Navigator.of(context).pop();
                          onEdit();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
