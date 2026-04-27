import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _proveedores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getProveedores();
      setState(() {
        _proveedores = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Proveedores'),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showAddProveedorDialog(),
            icon: const Icon(Icons.person_add),
            label: const Text('Nuevo Proveedor'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _proveedores.length,
            itemBuilder: (context, index) {
              final p = _proveedores[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.business)),
                  title: Text(p['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("RNC: ${p['rnc'] ?? 'N/A'} - Tel: ${p['telefono'] ?? 'N/A'}"),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          ),
    );
  }

  void _showAddProveedorDialog() {
    final nameController = TextEditingController();
    final rncController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Nuevo Proveedor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre / Razón Social')),
            TextField(controller: rncController, decoration: const InputDecoration(labelText: 'RNC')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Teléfono')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              await _apiService.createProveedor({
                'nombre': nameController.text,
                'rnc': rncController.text,
                'telefono': phoneController.text,
              });
              Navigator.pop(context);
              _loadData();
            }, 
            child: const Text('Guardar')
          ),
        ],
      ),
    );
  }
}
