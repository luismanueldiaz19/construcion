import 'package:flutter/material.dart';

/// Tipos de estado predefinidos para mapeo automático de colores.
enum AppStatusType {
  /// Verde: Activo, Pagado, Completado, Aprobado
  active,

  /// Rojo: Inactivo, Cancelado, Anulado, Vencido
  inactive,

  /// Ámbar / Naranja: Pendiente, En Proceso, Borrador
  pending,

  /// Azul: En Tránsito, Facturado, Enviado
  info,

  /// Gris neutro: Sin Asignar, Desconocido
  neutral,
}

/// Chip de estado ultra-compacto conforme a las directrices de diseño.
///
/// Tipografía de 10-11px, esquinas redondeadas tipo píldora y fondo suave.
class AppStatusBadge extends StatelessWidget {
  final String label;
  final AppStatusType type;
  final Color? customColor;
  final IconData? icon;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.type = AppStatusType.active,
    this.customColor,
    this.icon,
  });

  Color _getBaseColor() {
    if (customColor != null) return customColor!;
    switch (type) {
      case AppStatusType.active:
        return const Color(0xFF16A34A); // Verde
      case AppStatusType.inactive:
        return const Color(0xFFDC2626); // Rojo
      case AppStatusType.pending:
        return const Color(0xFFD97706); // Ámbar
      case AppStatusType.info:
        return const Color(0xFF2563EB); // Azul
      case AppStatusType.neutral:
        return const Color(0xFF64748B); // Gris pizarra
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _getBaseColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.5),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: baseColor.withValues(alpha: 0.28),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: baseColor),
            const SizedBox(width: 3.5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: baseColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
