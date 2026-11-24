import 'package:flutter/material.dart';
import 'app_card.dart';

export 'app_paginator.dart';

/// Componente de tabla full-width responsiva basado en la arquitectura de mecael.
///
/// Utiliza el widget [Table] nativo de Flutter con [TableColumnWidth] (como [FlexColumnWidth]),
/// cabecera pizarra suave (#F8FAFC), filas alternas cebra y fila inferior de totales.
/// Posee margen interno respecto al contenedor [AppCard] y su propio borde redondeado
/// con [Clip.antiAlias] para evitar desbordes o aspecto "esquineado" al hacer scroll.
class AppDataTable extends StatefulWidget {
  final double minWidth;
  final Map<int, TableColumnWidth> columnWidths;
  final List<Widget> headers;
  final List<TableRow> rows;
  final TableRow? totalRow;
  final Widget? paginationBar;
  final Widget? emptyState;
  final bool expand;
  final EdgeInsetsGeometry padding;

  const AppDataTable({
    super.key,
    required this.columnWidths,
    required this.headers,
    required this.rows,
    this.totalRow,
    this.paginationBar,
    this.emptyState,
    this.minWidth = 750,
    this.expand = true,
    this.padding = const EdgeInsets.all(12),
  });

  /// Helper para celdas de cabecera con estilo corporativo mecael
  static Widget buildHeaderCell(
    String text, {
    TextAlign align = TextAlign.center,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      child: Text(
        text.toUpperCase(),
        textAlign: align,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
          letterSpacing: 0.2,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Helper para celdas de texto estándar
  static Widget buildTextCell(
    String text, {
    TextAlign align = TextAlign.center,
    TextStyle? style,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6.5),
      child: Text(
        text,
        textAlign: align,
        style: style ?? const TextStyle(fontSize: 11, color: Color(0xFF334155)),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Helper para celdas con píldora/badge métrico
  static Widget buildBadgeCell(
    String text, {
    required Color color,
    TextAlign align = TextAlign.center,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: Align(
        alignment: align == TextAlign.left
            ? Alignment.centerLeft
            : (align == TextAlign.right
                  ? Alignment.centerRight
                  : Alignment.center),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  @override
  State<AppDataTable> createState() => _AppDataTableState();
}

class _AppDataTableState extends State<AppDataTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  Widget _buildTableBox(double? maxHeight) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final effectiveWidth = constraints.maxWidth > widget.minWidth
              ? constraints.maxWidth
              : widget.minWidth;

          return Scrollbar(
            controller: _verticalController,
            thumbVisibility: true,
            notificationPredicate: (notif) => notif.metrics.axis == Axis.vertical,
            child: SingleChildScrollView(
              controller: _verticalController,
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(),
              child: Scrollbar(
                controller: _horizontalController,
                thumbVisibility: true,
                notificationPredicate: (notif) => notif.metrics.axis == Axis.horizontal,
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: effectiveWidth,
                    child: Table(
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      columnWidths: widget.columnWidths,
                      children: [
                        // Cabecera corporativa mecael
                        TableRow(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFFE2E8F0),
                                width: 1.0,
                              ),
                            ),
                          ),
                          children: widget.headers,
                        ),

                        // Filas de datos cebra
                        ...widget.rows,

                        // Fila de Total inferior opcional
                        if (widget.totalRow != null) widget.totalRow!,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty && widget.emptyState != null) {
      return widget.emptyState!;
    }

    return AppCard(
      padding: widget.padding,
      child: widget.expand
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tabla dentro de un contenedor bordeado que completa el alto del card
                Expanded(
                  child: _buildTableBox(null),
                ),

                // Paginador anclado al fondo del card sin espacios en blanco
                if (widget.paginationBar != null) ...[
                  const SizedBox(height: 8),
                  widget.paginationBar!,
                ],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTableBox(null),
                if (widget.paginationBar != null) ...[
                  const SizedBox(height: 8),
                  widget.paginationBar!,
                ],
              ],
            ),
    );
  }
}
