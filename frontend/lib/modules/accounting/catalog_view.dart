import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class CatalogView extends StatefulWidget {
  const CatalogView({super.key});

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  final ApiService _apiService = ApiService();
  List<dynamic> _catalogo = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCatalogo();
  }

  Future<void> _loadCatalogo() async {
    try {
      final data = await _apiService.getCatalogo();
      setState(() {
        _catalogo = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _catalogo.length,
      itemBuilder: (context, index) {
        return _buildAccountNode(_catalogo[index], 0);
      },
    );
  }

  Widget _buildAccountNode(dynamic node, int depth) {
    final hijos = node['hijos'] as List? ?? [];
    final balance = double.tryParse(node['balance']?.toString() ?? '0') ?? 0;
    final f = NumberFormat.currency(symbol: '\$');

    // Invertimos el signo para Pasivos, Ingresos y Capital para mostrar saldo normal acreedor como positivo
    double displayBalance = balance;
    if (['Pasivo', 'Ingreso', 'Capital'].contains(node['tipo'])) {
      displayBalance = -balance;
    }

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(left: depth * 24.0, right: 16),
          leading: Icon(
            hijos.isNotEmpty
                ? Icons.folder
                : Icons.account_balance_wallet_outlined,
            color: _getColor(node['tipo']),
          ),
          title: Text(
            "${node['codigo']} ${node['nombre']}",
            style: TextStyle(
              fontWeight: node['nivel'] == 1
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          trailing: Text(
            f.format(displayBalance),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: displayBalance < 0 ? Colors.red : Colors.black87,
              fontSize: node['nivel'] == 1 ? 16 : 14,
            ),
          ),
          subtitle: node['nivel'] == 1
              ? Text(
                  node['tipo'].toUpperCase(),
                  style: const TextStyle(fontSize: 10, letterSpacing: 1),
                )
              : null,
        ),
        if (node['nivel'] < 3 || hijos.isNotEmpty)
          ...hijos.map((h) => _buildAccountNode(h, depth + 1)).toList(),
      ],
    );
  }

  Color _getColor(String tipo) {
    switch (tipo) {
      case 'Activo':
        return Colors.blue;
      case 'Pasivo':
        return Colors.red;
      case 'Capital':
        return Colors.purple;
      case 'Ingreso':
        return Colors.green;
      case 'Costo':
        return Colors.orange;
      case 'Gasto':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }
}
