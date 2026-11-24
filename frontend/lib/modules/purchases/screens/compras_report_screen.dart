import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_screen_wrapper.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/quick_date_filter.dart';
import '../providers/compras_report_provider.dart';
import '../widgets/compras_table.dart';
import '../widgets/compra_detail_panel.dart';
import '../widgets/compras_filter_sheet.dart';
import '../widgets/compras_summary_footer.dart';

class ComprasReportScreen extends StatelessWidget {
  const ComprasReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ComprasReportProvider(),
      child: const _ComprasReportScreenContent(),
    );
  }
}

class _ComprasReportScreenContent extends StatelessWidget {
  const _ComprasReportScreenContent();

  Future<void> _exportPdf(BuildContext context, ComprasReportProvider provider) async {
    String query = '?';
    if (provider.selectedProyecto != null) {
      query += 'proyecto_id=${provider.selectedProyecto!.id}&';
    }
    if (provider.selectedProveedor != null) {
      query += 'proveedor_id=${provider.selectedProveedor!.id}&';
    }
    if (provider.selectedEstado != null &&
        provider.selectedEstado != 'Todos') {
      query += 'estado=${provider.selectedEstado}&';
    }
    if (provider.selectedDateRange != null) {
      query +=
          'fecha_inicio=${DateFormat('yyyy-MM-dd').format(provider.selectedDateRange!.start)}&';
      query +=
          'fecha_fin=${DateFormat('yyyy-MM-dd').format(provider.selectedDateRange!.end)}&';
    }

    final url = Uri.parse('$host/reports/compras/pdf$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo generar el reporte PDF')),
        );
      }
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    ComprasFilterSheet.show(context);
  }

  void _showDetailBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: Provider.of<ComprasReportProvider>(context, listen: false),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: const SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: CompraDetailPanel(isBottomSheet: true),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    ComprasReportProvider provider,
  ) {
    if (!provider.isFilterActive) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Filtros Activos:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 6.0,
            runSpacing: 4.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (provider.searchController.text.isNotEmpty)
                _buildMiniChip(
                  'Buscar: "${provider.searchController.text}"',
                  () {
                    provider.updateSearchQuery('');
                    provider.searchController.clear();
                  },
                ),
              if (provider.selectedProyecto != null)
                _buildMiniChip(
                  'Proyecto: ${provider.selectedProyecto!.nombre}',
                  () => provider.setProyecto(null),
                ),
              if (provider.selectedProveedor != null)
                _buildMiniChip(
                  'Proveedor: ${provider.selectedProveedor!.name}',
                  () => provider.setProveedor(null),
                ),
              if (provider.selectedEstado != null)
                _buildMiniChip(
                  'Estado: ${provider.selectedEstado}',
                  () => provider.setEstado(null),
                ),
              if (provider.selectedDateRange != null)
                _buildMiniChip(
                  'Fechas: ${DateFormat('dd/MM/yy').format(provider.selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(provider.selectedDateRange!.end)}',
                  () => provider.setDateRange(null),
                ),
            ],
          ),
        ),
        TextButton(
          onPressed: provider.clearFilters,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 24),
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
          child: const Text(
            'Limpiar todo',
            style: TextStyle(color: Colors.red, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniChip(String label, VoidCallback onDeleted) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 10)),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close, size: 12),
      backgroundColor: Colors.blue.shade50,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: Colors.blue.shade200, width: 0.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ComprasReportProvider>(context);
    final count = provider.compras.length;

    return AppScreenWrapper(
      title: 'Registro de Compras',
      subtitle: '$count compras registradas',
      actions: [
        // Filtro de fecha rápida
        QuickDateFilter(
          selectedOption: provider.selectedDateFilter,
          onChanged: provider.setDateFilter,
        ),
        const SizedBox(width: 8),

        // Buscador compacto de comprobante
        SizedBox(
          width: 190,
          child: AppTextField(
            controller: provider.searchController,
            hintText: 'Buscar comprobante...',
            prefixIconData: Icons.search_rounded,
            borderRadius: 8,
            onChanged: (val) => provider.updateSearchQuery(val),
            suffixIcon: provider.searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                    onPressed: () {
                      provider.searchController.clear();
                      provider.loadData();
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(width: 6),

        // Exportar PDF
        IconButton(
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
          tooltip: 'Imprimir Reporte PDF',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () => _exportPdf(context, provider),
        ),

        // Recargar
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20),
          tooltip: 'Recargar datos',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: provider.loadData,
        ),
        const SizedBox(width: 6),

        // Botón Filtrar
        AppButton(
          text: 'Filtrar',
          icon: Icons.tune_rounded,
          variant: provider.isFilterActive
              ? AppButtonVariant.primary
              : AppButtonVariant.outlined,
          size: AppButtonSize.compact,
          onPressed: () => _showFilterBottomSheet(context),
        ),
      ],
      filterBar: _buildFilterChips(context, provider),
      // Modo 1: Escritorio - Tabla a la izquierda y panel de detalle a la derecha
      desktopView: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tabla ultra-compacta
                Expanded(
                  child: ComprasTable(
                    isLargeScreen: true,
                    onRowTap: (id) => provider.selectCompra(id),
                  ),
                ),

                // Panel lateral de detalle sólo si hay selección
                if (provider.selectedCompraDetail != null) ...[
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 420,
                    child: CompraDetailPanel(isBottomSheet: false),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          const ComprasSummaryFooter(),
        ],
      ),
      // Modo 2: Móvil - Tabla adaptable con apertura de detalle en BottomSheet
      mobileView: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ComprasTable(
              isLargeScreen: false,
              onRowTap: (id) {
                provider.selectCompra(id);
                _showDetailBottomSheet(context);
              },
            ),
          ),
          const SizedBox(height: 8),
          const ComprasSummaryFooter(),
        ],
      ),
    );
  }
}
