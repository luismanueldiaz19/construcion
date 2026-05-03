import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../services/purchase_service.dart';

class CompraDetailScreen extends StatefulWidget {
  final int compraId;

  const CompraDetailScreen({super.key, required this.compraId});

  @override
  State<CompraDetailScreen> createState() => _CompraDetailScreenState();
}

class _CompraDetailScreenState extends State<CompraDetailScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  bool _isLoading = true;
  Map<String, dynamic>? _compra;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCompra();
  }

  Future<void> _loadCompra() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _purchaseService.getCompra(widget.compraId);
      setState(() {
        _compra = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Factura #${widget.compraId}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Factura #${widget.compraId}')),
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (_compra == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Factura #${widget.compraId}')),
        body: const Center(child: Text('No se encontró la compra.')),
      );
    }

    final f = NumberFormat.currency(symbol: '\$');
    final detalles = _compra!['detalles'] as List? ?? [];

    // Configuración visual adaptada al "Design System" general (Color Azul Oscuro)
    const primaryColor = Color(0xFF003366);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de Compra #${_compra!['id']}'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Imprimir Factura',
            onPressed: () async {
              final url = Uri.parse('$host/compras/${_compra!['id']}/print');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo abrir el enlace de impresión'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(primaryColor, f),
                const SizedBox(height: 24),
                const Text(
                  'Materiales / Artículos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildItemsTable(detalles, f),
                const SizedBox(height: 24),
                _buildTotalsCard(f),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Color primaryColor, NumberFormat f) {
    final estado = _compra!['estado'] ?? 'N/A';
    Color estadoColor = estado == 'Pendiente' ? Colors.orange : Colors.green;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FACTURA #${_compra!['id']}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: estadoColor),
                  ),
                  child: Text(
                    estado.toUpperCase(),
                    style: TextStyle(
                      color: estadoColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Proveedor',
                    _compra!['proveedor']?['nombre'] ?? 'N/A',
                    Icons.store,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Proyecto',
                    _compra!['proyecto']?['nombre'] ?? 'N/A',
                    Icons.business,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Fecha',
                    _compra!['fecha']?.toString().split('T')[0] ?? 'N/A',
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Tipo',
                    _compra!['tipo_compra'] ?? 'N/A',
                    Icons.payment,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildItemsTable(List<dynamic> detalles, NumberFormat f) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
        columns: const [
          DataColumn(
            label: Text(
              'Código',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Material / Descripción',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Cantidad',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'Precio Unitario',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'Subtotal',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
        ],
        rows: detalles.map((d) {
          final mat = d['material'];
          final cantidad =
              double.tryParse(d['cantidad']?.toString() ?? '0') ?? 0;
          final precio =
              double.tryParse(d['precio_unitario']?.toString() ?? '0') ?? 0;
          final subtotal =
              double.tryParse(d['subtotal']?.toString() ?? '0') ?? 0;

          return DataRow(
            cells: [
              DataCell(Text(mat?['codigo'] ?? 'N/A')),
              DataCell(Text(mat?['nombre'] ?? 'Desconocido')),
              DataCell(Text(cantidad.toStringAsFixed(2))),
              DataCell(Text(f.format(precio))),
              DataCell(
                Text(
                  f.format(subtotal),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTotalsCard(NumberFormat f) {
    final subtotal =
        double.tryParse(_compra!['subtotal']?.toString() ?? '0') ?? 0;
    final itbis = double.tryParse(_compra!['itbis']?.toString() ?? '0') ?? 0;
    final total = double.tryParse(_compra!['total']?.toString() ?? '0') ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 300,
          child: Card(
            elevation: 4,
            color: const Color(0xFF003366),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildTotalRow(
                    'Subtotal',
                    f.format(subtotal),
                    Colors.white70,
                  ),
                  const SizedBox(height: 8),
                  _buildTotalRow(
                    'ITBIS (18%)',
                    f.format(itbis),
                    Colors.white70,
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  _buildTotalRow(
                    'TOTAL',
                    f.format(total),
                    Colors.greenAccent,
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(
    String label,
    String value,
    Color color, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
