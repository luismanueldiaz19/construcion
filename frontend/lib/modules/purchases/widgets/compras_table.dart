import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_theme.dart';
import '../../../../widgets/app_data_table.dart';
import '../providers/compras_report_provider.dart';

/// Tabla de compras ultra-compacta basada en la arquitectura AppDataTable.
/// Reemplaza las tarjetas grandes por una cuadrícula estandarizada y fluida.
class ComprasTable extends StatelessWidget {
  final bool isLargeScreen;
  final void Function(int) onRowTap;

  const ComprasTable({
    super.key,
    required this.isLargeScreen,
    required this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ComprasReportProvider>(context);
    final f = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);

    if (provider.compras.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 10),
              const Text(
                'No se encontraron compras con los filtros seleccionados.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Intente ajustar el rango de fechas o los filtros de búsqueda.',
                style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final compras = provider.compras;
    final double pageTotal = compras.fold<double>(0.0, (sum, c) => sum + c.total);

    // Filas cebra construidas como TableRow
    final rows = compras.asMap().entries.map((entry) {
      final index = entry.key;
      final c = entry.value;
      final isOdd = index.isOdd;
      final isSelected = provider.selectedCompraDetail != null &&
          provider.selectedCompraDetail!['id'] == c.id;

      final bool isPagado = c.estado.toLowerCase() == 'pagado';
      final Color estadoColor = isPagado
          ? const Color(0xFF16A34A)
          : const Color(0xFFEA580C);

      final String fechaCorta = c.fecha.contains('T')
          ? c.fecha.split('T')[0]
          : c.fecha;

      return TableRow(
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentColor.withValues(alpha: 0.10)
              : (isOdd ? const Color(0xFFF8FAFC) : Colors.white),
          border: const Border(
            bottom: BorderSide(color: Color(0xFFF1F5F9), width: 0.8),
          ),
        ),
        children: [
          // 1. FACTURA
          InkWell(
            onTap: () => onRowTap(c.id),
            child: AppDataTable.buildTextCell(
              '#${c.id}',
              align: TextAlign.left,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),

          // 2. NCF / COMPROBANTE
          InkWell(
            onTap: () => onRowTap(c.id),
            child: AppDataTable.buildTextCell(
              c.comprobante != null && c.comprobante!.isNotEmpty
                  ? c.comprobante!
                  : 'S/C',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: c.comprobante != null && c.comprobante!.isNotEmpty
                    ? const Color(0xFF334155)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ),

          // 3. PROVEEDOR
          InkWell(
            onTap: () => onRowTap(c.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (c.proveedor?.name ?? 'Proveedor no especificado').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (c.proveedor?.commercialName != null &&
                      c.proveedor!.commercialName!.isNotEmpty) ...[
                    Text(
                      c.proveedor!.commercialName!,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 4. PROYECTO
          InkWell(
            onTap: () => onRowTap(c.id),
            child: AppDataTable.buildTextCell(
              c.proyecto?.nombre ?? 'Sin Proyecto',
              align: TextAlign.left,
              style: TextStyle(
                fontSize: 10.5,
                color: c.proyecto != null
                    ? const Color(0xFF475569)
                    : const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // 5. FECHA
          InkWell(
            onTap: () => onRowTap(c.id),
            child: AppDataTable.buildTextCell(
              fechaCorta,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF64748B),
              ),
            ),
          ),

          // 6. TIPO
          InkWell(
            onTap: () => onRowTap(c.id),
            child: AppDataTable.buildTextCell(
              c.tipoCompra,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
              ),
            ),
          ),

          // 7. TOTAL (Azul vibrante)
          InkWell(
            onTap: () => onRowTap(c.id),
            child: AppDataTable.buildTextCell(
              f.format(c.total),
              align: TextAlign.right,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D4ED8),
              ),
            ),
          ),

          // 8. ESTADO (Píldora)
          InkWell(
            onTap: () => onRowTap(c.id),
            child: AppDataTable.buildBadgeCell(
              c.estado.toUpperCase(),
              color: estadoColor,
            ),
          ),
        ],
      );
    }).toList();

    // Fila inferior de Total consolidada
    final totalRow = TableRow(
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(
          top: BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
        ),
      ),
      children: [
        AppDataTable.buildTextCell(
          'TOTAL',
          align: TextAlign.left,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: 0.3,
          ),
        ),
        AppDataTable.buildTextCell('-'),
        AppDataTable.buildTextCell(
          '${compras.length} compras en pág.',
          align: TextAlign.left,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        AppDataTable.buildTextCell('-'),
        AppDataTable.buildTextCell('-'),
        AppDataTable.buildTextCell('-'),
        AppDataTable.buildTextCell(
          f.format(pageTotal),
          align: TextAlign.right,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1D4ED8),
          ),
        ),
        const SizedBox(),
      ],
    );

    return AppDataTable(
      minWidth: 780,
      columnWidths: const {
        0: FlexColumnWidth(0.9), // FACTURA
        1: FlexColumnWidth(1.2), // NCF / COMPROBANTE
        2: FlexColumnWidth(2.6), // PROVEEDOR
        3: FlexColumnWidth(2.1), // PROYECTO
        4: FlexColumnWidth(1.1), // FECHA
        5: FlexColumnWidth(1.0), // TIPO
        6: FlexColumnWidth(1.4), // TOTAL
        7: FlexColumnWidth(1.1), // ESTADO
      },
      headers: [
        AppDataTable.buildHeaderCell('FACTURA', align: TextAlign.left),
        AppDataTable.buildHeaderCell('NCF / COMPROBANTE'),
        AppDataTable.buildHeaderCell('PROVEEDOR', align: TextAlign.left),
        AppDataTable.buildHeaderCell('PROYECTO', align: TextAlign.left),
        AppDataTable.buildHeaderCell('FECHA'),
        AppDataTable.buildHeaderCell('TIPO'),
        AppDataTable.buildHeaderCell('TOTAL', align: TextAlign.right),
        AppDataTable.buildHeaderCell('ESTADO'),
      ],
      rows: rows,
      totalRow: totalRow,
      paginationBar: provider.lastPage > 1
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    onPressed: provider.currentPage > 1
                        ? () => provider.setPage(provider.currentPage - 1)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Página ${provider.currentPage} de ${provider.lastPage}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    onPressed: provider.currentPage < provider.lastPage
                        ? () => provider.setPage(provider.currentPage + 1)
                        : null,
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
