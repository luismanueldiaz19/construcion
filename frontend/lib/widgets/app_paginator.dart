import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Paginador corporativo para tablas basado en el diseño ergonómico de mecael.
///
/// Incluye selector de filas por página, contador descriptivo ("Mostrando X - Y de Z"),
/// botones de primera/última página y burbuja indicadora de página activa.
class AppPaginator extends StatelessWidget {
  final int currentPage;
  final int totalItems;
  final int rowsPerPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int>? onRowsPerPageChanged;
  final List<int> rowsPerPageOptions;

  const AppPaginator({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.rowsPerPage,
    required this.onPageChanged,
    this.onRowsPerPageChanged,
    this.rowsPerPageOptions = const [10, 25, 50],
  });

  @override
  Widget build(BuildContext context) {
    final int totalPages = (totalItems / rowsPerPage).ceil();
    final int displayTotalPages = totalPages == 0 ? 1 : totalPages;

    final int startItem =
        totalItems == 0 ? 0 : (currentPage - 1) * rowsPerPage + 1;
    final int endItem = (currentPage * rowsPerPage) > totalItems
        ? totalItems
        : (currentPage * rowsPerPage);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Selector de filas por página
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filas por página: ',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (onRowsPerPageChanged != null)
                DropdownButton<int>(
                  value: rowsPerPage,
                  isDense: true,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  items: rowsPerPageOptions.map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(
                        '$value',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      onRowsPerPageChanged!(newValue);
                    }
                  },
                )
              else
                Text(
                  '$rowsPerPage',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
            ],
          ),

          // 2. Texto de rango de registros
          Text(
            'Mostrando $startItem - $endItem de $totalItems',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),

          // 3. Botones de paginación con burbuja
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Primera página
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                icon: const Icon(Icons.first_page_rounded, size: 18),
                onPressed: currentPage > 1 ? () => onPageChanged(1) : null,
                tooltip: 'Primera página',
              ),
              const SizedBox(width: 4),

              // Página anterior
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
                tooltip: 'Página anterior',
              ),
              const SizedBox(width: 8),

              // Burbuja indicadora de página
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$currentPage / $displayTotalPages',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Siguiente página
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                onPressed: currentPage < totalPages
                    ? () => onPageChanged(currentPage + 1)
                    : null,
                tooltip: 'Siguiente página',
              ),
              const SizedBox(width: 4),

              // Última página
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                icon: const Icon(Icons.last_page_rounded, size: 18),
                onPressed: currentPage < totalPages
                    ? () => onPageChanged(totalPages)
                    : null,
                tooltip: 'Última página',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
