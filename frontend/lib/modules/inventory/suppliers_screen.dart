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
  List<dynamic> _filteredProveedores = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredProveedores = _proveedores
          .where(
            (p) =>
                p['nombre'].toString().toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ||
                (p['rnc']?.toString().toLowerCase().contains(
                      _searchController.text.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getProveedores();
      setState(() {
        _proveedores = data;
        _filteredProveedores = data;
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
            onPressed: () => _showSupplierDialog(),
            icon: const Icon(Icons.person_add),
            label: const Text('Nuevo Proveedor'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o RNC...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SizedBox(
                      width: double.infinity,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            Colors.grey[100],
                          ),
                          columns: const [
                            DataColumn(label: Text('Nombre / Empresa')),
                            DataColumn(label: Text('RNC')),
                            DataColumn(label: Text('Teléfono')),
                            DataColumn(label: Text('Acciones')),
                          ],
                          rows: _filteredProveedores.map((p) {
                            return DataRow(
                              cells: [
                                DataCell(Text(p['nombre'] ?? '')),
                                DataCell(Text(p['rnc'] ?? 'N/A')),
                                DataCell(Text(p['telefono'] ?? 'N/A')),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () =>
                                        _showSupplierDialog(supplier: p),
                                    tooltip: 'Editar',
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showSupplierDialog({Map<String, dynamic>? supplier}) {
    final bool isEdit = supplier != null;
    final nameController = TextEditingController(text: supplier?['nombre']);
    final rncController = TextEditingController(text: supplier?['rnc']);
    final phoneController = TextEditingController(text: supplier?['telefono']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Editar Proveedor' : 'Registrar Nuevo Proveedor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre / Razón Social',
              ),
            ),
            TextField(
              controller: rncController,
              decoration: const InputDecoration(labelText: 'RNC'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final data = {
                'nombre': nameController.text,
                'rnc': rncController.text,
                'telefono': phoneController.text,
              };

              try {
                if (isEdit) {
                  await _apiService.updateProveedor(supplier['id'], data);
                } else {
                  await _apiService.createProveedor(data);
                }
                if (mounted) Navigator.pop(context);
                _loadData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
