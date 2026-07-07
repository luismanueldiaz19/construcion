import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';
import '../../services/accounting_service.dart';
import '../../core/constants.dart';
import '../../widgets/quick_date_filter.dart';

class CobrosScreen extends StatefulWidget {
  const CobrosScreen({super.key});

  @override
  State<CobrosScreen> createState() => _CobrosScreenState();
}

class _CobrosScreenState extends State<CobrosScreen> {
  final AccountingService _accountingService = AccountingService();
  List<dynamic> _history = [];
  bool _isLoading = true;
  String _searchQuery = '';
  DateFilterOption _selectedDateFilter = DateFilterOption.todos;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = await _accountingService.getAllPagosHistorial();
      setState(() {
        _history = data.where((item) => item['tipo'] == 'Cobro').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar historial: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteComprobante(int id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar comprobante?'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar el archivo adjunto de este pago? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _accountingService.deleteComprobantePago(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Comprobante eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadHistory();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar comprobante: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> get _filteredHistory {
    // 1. Filtrar por fecha
    final listByDate = _history.where((pago) {
      final dateStr = pago['fecha']?.toString();
      if (dateStr == null) return false;
      final date = DateTime.tryParse(dateStr);
      if (date == null) return false;
      return QuickDateFilter.isDateInFilter(date, _selectedDateFilter);
    }).toList();

    // 2. Filtrar por búsqueda
    if (_searchQuery.isEmpty) return listByDate;
    return listByDate.where((item) {
      final cliente = item['entidad'].toString().toLowerCase();
      final proyecto = item['proyecto'].toString().toLowerCase();
      return cliente.contains(_searchQuery.toLowerCase()) ||
          proyecto.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        title: const Text('Cobros parciales por avance (Historial de Cobros)'),
        actions: [
          IconButton(
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar Historial',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 1000;

          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Buscador de Texto
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Buscar por cliente o proyecto...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                      ),
                      // Buscador de Fecha Rápido
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: QuickDateFilter(
                                selectedOption: _selectedDateFilter,
                                onChanged: (option) {
                                  setState(() {
                                    _selectedDateFilter = option;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Listado de Tarjetas
                      _buildHistoryTab(f),
                    ],
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: SingleChildScrollView(
                    child: _buildSummaryCards(f, isVertical: true),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              _buildSummaryCards(f),
              // Buscador de Texto
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por cliente o proyecto...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              // Buscador de Fecha Rápido
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: QuickDateFilter(
                        selectedOption: _selectedDateFilter,
                        onChanged: (option) {
                          setState(() {
                            _selectedDateFilter = option;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Listado de Tarjetas
              _buildHistoryTab(f),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab(NumberFormat f) {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _filteredHistory.isEmpty
            ? const Center(
                child: Text('No se encontraron cobros registrados.'),
              )
            : Container(
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 60,
                        horizontalMargin: 20,
                        columnSpacing: 28,
                        dividerThickness: 0.5,
                        columns: const [
                          DataColumn(label: Text('TIPO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54))),
                          DataColumn(label: Text('FECHA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54))),
                          DataColumn(label: Text('CLIENTE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54))),
                          DataColumn(label: Text('PROYECTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54))),
                          DataColumn(label: Text('MÉTODO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54))),
                          DataColumn(label: Text('MONTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)), numeric: true),
                          DataColumn(label: Text('ACCIÓN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54))),
                        ],
                        rows: _filteredHistory.map((item) => _buildDataRow(item, f)).toList(),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  DataRow _buildDataRow(dynamic item, NumberFormat f) {
    final pMonto = double.tryParse(item['monto'].toString()) ?? 0;

    return DataRow(
      cells: [
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Ingreso',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            item['fecha'] ?? '',
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
        DataCell(
          Text(
            item['entidad'] ?? 'Sin Cliente',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        DataCell(
          Text(
            item['proyecto'] ?? 'N/A',
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item['metodo_pago'] ?? '',
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ),
        ),
        DataCell(
          Text(
            '+${f.format(pMonto)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
              fontSize: 14,
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item['original'] != null &&
                  item['original']['comprobante_path'] != null) ...[
                IconButton(
                  icon: const Icon(Icons.attachment, color: Colors.blue, size: 20),
                  tooltip: 'Ver Comprobante Original',
                  splashRadius: 20,
                  onPressed: () async {
                    final url = Uri.parse('$host/storage/${item['original']['comprobante_path']}');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  tooltip: 'Eliminar Comprobante',
                  splashRadius: 20,
                  onPressed: () => _confirmDeleteComprobante(item['id']),
                ),
              ],
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.redAccent, size: 20),
                tooltip: 'Ver Recibo PDF',
                splashRadius: 20,
                onPressed: () async {
                  final url = Uri.parse('$host/api/v1/pagos-historial/Cobro/${item['id']}/pdf');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(NumberFormat f, {bool isVertical = false}) {
    double totalIngresos = 0;
    int totalTransacciones = 0;

    for (var item in _history) {
      if (item['tipo'] == 'Cobro') {
        final double monto = double.tryParse(item['monto'].toString()) ?? 0;
        totalIngresos += monto;
        totalTransacciones++;
      }
    }

    final items = [
      _buildSummaryItem(
        'Ingresos Recibidos',
        f.format(totalIngresos),
        Colors.green[700]!,
        Icons.trending_up,
      ),
      _buildSummaryItem(
        'Total Cobros',
        totalTransacciones.toString(),
        Colors.blue[700]!,
        Icons.receipt_long,
      ),
    ];

    if (isVertical) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            items[0],
            const SizedBox(height: 16),
            items[1],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: items[0]),
          const SizedBox(width: 16),
          Expanded(child: items[1]),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
