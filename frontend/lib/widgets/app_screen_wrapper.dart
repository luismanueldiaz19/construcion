import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Define el modo de visualización de la pantalla.
enum AppScreenMode {
  /// Se adapta automáticamente según el ancho de pantalla (breakpoint por defecto: 850px).
  auto,

  /// Fuerza el modo Escritorio (tablas, layout horizontal, barra completa).
  desktop,

  /// Fuerza el modo Móvil / Compacto (tarjetas, scroll vertical, controles adaptativos).
  mobile,
}

/// Contenedor global estandarizado para envolver pantallas del sistema Neo Project ERP.
///
/// Proporciona soporte nativo para 2 modos de pantalla (Escritorio y Móvil),
/// estandariza encabezados, filtros, acciones principales y estados de carga/error
/// cumpliendo estrictamente con las skills de interfaz compacta y código limpio.
class AppScreenWrapper extends StatelessWidget {
  /// Título principal de la pantalla.
  final String title;

  /// Subtítulo o texto de soporte (ej. "Total: 15 registros" o breadcrumbs).
  final String? subtitle;

  /// Botones de acción principales (ej. "Nuevo Registro", "Exportar", "Refrescar").
  final List<Widget>? actions;

  /// Barra de filtros o búsqueda horizontal situada debajo del título.
  final Widget? filterBar;

  /// Vista optimizada para pantalla ancha / escritorio (ej. tablas, columnas).
  final Widget desktopView;

  /// Vista optimizada para pantalla estrecha / móvil (ej. tarjetas, lista vertical).
  /// Si no se suministra, adapta la [desktopView] dentro de un scroll horizontal de respaldo.
  final Widget? mobileView;

  /// Indicador de estado de carga global de la pantalla.
  final bool isLoading;

  /// Mensaje de error para mostrar un aviso amigable en lugar del contenido.
  final String? errorMessage;

  /// Callback para reintentar la operación en caso de error.
  final VoidCallback? onRetry;

  /// Modo forzado de visualización o detección automática.
  final AppScreenMode mode;

  /// Breakpoint en píxeles para alternar entre móvil y escritorio (por defecto 850).
  final double breakpoint;

  /// Padding interno general del contenido (por defecto adaptativo: 14px en desktop, 10px en móvil).
  final EdgeInsetsGeometry? contentPadding;

  const AppScreenWrapper({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.filterBar,
    required this.desktopView,
    this.mobileView,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.mode = AppScreenMode.auto,
    this.breakpoint = 850.0,
    this.contentPadding,
  });

  bool _isMobile(BuildContext context) {
    if (mode == AppScreenMode.mobile) return true;
    if (mode == AppScreenMode.desktop) return false;
    return MediaQuery.of(context).size.width < breakpoint;
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = _isMobile(context);
    final EdgeInsetsGeometry effectivePadding = contentPadding ??
        EdgeInsets.symmetric(
          horizontal: isMobile ? 12.0 : 16.0,
          vertical: isMobile ? 10.0 : 14.0,
        );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: effectivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ScreenHeader(
                title: title,
                subtitle: subtitle,
                actions: actions,
                isMobile: isMobile,
              ),
              if (filterBar != null) ...[
                const SizedBox(height: 10),
                filterBar!,
              ],
              const SizedBox(height: 12),
              Expanded(
                child: _buildBody(context, isMobile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isMobile) {
    if (isLoading) {
      return const _LoadingView();
    }

    if (errorMessage != null) {
      return _ErrorView(
        message: errorMessage!,
        onRetry: onRetry,
      );
    }

    if (isMobile) {
      if (mobileView != null) {
        return mobileView!;
      }
      // Fallback seguro: scroll horizontal para evitar overflow de desktopView
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: breakpoint,
          child: desktopView,
        ),
      );
    }

    return desktopView;
  }
}

/// Encabezado estandarizado con tipografía compacta y botones con altura cómoda (36px).
class _ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool isMobile;

  const _ScreenHeader({
    required this.title,
    this.subtitle,
    this.actions,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final titleWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 12.0,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ],
    );

    if (actions == null || actions!.isEmpty) {
      return titleWidget;
    }

    // Regla obligatoria flutter-small-widgets: asegurar que los botones
    // de acción tengan una altura mínima de 36px y nunca queden aplastados.
    final formattedActions = actions!.map((action) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 36.0),
        child: action,
      );
    }).toList();

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          titleWidget,
          const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: formattedActions,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleWidget),
        const SizedBox(width: 16),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: formattedActions,
        ),
      ],
    );
  }
}

/// Vista compacta de carga para no desfasar la interfaz.
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Cargando datos...',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner amigable de error con botón de reintento.
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorView({
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.red.shade400),
            const SizedBox(height: 10),
            const Text(
              'Ocurrió un inconveniente',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
