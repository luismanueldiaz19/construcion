import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_theme.dart';
import '../../../../models/compra.dart';
import '../../purchases/providers/compras_report_provider.dart';

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
    final f = NumberFormat.currency(symbol: '\$');

    if (provider.compras.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No se encontraron compras con los filtros seleccionados.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.compras.length,
            itemBuilder: (context, index) {
              return _buildCard(
                context,
                provider,
                provider.compras[index],
                f,
              );
            },
          ),
        ),
        _buildPagination(provider),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context,
    ComprasReportProvider provider,
    Compra c,
    NumberFormat f,
  ) {
    final double total = c.total;
    final double subtotal = c.subtotal;
    final bool isSelected =
        provider.selectedCompraDetail != null &&
        provider.selectedCompraDetail!['id'] == c.id;

    Color estadoColor = c.estado == 'Pendiente' ? Colors.orange : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isSelected 
              ? AppTheme.accentColor.withValues(alpha: 0.5) 
              : Colors.blueGrey.withValues(alpha: 0.05),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onRowTap(c.id),
          hoverColor: Colors.blueGrey.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: isLargeScreen
                ? _buildLargeScreenCardContent(c, f, estadoColor)
                : _buildSmallScreenCardContent(c, f, estadoColor),
          ),
        ),
      ),
    );
  }

  Widget _buildLargeScreenCardContent(Compra c, NumberFormat f, Color estadoColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Referencia
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#${c.id} - ${c.tipoCompra}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                c.fecha.split('T')[0],
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              if (c.comprobante != null && c.comprobante!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'NFC: ${c.comprobante}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blueGrey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Participantes
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.proveedor?.name ?? 'N/A',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.folder_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      c.proyecto?.nombre ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Importes
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                f.format(c.total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sub: ${f.format(c.subtotal)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'ITBIS: ${f.format(c.total - c.subtotal)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Estado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: estadoColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: estadoColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            c.estado,
            style: TextStyle(
              color: estadoColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallScreenCardContent(Compra c, NumberFormat f, Color estadoColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '#${c.id} - ${c.tipoCompra}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: estadoColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: estadoColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                c.estado,
                style: TextStyle(
                  color: estadoColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          c.proveedor?.name ?? 'N/A',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.folder_outlined, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                c.proyecto?.nombre ?? 'N/A',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (c.comprobante != null && c.comprobante!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'NFC: ${c.comprobante}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blueGrey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  c.fecha.split('T')[0],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Sub: ${f.format(c.subtotal)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  'ITBIS: ${f.format(c.total - c.subtotal)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  f.format(c.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPagination(ComprasReportProvider provider) {
    if (provider.lastPage <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: provider.currentPage > 1
                ? () {
                    provider.setPage(provider.currentPage - 1);
                  }
                : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'Página ${provider.currentPage} de ${provider.lastPage}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: provider.currentPage < provider.lastPage
                ? () {
                    provider.setPage(provider.currentPage + 1);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
