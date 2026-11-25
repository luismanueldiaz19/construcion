import 'package:flutter/material.dart';
import '../../../../core/app_theme.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_text_field.dart';

/// Diálogo compacto para editar el nombre y las notas del proyecto.
class EditProjectInfoDialog extends StatefulWidget {
  final String initialNombre;
  final String initialNotas;

  const EditProjectInfoDialog({
    super.key,
    required this.initialNombre,
    required this.initialNotas,
  });

  static Future<({String nombre, String notas})?> show(
    BuildContext context, {
    required String initialNombre,
    required String initialNotas,
  }) {
    return showDialog<({String nombre, String notas})>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditProjectInfoDialog(
        initialNombre: initialNombre,
        initialNotas: initialNotas,
      ),
    );
  }

  @override
  State<EditProjectInfoDialog> createState() => _EditProjectInfoDialogState();
}

class _EditProjectInfoDialogState extends State<EditProjectInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _notasController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.initialNombre);
    _notasController = TextEditingController(text: widget.initialNotas);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop((
      nombre: _nombreController.text.trim().toUpperCase(),
      notas: _notasController.text.trim().toUpperCase(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      color: AppTheme.accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Editar Proyecto',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 18, color: Color(0xFFE2E8F0)),
                const Text(
                  'Nombre del Proyecto *',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 5),
                AppTextField(
                  controller: _nombreController,
                  hintText: 'EJ: TORRE LAS LOMAS',
                  prefixIconData: Icons.apartment_rounded,
                  uppercase: true,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Notas / Resumen',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 5),
                AppTextField(
                  controller: _notasController,
                  hintText: 'DESCRIPCIÓN O NOTAS IMPORTANTES...',
                  uppercase: true,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Cancelar',
                        variant: AppButtonVariant.outlined,
                        size: AppButtonSize.compact,
                        borderRadius: 9,
                        isFullWidth: true,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        text: 'Guardar',
                        icon: Icons.check_rounded,
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.compact,
                        borderRadius: 9,
                        isFullWidth: true,
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Diálogo compacto para cambiar el estado operativo del proyecto.
class ChangeProjectStatusDialog extends StatelessWidget {
  final String currentStatus;
  final List<String> options;

  const ChangeProjectStatusDialog({
    super.key,
    required this.currentStatus,
    required this.options,
  });

  static Future<String?> show(
    BuildContext context, {
    required String currentStatus,
    required List<String> options,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => ChangeProjectStatusDialog(
        currentStatus: currentStatus,
        options: options,
      ),
    );
  }

  IconData _iconFor(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return Icons.play_circle_outline_rounded;
      case 'terminado':
        return Icons.task_alt_rounded;
      case 'cancelado':
        return Icons.cancel_outlined;
      default:
        return Icons.flag_outlined;
    }
  }

  Color _colorFor(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return const Color(0xFF16A34A);
      case 'terminado':
        return const Color(0xFF2563EB);
      case 'cancelado':
        return const Color(0xFFDC2626);
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Cambiar Estado del Proyecto',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Estado actual: $currentStatus',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Divider(height: 18, color: Color(0xFFE2E8F0)),
              ...options.map((estado) {
                final color = _colorFor(estado);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(estado),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(_iconFor(estado), size: 18, color: color),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                estado,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: color,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 4),
              AppButton(
                text: 'Cancelar',
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.compact,
                borderRadius: 9,
                isFullWidth: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
