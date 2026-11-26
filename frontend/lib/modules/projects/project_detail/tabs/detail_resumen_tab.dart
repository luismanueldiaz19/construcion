import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/constants.dart';
import '../../../../core/utils/image_compressor.dart';
import '../../../../widgets/app_alert.dart';
import '../../../../widgets/app_confirm_dialog.dart';
import '../../../../widgets/app_status_badge.dart';
import '../dialogs/edit_project_info_dialog.dart';
import '../providers/project_detail_provider.dart';

/// Pestaña 1 (Resumen): Integrada a la pantalla, compacta y sin overflows.
class DetailResumenTab extends StatelessWidget {
  const DetailResumenTab({super.key});

  Future<void> _handleEditInfo(
    BuildContext context,
    ProjectDetailProvider provider,
  ) async {
    final p = provider.proyecto!;
    final result = await EditProjectInfoDialog.show(
      context,
      initialNombre: p.nombre,
      initialNotas: p.notas ?? '',
    );
    if (result == null) return;

    try {
      await provider.actualizarProyectoDetalles(result.nombre, result.notas);
      if (context.mounted) {
        AppAlert.showToast(
          context,
          'Proyecto actualizado correctamente.',
          type: AppAlertType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppAlert.showToast(
          context,
          'Error al actualizar: $e',
          type: AppAlertType.error,
        );
      }
    }
  }

  Future<void> _handleChangeStatus(
    BuildContext context,
    ProjectDetailProvider provider,
  ) async {
    final options = provider.nextEstados;
    if (options.isEmpty) {
      AppAlert.showToast(
        context,
        'Este proyecto ya está finalizado o cancelado.',
        type: AppAlertType.info,
      );
      return;
    }

    final nuevoEstado = await ChangeProjectStatusDialog.show(
      context,
      currentStatus: provider.proyecto!.estado,
      options: options,
    );
    if (nuevoEstado == null) return;

    try {
      await provider.cambiarEstado(nuevoEstado);
      if (context.mounted) {
        AppAlert.showToast(
          context,
          'Estado actualizado a $nuevoEstado.',
          type: AppAlertType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppAlert.showToast(
          context,
          'Error al cambiar estado: $e',
          type: AppAlertType.error,
        );
      }
    }
  }

  Future<void> _handleUploadLogo(
    BuildContext context,
    ProjectDetailProvider provider,
  ) async {
    final image = await ImageCompressor.pickAndCompressWithModal(context);
    if (image == null) return;

    try {
      final uploaded = await provider.pickAndUploadLogo(preselectedImage: image);
      if (uploaded && context.mounted) {
        AppAlert.showToast(
          context,
          'Logo optimizado y actualizado correctamente.',
          type: AppAlertType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppAlert.showToast(context, 'Error: $e', type: AppAlertType.error);
      }
    }
  }

  Future<void> _handleRemoveLogo(
    BuildContext context,
    ProjectDetailProvider provider,
  ) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: '¿Eliminar logo?',
      message: 'Se quitará la imagen asociada a este proyecto.',
      confirmText: 'Eliminar',
      isDestructive: true,
    );
    if (!confirmed) return;

    try {
      await provider.removeLogo();
      if (context.mounted) {
        AppAlert.showToast(
          context,
          'Logo eliminado.',
          type: AppAlertType.warning,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppAlert.showToast(context, 'Error: $e', type: AppAlertType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectDetailProvider>();
    final proyecto = provider.proyecto!;
    final currencyFmt = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);
    final dateFmt = DateFormat('dd/MM/yyyy');

    final avance = provider.avanceFisico;
    final progressColor = avance >= 75
        ? const Color(0xFF16A34A)
        : avance >= 25
            ? const Color(0xFF2563EB)
            : const Color(0xFFD97706);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bloque superior: Logo + Identidad + Editar + Estado
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProjectLogoBox(
              logoPath: proyecto.logoPath,
              onUpload: () => _handleUploadLogo(context, provider),
              onRemove: () => _handleRemoveLogo(context, provider),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          proyecto.nombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            height: 1.2,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Editar nombre y notas',
                        onPressed: () => _handleEditInfo(context, provider),
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppTheme.ledhouseBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _MetaLine(
                    icon: Icons.person_outline_rounded,
                    text: proyecto.cliente.isNotEmpty
                        ? proyecto.cliente
                        : 'Cliente sin asignar',
                  ),
                  const SizedBox(height: 3),
                  _MetaLine(
                    icon: Icons.location_on_outlined,
                    text: (proyecto.ubicacion != null &&
                            proyecto.ubicacion!.isNotEmpty)
                        ? proyecto.ubicacion!
                        : 'Ubicación no especificada',
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _handleChangeStatus(context, provider),
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppStatusBadge(
                          label: proyecto.estado.toUpperCase(),
                          type: provider.statusType,
                          icon: provider.nextEstados.isNotEmpty
                              ? Icons.edit_outlined
                              : null,
                        ),
                        if (provider.nextEstados.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          const Text(
                            'Cambiar estado',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 22, color: Color(0xFFE2E8F0)),

        // Barra de avance físico
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Avance Físico de Obra',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              '${avance.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: avance / 100.0,
            minHeight: 7,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
        const SizedBox(height: 14),

        // KPIs financieros compactos en cuadrícula de 2 columnas (0 overflow)
        Row(
          children: [
            Expanded(
              child: _CompactKpiTile(
                label: 'Presupuesto Total',
                value: currencyFmt.format(provider.presupuestoTotal),
                color: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompactKpiTile(
                label: 'Total Gastado',
                value: currencyFmt.format(provider.totalGastado),
                color: AppTheme.dangerColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _CompactKpiTile(
                label: 'Total Cobrado',
                value: currencyFmt.format(provider.totalCobrado),
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompactKpiTile(
                label: 'Saldo Pendiente',
                value: currencyFmt.format(provider.saldoPendiente),
                color: const Color(0xFFD97706),
              ),
            ),
          ],
        ),
        const Divider(height: 22, color: Color(0xFFE2E8F0)),

        // Detalle de fechas y desglose presupuestario
        const Text(
          'Información y Desglose',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _KeyValueLine(
          label: 'Fechas',
          value:
              '${proyecto.fechaInicio != null ? dateFmt.format(proyecto.fechaInicio!) : '--'} → ${proyecto.fechaFin != null ? dateFmt.format(proyecto.fechaFin!) : '--'}',
        ),
        _KeyValueLine(
          label: 'Partidas registradas',
          value: '${proyecto.partidas.length}',
        ),
        _KeyValueLine(
          label: 'Sub-total directo',
          value: currencyFmt.format(proyecto.presupuestoEstimado),
        ),
        _KeyValueLine(
          label: 'Transporte',
          value: currencyFmt.format(proyecto.transporte),
        ),
        _KeyValueLine(
          label: 'ITBIS',
          value: currencyFmt.format(proyecto.itbis),
        ),
        if (proyecto.supervisionTecnica > 0)
          _KeyValueLine(
            label: 'Supervisión técnica',
            value: currencyFmt.format(proyecto.supervisionTecnica),
          ),
        if (proyecto.otrosCostos > 0)
          _KeyValueLine(
            label: 'Otros costos indirectos',
            value: currencyFmt.format(proyecto.otrosCostos),
          ),

        // Notas / Resumen
        if (proyecto.notas != null && proyecto.notas!.trim().isNotEmpty) ...[
          const Divider(height: 22, color: Color(0xFFE2E8F0)),
          const Text(
            'Notas / Resumen',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            proyecto.notas!,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProjectLogoBox extends StatelessWidget {
  final String? logoPath;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  const _ProjectLogoBox({
    required this.logoPath,
    required this.onUpload,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onUpload,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: logoPath == null
            ? const Icon(
                Icons.add_a_photo_outlined,
                color: Color(0xFF94A3B8),
                size: 24,
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      '$host/api/v1/file?path=$logoPath',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: Color(0xFF94A3B8),
                        size: 22,
                      ),
                    ),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: InkWell(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF64748B)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactKpiTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CompactKpiTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyValueLine extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValueLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
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
