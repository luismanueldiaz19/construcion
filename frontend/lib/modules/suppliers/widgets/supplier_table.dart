import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_theme.dart';
import '../../../../models/proveedor.dart';
import '../../../../widgets/app_card.dart';
import '../../../../widgets/app_data_table.dart';
import '../providers/suppliers_provider.dart';

/// Tabla de proveedores enriquecida con columnas de contacto y teléfono,
/// sin columna de estado para evitar desbordamientos, y paginación ultra-compacta.
class SupplierTable extends StatefulWidget {
  final Function(Proveedor) onEdit;
  final Proveedor? selectedProveedor;

  const SupplierTable({
    super.key,
    required this.onEdit,
    this.selectedProveedor,
  });

  @override
  State<SupplierTable> createState() => _SupplierTableState();
}

class _SupplierTableState extends State<SupplierTable> {
  int _currentPage = 0;
  final int _rowsPerPage = 15;

  Color _getClassificationColor(String classification) {
    final lower = classification.toLowerCase();
    if (lower == 'excelente' || lower == 'bueno') {
      return const Color(0xFF16A34A);
    }
    if (lower == 'regular') {
      return const Color(0xFFEA580C);
    }
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SuppliersProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final proveedores = provider.filteredProveedores;

        if (proveedores.isEmpty) {
          return AppCard(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.domain_disabled_rounded,
                    size: 36,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No se encontraron proveedores',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Intente ajustar los filtros de búsqueda o registre un nuevo proveedor.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Cálculos de paginación
        final int totalItems = proveedores.length;
        final int totalPages = (totalItems / _rowsPerPage).ceil();
        if (_currentPage >= totalPages && totalPages > 0) {
          _currentPage = totalPages - 1;
        }

        final int startIndex = _currentPage * _rowsPerPage;
        final int endIndex = (startIndex + _rowsPerPage > totalItems)
            ? totalItems
            : startIndex + _rowsPerPage;
        final List<Proveedor> pageItems = proveedores.sublist(
          startIndex,
          endIndex,
        );

        // Cálculos para la fila de Totales
        final double totalCreditLimitOnPage = pageItems
            .where((p) => p.allowCredit)
            .fold<double>(0.0, (sum, p) => sum + p.creditLimit);
        final int creditCountOnPage = pageItems
            .where((p) => p.allowCredit)
            .length;
        final f = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);

        // Filas cebra construidas como TableRow
        final rows = pageItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isOdd = index.isOdd;
          final isSelected = widget.selectedProveedor?.id == item.id;
          final colorClasif = _getClassificationColor(item.classification);

          // Teléfono prioritario (fijo, móvil o whatsapp)
          final String telefono =
              (item.phone != null && item.phone!.trim().isNotEmpty)
              ? item.phone!
              : ((item.mobile != null && item.mobile!.trim().isNotEmpty)
                    ? item.mobile!
                    : ((item.whatsapp != null &&
                              item.whatsapp!.trim().isNotEmpty)
                          ? item.whatsapp!
                          : 'N/A'));

          // Contacto prioritario
          final String contacto =
              (item.contactName != null && item.contactName!.trim().isNotEmpty)
              ? item.contactName!
              : ((item.email != null && item.email!.trim().isNotEmpty)
                    ? item.email!
                    : 'N/A');

          return TableRow(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accentColor.withValues(alpha: 0.08)
                  : (isOdd ? const Color(0xFFF8FAFC) : Colors.white),
              border: const Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9), width: 0.8),
              ),
            ),
            children: [
              // 1. CÓDIGO (Discreto y secundario para no competir con el nombre)
              AppDataTable.buildTextCell(
                item.code ?? 'S/C',
                align: TextAlign.left,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),

              // 2. PROVEEDOR (Nombre principal destacado en negrita y alto contraste)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 4.5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: item.active
                            ? const Color(0xFF0F172A)
                            : Colors.grey.shade500,
                        letterSpacing: 0.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.commercialName != null &&
                        item.commercialName!.isNotEmpty) ...[
                      Text(
                        item.commercialName!,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // 3. RNC / CÉDULA
              AppDataTable.buildTextCell(
                item.rnc ?? 'N/A',
                style: TextStyle(
                  fontSize: 10.5,
                  color: (item.rnc != null && item.rnc != 'N/A')
                      ? const Color(0xFF334155)
                      : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),

              // 4. TELÉFONO
              AppDataTable.buildTextCell(
                telefono,
                style: TextStyle(
                  fontSize: 10.5,
                  color: telefono != 'N/A'
                      ? const Color(0xFF0284C7)
                      : const Color(0xFF94A3B8),
                  fontWeight: telefono != 'N/A'
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),

              // 5. CONTACTO
              AppDataTable.buildTextCell(
                contacto,
                style: TextStyle(
                  fontSize: 10.5,
                  color: contacto != 'N/A'
                      ? const Color(0xFF475569)
                      : const Color(0xFF94A3B8),
                ),
              ),

              // 6. TIPO
              AppDataTable.buildTextCell(
                item.type == 'persona_fisica' ? 'Persona Física' : 'Empresa',
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),

              // 7. CLASIFICACIÓN
              AppDataTable.buildBadgeCell(
                item.classification.toUpperCase(),
                color: colorClasif,
              ),

              // 8. LÍMITE CRÉDITO (Azul vibrante sólo si tiene crédito real > 0)
              (item.allowCredit && item.creditLimit > 0)
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 3.5,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            f.format(item.creditLimit),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          Text(
                            '${item.creditDays}d plazo',
                            style: const TextStyle(
                              fontSize: 9.0,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  : AppDataTable.buildTextCell(
                      item.allowCredit ? 'RD\$ 0.00' : 'Sin Crédito',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                      ),
                    ),

              // 9. ACCIÓN (Editar)
              Center(
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 26,
                    minHeight: 26,
                  ),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 15,
                    color: Color(0xFF64748B),
                  ),
                  tooltip: 'Editar proveedor',
                  onPressed: () => widget.onEdit(item),
                ),
              ),
            ],
          );
        }).toList();

        // Fila de Total inferior alineada con las 9 columnas
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
            AppDataTable.buildTextCell(
              '${pageItems.length} proveedores',
              align: TextAlign.left,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            AppDataTable.buildTextCell('-'),
            AppDataTable.buildTextCell('-'),
            AppDataTable.buildTextCell('-'),
            AppDataTable.buildTextCell('-'),
            AppDataTable.buildTextCell(
              '$creditCountOnPage con créd.',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
            AppDataTable.buildTextCell(
              f.format(totalCreditLimitOnPage),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(),
          ],
        );

        return AppDataTable(
          expand: false,
          minWidth: 840,
          columnWidths: const {
            0: FlexColumnWidth(1.0), // CÓDIGO
            1: FlexColumnWidth(2.5), // PROVEEDOR
            2: FlexColumnWidth(1.2), // RNC / CÉDULA
            3: FlexColumnWidth(1.2), // TELÉFONO
            4: FlexColumnWidth(1.3), // CONTACTO
            5: FlexColumnWidth(1.1), // TIPO
            6: FlexColumnWidth(1.1), // CLASIFICACIÓN
            7: FlexColumnWidth(1.4), // LÍMITE CRÉDITO
            8: FixedColumnWidth(38), // ACCIÓN
          },
          headers: [
            AppDataTable.buildHeaderCell('CÓDIGO', align: TextAlign.left),
            AppDataTable.buildHeaderCell('PROVEEDOR', align: TextAlign.left),
            AppDataTable.buildHeaderCell('RNC / CÉDULA'),
            AppDataTable.buildHeaderCell('TELÉFONO'),
            AppDataTable.buildHeaderCell('CONTACTO'),
            AppDataTable.buildHeaderCell('TIPO'),
            AppDataTable.buildHeaderCell('CLASIFICACIÓN'),
            AppDataTable.buildHeaderCell('LÍMITE CRÉDITO'),
            AppDataTable.buildHeaderCell('VER'),
          ],
          rows: rows,
          totalRow: totalRow,
          paginationBar: totalPages > 1
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 26,
                          minHeight: 26,
                        ),
                        icon: const Icon(Icons.chevron_left_rounded, size: 20),
                        onPressed: _currentPage > 0
                            ? () => setState(() => _currentPage--)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Página ${_currentPage + 1} de $totalPages',
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
                        constraints: const BoxConstraints(
                          minWidth: 26,
                          minHeight: 26,
                        ),
                        icon: const Icon(Icons.chevron_right_rounded, size: 20),
                        onPressed: _currentPage < totalPages - 1
                            ? () => setState(() => _currentPage++)
                            : null,
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }
}
