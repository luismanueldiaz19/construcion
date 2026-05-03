import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../services/inventory_service.dart';
import 'purchase_form_screen.dart';
import 'suppliers_screen.dart';
import 'reception_screen.dart';
import 'project_inventory_details_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<dynamic> _inventarioProyectos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final proyectos = await _inventoryService.getInventarioPorProyecto();
      setState(() {
        _inventarioProyectos = proyectos;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        title: const Text('Inventario por Proyecto'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReceptionScreen(),
                ),
              );
              _loadData();
            },
            icon: const Icon(
              Icons.local_shipping_outlined,
              color: Colors.orange,
            ),
            label: const Text('Recibir en Obra'),
          ),

          const SizedBox(width: 24),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildProjectInventory(),
    );
  }

  Widget _buildProjectInventory() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _inventarioProyectos.length,
      itemBuilder: (context, index) {
        final proj = _inventarioProyectos[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blueGrey,
              child: Icon(Icons.apartment, color: Colors.white),
            ),
            title: Text(
              proj['nombre'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: const Text('Ver balance y movimientos de inventario'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectInventoryDetailsScreen(
                    proyectoId: proj['id'],
                    proyectoNombre: proj['nombre'],
                  ),
                ),
              ).then((_) => _loadData());
            },
          ),
        );
      },
    );
  }
}
