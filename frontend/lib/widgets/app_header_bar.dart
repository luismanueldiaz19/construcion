import 'package:flutter/material.dart';

/// Barra de encabezado superior (AppBar / Header) estandarizada para Neo Project ERP.
/// Basada en el diseño visual de cabecera con badge rojo ('N'), título destacado,
/// subtítulo descriptivo y soporte para acciones a la derecha.
///
/// Puede utilizarse tanto directamente como `appBar` en un [Scaffold]
/// (implementa [PreferredSizeWidget]) o como widget de encabezado inline.
class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  /// Título principal (ej: "NEO PROJECT", "PROYECTOS", "COMPRAS Y GASTOS").
  final String title;

  /// Subtítulo descriptivo (ej: "ERP Constructora · RD").
  final String? subtitle;

  /// Letra que se muestra dentro del badge rojo redondeado (por defecto "N").
  final String badgeLetter;

  /// Color de fondo del badge del logo (por defecto rojo corporativo #E31E24).
  final Color badgeColor;

  /// Widget personalizado para sustituir el badge rojo si se desea un logo o ícono.
  final Widget? leadingWidget;

  /// Botón de retroceso opcional o acción líder (ej. abrir drawer).
  final VoidCallback? onBack;

  /// Si es true, muestra un botón de menú tipo hamburguesa a la izquierda para abrir el Drawer.
  final bool showMenuButton;

  /// Callback opcional para abrir el Drawer. Si es nulo y showMenuButton es true,
  /// intentará abrir el Drawer del Scaffold automáticamente.
  final VoidCallback? onMenuPressed;

  /// Acciones opcionales a la derecha.
  final List<Widget>? actions;

  /// Altura total de la barra (por defecto 90px).
  final double height;

  /// Color de fondo principal (por defecto oscuro pizarra #0F172A).
  final Color? backgroundColor;

  const AppHeaderBar({
    super.key,
    this.title = 'NEO PROJECT',
    this.subtitle = 'ERP Constructora · RD',
    this.badgeLetter = 'N',
    this.badgeColor = const Color(0xFFE31E24),
    this.leadingWidget,
    this.onBack,
    this.showMenuButton = true,
    this.onMenuPressed,
    this.actions,
    this.height = 90.0,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF0F172A),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF1E293B), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Botón de retroceso si fue provisto
              if (onBack != null) ...[
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: Colors.white70,
                  ),
                  onPressed: onBack,
                ),
                const SizedBox(width: 6),
              ] else if (showMenuButton) ...[
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: const Icon(
                    Icons.menu_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  tooltip: 'Menú lateral',
                  onPressed: onMenuPressed ??
                      () => Scaffold.maybeOf(context)?.openDrawer(),
                ),
                const SizedBox(width: 8),
              ],

              // Badge rojo redondeado con letra 'N' (o leadingWidget)
              GestureDetector(
                onTap: () {
                  if (onMenuPressed != null) {
                    onMenuPressed!();
                  } else {
                    Scaffold.maybeOf(context)?.openDrawer();
                  }
                },
                child: leadingWidget ??
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: badgeColor.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badgeLetter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
              ),
              const SizedBox(width: 12),

              // Bloque de Título y Subtítulo
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 1.5),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Acciones opcionales a la derecha
              ...?actions,
            ],
          ),
        ),
      ),
    );
  }
}
