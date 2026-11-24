import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Tipos de alerta soportados por el sistema de diseño.
enum AppAlertType {
  error,
  success,
  warning,
  info,
}

/// Componente universal de alerta:
/// 1. Puede renderizarse como un Banner en el formulario.
/// 2. Proporciona un método estático [AppAlert.showToast] para notificaciones flotantes (SnackBars).
class AppAlert extends StatelessWidget {
  final String message;
  final String? title;
  final AppAlertType type;
  final VoidCallback? onClose;
  final bool isDark;

  const AppAlert({
    super.key,
    required this.message,
    this.title,
    this.type = AppAlertType.info,
    this.onClose,
    this.isDark = false,
  });

  Color _getBaseColor() {
    switch (type) {
      case AppAlertType.error:
        return const Color(0xFFEA4335);
      case AppAlertType.success:
        return const Color(0xFF34A853);
      case AppAlertType.warning:
        return const Color(0xFFFBBC04);
      case AppAlertType.info:
        return const Color(0xFF1A73E8);
    }
  }

  IconData _getIconData() {
    switch (type) {
      case AppAlertType.error:
        return Icons.error_outline_rounded;
      case AppAlertType.success:
        return Icons.check_circle_outline_rounded;
      case AppAlertType.warning:
        return Icons.warning_amber_rounded;
      case AppAlertType.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _getBaseColor();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: baseColor.withValues(alpha: isDark ? 0.35 : 0.40),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(_getIconData(), color: baseColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      color: baseColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: TextStyle(
                    color: isDark ? Colors.white.withValues(alpha: 0.9) : AppTheme.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.close, size: 16, color: baseColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Muestra una notificación flotante estilo toast/snackbar de manera centralizada.
  static void showToast(
    BuildContext context,
    String message, {
    AppAlertType type = AppAlertType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    Color baseColor;
    IconData icon;

    switch (type) {
      case AppAlertType.error:
        baseColor = const Color(0xFFEA4335);
        icon = Icons.error_outline_rounded;
        break;
      case AppAlertType.success:
        baseColor = const Color(0xFF34A853);
        icon = Icons.check_circle_outline_rounded;
        break;
      case AppAlertType.warning:
        baseColor = const Color(0xFFFBBC04);
        icon = Icons.warning_amber_rounded;
        break;
      case AppAlertType.info:
        baseColor = const Color(0xFF1A73E8);
        icon = Icons.info_outline_rounded;
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A1C1E),
        elevation: 6,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: baseColor.withValues(alpha: 0.6), width: 1),
        ),
        content: Row(
          children: [
            Icon(icon, color: baseColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
