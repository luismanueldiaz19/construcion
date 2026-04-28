import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _materiales = [];
  List<dynamic> _filteredMateriales = [];
  List<dynamic> _categorias = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  int? _selectedCategoriaId;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final materials = await _apiService.getMateriales();
      final categories = await _apiService.getCategorias();
      setState(() {
        _materiales = materials;
        _categorias = categories;
        _filterData();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _filterData() {
    setState(() {
      _filteredMateriales = _materiales.where((m) {
        final matchesSearch =
            m['nombre'].toString().toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            (m['codigo']?.toString().toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ??
                false);
        final matchesCategory =
            _selectedCategoriaId == null ||
            m['categoria_id'] == _selectedCategoriaId;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración de Productos'),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showProductDialog(),
            icon: const Icon(Icons.add_box),
            label: const Text('Nuevo Producto'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(),
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
                            DataColumn(label: Text('Código')),
                            DataColumn(label: Text('Producto')),
                            DataColumn(label: Text('Categoría')),
                            DataColumn(label: Text('U. Medida')),
                            DataColumn(label: Text('Precio Costo')),
                            DataColumn(label: Text('Estado')),
                            DataColumn(label: Text('Acciones')),
                          ],
                          rows: _filteredMateriales.map((m) {
                            final bool isActive =
                                m['estado'] == 'activo' ||
                                m['estado'] == true ||
                                m['estado'] == 1;
                            return DataRow(
                              cells: [
                                DataCell(Text(m['codigo'] ?? 'N/A')),
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        m['nombre'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (m['descripcion'] != null)
                                        Text(
                                          m['descripcion'],
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    m['categoria']?['nombre'] ??
                                        'Sin Categoría',
                                  ),
                                ),
                                DataCell(Text(m['unidad'] ?? '')),
                                DataCell(
                                  Text(
                                    currencyFormat.format(
                                      double.tryParse(
                                            m['precio_costo']?.toString() ??
                                                '0',
                                          ) ??
                                          0,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Chip(
                                    label: Text(
                                      isActive ? 'ACTIVO' : 'INACTIVO',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: isActive
                                        ? Colors.green
                                        : Colors.red,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () =>
                                            _showProductDialog(product: m),
                                        tooltip: 'Editar',
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          isActive
                                              ? Icons.block
                                              : Icons.check_circle,
                                          color: isActive
                                              ? Colors.orange
                                              : Colors.green,
                                        ),
                                        onPressed: () => _toggleEstado(m['id']),
                                        tooltip: isActive
                                            ? 'Desactivar'
                                            : 'Activar',
                                      ),
                                    ],
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

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o código...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _selectedCategoriaId,
              decoration: InputDecoration(
                labelText: 'Filtrar por Categoría',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Todas las categorías'),
                ),
                ..._categorias.map<DropdownMenuItem<int>>(
                  (c) => DropdownMenuItem<int>(
                    value: c['id'],
                    child: Text(c['nombre']),
                  ),
                ),
              ],
              onChanged: (v) {
                setState(() => _selectedCategoriaId = v);
                _filterData();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleEstado(int id) async {
    try {
      await _apiService.toggleMaterialEstado(id);
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showProductDialog({Map<String, dynamic>? product}) {
    final bool isEdit = product != null;
    final codigoController = TextEditingController(text: product?['codigo']);
    final nombreController = TextEditingController(text: product?['nombre']);
    final descController = TextEditingController(text: product?['descripcion']);
    final precioController = TextEditingController(
      text: product?['precio_costo']?.toString(),
    );
    final unidadController = TextEditingController(text: product?['unidad']);
    int? catId = product?['categoria_id'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Editar Producto' : 'Nuevo Producto'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: codigoController,
                        decoration: const InputDecoration(
                          labelText: 'Código (SKU)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: catId,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                          border: OutlineInputBorder(),
                        ),
                        items: _categorias
                            .map<DropdownMenuItem<int>>(
                              (c) => DropdownMenuItem<int>(
                                value: c['id'],
                                child: Text(c['nombre']),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => catId = v,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Producto *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: unidadController,
                        decoration: const InputDecoration(
                          labelText: 'Unidad de Medida *',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) =>
                            unidadController.value = unidadController.value
                                .copyWith(text: v.toUpperCase()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: precioController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Precio de Costo',
                          prefixText: '\$',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nombreController.text.isEmpty ||
                  unidadController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nombre y Unidad son obligatorios'),
                  ),
                );
                return;
              }

              final data = {
                'codigo': codigoController.text.isEmpty
                    ? null
                    : codigoController.text,
                'nombre': nombreController.text,
                'descripcion': descController.text,
                'categoria_id': catId,
                'unidad': unidadController.text.toUpperCase(),
                'precio_costo': double.tryParse(precioController.text) ?? 0.0,
              };

              try {
                if (isEdit) {
                  await _apiService.updateMaterial(product['id'], data);
                } else {
                  await _apiService.createMaterial(data);
                }
                if (mounted) Navigator.pop(context);
                _loadData();
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
