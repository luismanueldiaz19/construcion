import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'app_button.dart';

/// Diálogo modal estandarizado para confirmaciones del sistema (eliminaciones,
/// anulación de comprobantes, acciones críticas).
///
/// Garantiza un espaciado interno amplio (18-20px) y botones con altura
/// cómoda sin aplastar según las directrices de diseño.
class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;
  final IconData? icon;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirmar',
    this.cancelText = 'Cancelar',
    this.isDestructive = false,
    this.icon,
  });

  /// Método estático de conveniencia para invocar el diálogo y obtener true/false.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    bool isDestructive = false,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AppConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        icon: icon,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIcon = icon ??
        (isDestructive
            ? Icons.delete_forever_rounded
            : Icons.help_outline_rounded);
    final iconColor =
        isDestructive ? AppTheme.dangerColor : AppTheme.accentColor;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 10,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icono temático
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(effectiveIcon, color: iconColor, size: 28),
                ),
              ),
              const SizedBox(height: 14),

              // Título
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Mensaje descriptivo
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),

              // Botones de acción sin aplastar
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: cancelText,
                      onPressed: () => Navigator.of(context).pop(false),
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.compact,
                      borderRadius: 10,
                      isFullWidth: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      text: confirmText,
                      onPressed: () => Navigator.of(context).pop(true),
                      variant: isDestructive
                          ? AppButtonVariant.danger
                          : AppButtonVariant.primary,
                      size: AppButtonSize.compact,
                      borderRadius: 10,
                      isFullWidth: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
