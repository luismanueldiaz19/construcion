import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Variantes visuales para el botón estandarizado del sistema.
enum AppButtonVariant {
  /// Color rojo corporativo (#E31E24), texto blanco y sombra sutil.
  primary,

  /// Color gris oscuro institucional (#1A1C1E).
  secondary,

  /// Botón con borde y fondo transparente.
  outlined,

  /// Color rojo peligro (#EA4335) para acciones destructivas.
  danger,

  /// Color verde (#34A853) para confirmaciones y cobros.
  success,
}

/// Tamaños normalizados para mantener consistencia de densidad visual.
enum AppButtonSize {
  /// Altura 36px, tipografía 13px (ideal para toolbars y tablas).
  compact,

  /// Altura 42px, tipografía 14px (ideal para diálogos y formularios).
  standard,

  /// Altura 50px, tipografía 15px (ideal para login y acciones primarias destacadas).
  large,
}

/// Botón universal reutilizable con indicador de carga integrado y diseño compacto.
class AppButton extends StatelessWidget {
  /// Texto a mostrar en el botón.
  final String text;

  /// Callback al presionar el botón. Si es null o [isLoading] es true, el botón se deshabilita.
  final VoidCallback? onPressed;

  /// Icono opcional que se muestra antes del texto.
  final IconData? icon;

  /// Variante cromática del botón.
  final AppButtonVariant variant;

  /// Tamaño predeterminado del botón.
  final AppButtonSize size;

  /// Si es true, el botón se expande al ancho completo de su contenedor.
  final bool isFullWidth;

  /// Estado de carga. Reemplaza el contenido por un spinner circular elegante.
  final bool isLoading;

  /// Radio de curvatura de los bordes (por defecto 12px).
  final double borderRadius;

  /// Color de fondo personalizado (anula la variante si se especifica).
  final Color? customBackgroundColor;

  /// Color de texto/icono personalizado (anula la variante si se especifica).
  final Color? customTextColor;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.standard,
    this.isFullWidth = false,
    this.isLoading = false,
    this.borderRadius = 12.0,
    this.customBackgroundColor,
    this.customTextColor,
  });

  double get _height {
    switch (size) {
      case AppButtonSize.compact:
        return 36.0;
      case AppButtonSize.standard:
        return 42.0;
      case AppButtonSize.large:
        return 50.0;
    }
  }

  double get _fontSize {
    switch (size) {
      case AppButtonSize.compact:
        return 13.0;
      case AppButtonSize.standard:
        return 14.0;
      case AppButtonSize.large:
        return 15.0;
    }
  }

  double get _iconSize {
    switch (size) {
      case AppButtonSize.compact:
        return 16.0;
      case AppButtonSize.standard:
        return 18.0;
      case AppButtonSize.large:
        return 20.0;
    }
  }

  Color _getBackgroundColor() {
    if (customBackgroundColor != null) return customBackgroundColor!;
    switch (variant) {
      case AppButtonVariant.primary:
        return AppTheme.accentColor;
      case AppButtonVariant.secondary:
        return AppTheme.primaryColor;
      case AppButtonVariant.outlined:
        return Colors.transparent;
      case AppButtonVariant.danger:
        return AppTheme.dangerColor;
      case AppButtonVariant.success:
        return AppTheme.successColor;
    }
  }

  Color _getTextColor() {
    if (customTextColor != null) return customTextColor!;
    switch (variant) {
      case AppButtonVariant.outlined:
        return AppTheme.accentColor;
      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
      case AppButtonVariant.danger:
      case AppButtonVariant.success:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBackgroundColor();
    final textColor = _getTextColor();
    final bool isEnabled = onPressed != null && !isLoading;

    final Widget content = isLoading
        ? SizedBox(
            width: _iconSize + 2,
            height: _iconSize + 2,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == AppButtonVariant.outlined ? bgColor : Colors.white,
              ),
            ),
          )
        : Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: _iconSize, color: textColor),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: _fontSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          );

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: textColor,
      disabledBackgroundColor: bgColor.withValues(alpha: 0.55),
      disabledForegroundColor: textColor.withValues(alpha: 0.7),
      elevation: variant == AppButtonVariant.primary ? 4 : 0,
      shadowColor: variant == AppButtonVariant.primary
          ? AppTheme.accentColor.withValues(alpha: 0.4)
          : Colors.transparent,
      minimumSize: Size(isFullWidth ? double.infinity : 0, _height),
      padding: EdgeInsets.symmetric(
        horizontal: size == AppButtonSize.compact ? 12 : 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: variant == AppButtonVariant.outlined
            ? BorderSide(color: bgColor, width: 1.5)
            : BorderSide.none,
      ),
    );

    return SizedBox(
      height: _height,
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: buttonStyle,
        child: content,
      ),
    );
  }
}
