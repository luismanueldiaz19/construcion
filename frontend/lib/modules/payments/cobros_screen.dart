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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                // Buscador de Fecha Rápido (QuickDateFilter)
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
                // Listado de Tarjetas
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadHistory,
                    child: _filteredHistory.isEmpty
                        ? const Center(
                            child: Text('No se encontraron cobros registrados.'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredHistory.length,
                            itemBuilder: (context, index) {
                              final item = _filteredHistory[index];
                              return _buildCobroCard(item, f);
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCobroCard(dynamic item, NumberFormat f) {
    final pMonto = double.tryParse(item['monto'].toString()) ?? 0;
    final pFecha = DateTime.tryParse(item['fecha'].toString()) ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono Flecha Verde
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_downward,
              size: 20,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(width: 16),
          // Detalles de Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['proyecto'] ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cliente: ${item['entidad'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['metodo_pago']} • ${DateFormat('dd/MM/yyyy').format(pFecha)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // Monto Cobrado
          Text(
            '+${f.format(pMonto)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(width: 16),
          // Adjuntos y PDF
          if (item['original'] != null &&
              item['original']['comprobante_path'] != null) ...[
            IconButton(
              icon: const Icon(
                Icons.attachment,
                color: Colors.blue,
              ),
              tooltip: 'Ver Comprobante Original',
              onPressed: () async {
                final url = Uri.parse(
                  '$host/storage/${item['original']['comprobante_path']}',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              tooltip: 'Eliminar Comprobante',
              onPressed: () => _confirmDeleteComprobante(item['id']),
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf,
              color: Colors.red,
            ),
            tooltip: 'Ver Recibo PDF',
            onPressed: () async {
              final url = Uri.parse(
                '$host/api/v1/pagos-historial/Cobro/${item['id']}/pdf',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(
                  url,
                  mode: LaunchMode.externalApplication,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
