import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../services/purchase_service.dart';

class GastoDetailScreen extends StatefulWidget {
  final int gastoId;

  const GastoDetailScreen({super.key, required this.gastoId});

  @override
  State<GastoDetailScreen> createState() => _GastoDetailScreenState();
}

class _GastoDetailScreenState extends State<GastoDetailScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  bool _isLoading = true;
  Map<String, dynamic>? _gasto;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGasto();
  }

  Future<void> _loadGasto() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _purchaseService.getGasto(widget.gastoId);
      setState(() {
        _gasto = data;
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
        appBar: AppBar(title: Text('Comprobante #${widget.gastoId}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Comprobante #${widget.gastoId}')),
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (_gasto == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Comprobante #${widget.gastoId}')),
        body: const Center(child: Text('No se encontró el gasto.')),
      );
    }

    final f = NumberFormat.currency(symbol: '\$');
    const primaryColor = Color(0xFF003366);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de Gasto #${_gasto!['id']}'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Imprimir Comprobante',
            onPressed: () async {
              final url = Uri.parse('$host/gastos/${_gasto!['id']}/print');
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
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(primaryColor, f),
                const SizedBox(height: 24),
                _buildConceptCard(f),
                const SizedBox(height: 24),
                _buildSummaryCard(f),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Color primaryColor, NumberFormat f) {
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
                  'COMPROBANTE #${_gasto!['id']}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                Text(
                  _gasto!['fecha']?.toString().split('T')[0] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey,
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
                    'Proyecto',
                    _gasto!['proyecto']?['nombre'] ?? 'N/A',
                    Icons.business,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Tipo de Gasto',
                    _gasto!['tipo_gasto'] ?? 'N/A',
                    Icons.category,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Método Pago',
                    _gasto!['metodo_pago'] ?? 'N/A',
                    Icons.payment,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Beneficiario',
                    _gasto!['proveedor']?['nombre'] ?? 'N/A',
                    Icons.person,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Subpartida',
                    _gasto!['subpartida']?['descripcion'] ?? 'General',
                    Icons.list_alt,
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
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildConceptCard(NumberFormat f) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Concepto / Descripción',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text(
              _gasto!['descripcion'] ?? 'Sin descripción',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(NumberFormat f) {
    final monto = double.tryParse(_gasto!['monto']?.toString() ?? '0') ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF003366),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'TOTAL PAGADO',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            f.format(monto),
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
