import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../core/utils/excel_parser.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_confirm_dialog.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_status_badge.dart';
import '../providers/project_form_provider.dart';
import 'dialogs/partida_form_dialog.dart';
import 'project_partida_card.dart';

/// Paso 2: Lista limpia de partidas con creación/edición mediante diálogo.
class ProjectBudgetStep extends StatelessWidget {
  final NumberFormat formatter;

  const ProjectBudgetStep({super.key, required this.formatter});

  Future<void> _openPartidaDialog(
    BuildContext context,
    ProjectFormProvider provider, {
    int? editIndex,
  }) async {
    final initial = editIndex != null ? provider.partidas[editIndex] : null;
    final result = await PartidaFormDialog.show(
      context,
      initialPartida: initial,
      formatter: formatter,
    );

    if (result != null) {
      provider.savePartidaData(result, editIndex: editIndex);
      if (context.mounted) {
        AppAlert.showToast(
          context,
          editIndex != null ? 'Partida actualizada.' : 'Partida agregada.',
          type: AppAlertType.success,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  Future<void> _confirmRemovePartida(
    BuildContext context,
    ProjectFormProvider provider,
    int index,
  ) async {
    final nombre =
        provider.partidas[index]['descripcion']?.toString().trim() ?? '';
    final confirmed = await AppConfirmDialog.show(
      context,
      title: '¿Eliminar partida?',
      message:
          'Se eliminará "${nombre.isEmpty ? 'Partida #${index + 1}' : nombre}" junto con todas sus sub-partidas.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      isDestructive: true,
    );
    if (confirmed) {
      provider.removePartida(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectFormProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Encabezado y controles integrados en la parte superior
        Row(
          children: [
            const Icon(
              Icons.list_alt_rounded,
              size: 18,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Partidas del Presupuesto',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            AppStatusBadge(
              label: '${provider.partidas.length} partidas',
              type: AppStatusType.info,
            ),
            if (provider.totalSubpartidas > 0) ...[
              const SizedBox(width: 6),
              AppStatusBadge(
                label: '${provider.totalSubpartidas} ítems',
                type: AppStatusType.neutral,
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppButton(
              text: 'Nueva Partida',
              icon: Icons.add_circle_outline_rounded,
              size: AppButtonSize.compact,
              variant: AppButtonVariant.secondary,
              borderRadius: 8,
              onPressed: () => _openPartidaDialog(context, provider),
            ),
            AppButton(
              text: 'Importar Excel',
              icon: Icons.table_view_rounded,
              size: AppButtonSize.compact,
              variant: AppButtonVariant.success,
              borderRadius: 8,
              onPressed: () =>
                  _showExcelImportInstructions(context, provider),
            ),
            if (provider.partidas.isNotEmpty)
              AppButton(
                text: 'Limpiar',
                icon: Icons.delete_sweep_rounded,
                size: AppButtonSize.compact,
                variant: AppButtonVariant.danger,
                borderRadius: 8,
                onPressed: () => _confirmClearAll(context, provider),
              ),
          ],
        ),
        const Divider(height: 20, color: Color(0xFFE2E8F0)),

        // Lista limpia de partidas o estado vacío
        if (provider.partidas.isEmpty)
          AppEmptyState(
            icon: Icons.playlist_add_rounded,
            title: 'Sin partidas registradas',
            description:
                'Crea tu primera partida con sus sub-partidas o importa un presupuesto desde Excel (.xlsx).',
            actionText: 'Nueva Partida',
            onAction: () => _openPartidaDialog(context, provider),
          )
        else ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              'Toca una partida para ver sus sub-partidas o pulsa editar para modificarla.',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ...provider.partidas.asMap().entries.map(
                (e) => ProjectPartidaCard(
                  pIndex: e.key,
                  partida: e.value,
                  formatter: formatter,
                  onEdit: () =>
                      _openPartidaDialog(context, provider, editIndex: e.key),
                  onDelete: () =>
                      _confirmRemovePartida(context, provider, e.key),
                ),
              ),
        ],
      ],
    );
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    ProjectFormProvider provider,
  ) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: '¿Eliminar todas las partidas?',
      message:
          'Se eliminarán todas las partidas y sub-partidas cargadas. Esta acción no se puede deshacer.',
      confirmText: 'Sí, eliminar',
      cancelText: 'Cancelar',
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      provider.clearAllPartidas();
      AppAlert.showToast(
        context,
        'Todas las partidas han sido eliminadas.',
        type: AppAlertType.warning,
      );
    }
  }

  void _showExcelImportInstructions(
    BuildContext context,
    ProjectFormProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.table_view_rounded,
                        color: AppTheme.successColor,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Formato de Excel Requerido',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'El archivo (.xlsx) debe contener estas columnas desde la fila 1:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('A: NO (Número, ej: 1.00, 1.01)',
                            style: TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.w600)),
                        SizedBox(height: 3),
                        Text('B: PARTIDAS (Descripción del trabajo)',
                            style: TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.w600)),
                        SizedBox(height: 3),
                        Text('C: CANT. (Cantidad)',
                            style: TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.w600)),
                        SizedBox(height: 3),
                        Text('D: UD (Unidad, ej: M2, M3, GL)',
                            style: TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.w600)),
                        SizedBox(height: 3),
                        Text('E: PU (Precio Unitario)',
                            style: TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const AppAlert(
                    type: AppAlertType.info,
                    message:
                        'Filas con CANT. vacío o 0 se toman como Partidas. Filas con CANT. > 0 se agregan como Sub-partidas.',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Cancelar',
                          variant: AppButtonVariant.outlined,
                          size: AppButtonSize.compact,
                          isFullWidth: true,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppButton(
                          text: 'Subir Excel',
                          icon: Icons.upload_file_rounded,
                          variant: AppButtonVariant.success,
                          size: AppButtonSize.compact,
                          isFullWidth: true,
                          onPressed: () {
                            Navigator.pop(ctx);
                            _importExcel(context, provider);
                          },
                        ),
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

  Future<void> _importExcel(
    BuildContext context,
    ProjectFormProvider provider,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.accentColor,
              ),
              SizedBox(height: 14),
              Text(
                'Importando Partidas...',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Procesando archivo Excel, espera un momento',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await ExcelParser.parseBudgetExcel();
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      if (result != null && result.isNotEmpty) {
        await provider.appendFromExcel(result);
        if (context.mounted) {
          AppAlert.showToast(
            context,
            'Se importaron ${result.length} partidas exitosamente.',
            type: AppAlertType.success,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        AppAlert.showToast(
          context,
          'Error de importación: ${e.toString().replaceAll('Exception:', '').trim()}',
          type: AppAlertType.error,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }
}
