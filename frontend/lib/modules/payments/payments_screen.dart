import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../accounting/cuentas_por_pagar_screen.dart'; // We'll keep the views but integrate them here

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _history = [];
  bool _isLoadingHistory = true;
  String _searchQuery = '';
  String? _filterTipo;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final data = await _apiService.getAllPagosHistorial();
      setState(() {
        _history = data;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() => _isLoadingHistory = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar historial: $e')),
        );
      }
    }
  }

  List<dynamic> get _filteredHistory {
    return _history.where((item) {
      final matchesSearch = item['entidad'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['proyecto'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['concepto'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesTipo = _filterTipo == null || item['tipo'] == _filterTipo;
      
      return matchesSearch && matchesTipo;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Pagos Realizados'),
        actions: [
          IconButton(
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar por proyecto, proveedor...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: _filterTipo,
                  hint: const Text('Tipo'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: 'Compra', child: Text('Compra')),
                    DropdownMenuItem(value: 'Proyecto', child: Text('Proyecto')),
                  ],
                  onChanged: (v) => setState(() => _filterTipo = v),
                ),
              ],
            ),
          ),
          Expanded(child: _buildHistoryTab()),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final f = NumberFormat.currency(symbol: '\$');
    final filtered = _filteredHistory;
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: _isLoadingHistory
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
              ? const Center(child: Text('No se encontraron registros.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildHistoryCard(item, f);
                  },
                ),
    );
  }

  Widget _buildHistoryCard(dynamic item, NumberFormat f) {
    final bool isCompra = item['tipo'] == 'Compra';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: isCompra ? Colors.blue[100] : Colors.orange[100],
          child: Icon(
            isCompra ? Icons.shopping_cart : Icons.construction,
            color: isCompra ? Colors.blue[900] : Colors.orange[900],
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item['entidad'],
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              f.format(double.tryParse(item['monto'].toString()) ?? 0),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 16,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.business, size: 14, color: Colors.blueGrey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Proyecto: ${item['proyecto']}',
                    style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.blueGrey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(item['concepto']),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  item['fecha'],
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 12),
                Icon(Icons.payment, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  item['metodo_pago'],
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
          onPressed: () => _openPdf(item['tipo'], item['id']),
          tooltip: 'Imprimir Recibo',
        ),
      ),
    );
  }

  void _openPdf(String tipo, int id) async {
    final url = Uri.parse('${_apiService.baseUrl}/pagos-historial/$tipo/$id/pdf');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el PDF')),
        );
      }
    }
  }
}
