import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../providers/compras_report_provider.dart';
import '../widgets/compras_table.dart';
import '../widgets/compra_detail_panel.dart';
import '../widgets/compras_filter_sheet.dart';
import '../widgets/compras_summary_footer.dart';
import '../../../widgets/quick_date_filter.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ComprasReportProvider>(context);
    final width = MediaQuery.of(context).size.width;
    final isLargeScreen = width > 950;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        title: const Text(
          'Registro de Compras',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          QuickDateFilter(
            selectedOption: provider.selectedDateFilter,
            onChanged: provider.setDateFilter,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Imprimir Reporte PDF',
            onPressed: () async {
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
                    const SnackBar(
                      content: Text('No se pudo generar el reporte PDF'),
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.loadData,
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _showFilterBottomSheet(context),
            icon: Icon(
              provider.isFilterActive
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
              color: provider.isFilterActive
                  ? Colors.black
                  : Colors.grey.shade700,
              size: 18,
            ),
            label: Text(
              'Filtrar',
              style: TextStyle(
                color: provider.isFilterActive
                    ? Colors.black
                    : Colors.grey.shade700,
                fontWeight: provider.isFilterActive
                    ? FontWeight.bold
                    : FontWeight.w500,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: provider.isFilterActive
                    ? Colors.black
                    : Colors.grey.shade300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: provider.isLoading && provider.compras.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : Column(
              children: [
                _buildFilterChips(context, provider),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ComprasTable(
                          isLargeScreen: isLargeScreen,
                          onRowTap: (id) {
                            provider.selectCompra(id);
                            if (!isLargeScreen) {
                              _showDetailBottomSheet(context);
                            }
                          },
                        ),
                      ),
                      if (isLargeScreen)
                        const Padding(
                          padding: EdgeInsets.only(
                            top: 16.0,
                            right: 24.0,
                            bottom: 16.0,
                          ),
                          child: SizedBox(
                            width: 460,
                            child: CompraDetailPanel(isBottomSheet: false),
                          ),
                        ),
                    ],
                  ),
                ),
                const ComprasSummaryFooter(),
              ],
            ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 600),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: Provider.of<ComprasReportProvider>(context, listen: false),
          child: const ComprasFilterSheet(),
        );
      },
    );
  }

  void _showDetailBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 600),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: CompraDetailPanel(isBottomSheet: true),
                ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Filtros activos: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.blueGrey,
              ),
            ),
          ),

          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                if (provider.searchController.text.isNotEmpty)
                  Chip(
                    label: Text(
                      'Buscar: "${provider.searchController.text}"',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onDeleted: () {
                      provider.updateSearchQuery('');
                      provider.searchController.clear();
                    },
                    deleteIcon: const Icon(Icons.close, size: 14),
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                if (provider.selectedProyecto != null)
                  Chip(
                    label: Text(
                      'Proyecto: ${provider.selectedProyecto!.nombre}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onDeleted: () {
                      provider.setProyecto(null);
                    },
                    deleteIcon: const Icon(Icons.close, size: 14),
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                if (provider.selectedProveedor != null)
                  Chip(
                    label: Text(
                      'Proveedor: ${provider.selectedProveedor!.name}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onDeleted: () {
                      provider.setProveedor(null);
                    },
                    deleteIcon: const Icon(Icons.close, size: 14),
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                if (provider.selectedEstado != null)
                  Chip(
                    label: Text(
                      'Estado: ${provider.selectedEstado}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onDeleted: () {
                      provider.setEstado(null);
                    },
                    deleteIcon: const Icon(Icons.close, size: 14),
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                if (provider.selectedDateRange != null)
                  Chip(
                    label: Text(
                      'Fechas: ${DateFormat('dd/MM/yy').format(provider.selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(provider.selectedDateRange!.end)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onDeleted: () {
                      provider.setDateRange(null);
                    },
                    deleteIcon: const Icon(Icons.close, size: 14),
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                TextButton(
                  onPressed: provider.clearFilters,
                  child: const Text(
                    'Limpiar todo',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
