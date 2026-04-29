import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cabecera Premium
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF003366),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isEdit ? Icons.edit_note : Icons.add_business,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit ? 'Editar Producto' : 'Nuevo Producto',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Complete la información del catálogo',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Identificación del Producto
                        const Text(
                          'Identificación',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: codigoController,
                                decoration: InputDecoration(
                                  labelText: 'SKU / Código',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.qr_code,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      value: catId,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: 'Categoría',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      items: _categorias
                                          .map<DropdownMenuItem<int>>(
                                            (c) => DropdownMenuItem<int>(
                                              value: c['id'],
                                              child: Text(
                                                c['nombre'],
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) =>
                                          setModalState(() => catId = v),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Botón para nueva categoría
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.add,
                                        color: Colors.blue,
                                      ),
                                      tooltip: 'Nueva Categoría',
                                      onPressed: () => _showNewCategoryDialog(
                                        onCreated: (newCat) {
                                          setModalState(() {
                                            catId = newCat['id'];
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Nombre y Descripción
                        TextField(
                          controller: nombreController,
                          decoration: InputDecoration(
                            labelText: 'Nombre del Producto *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.inventory_2_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Descripción detallada',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Medidas y Costos
                        const Text(
                          'Especificaciones Técnicas',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: unidadController,
                                decoration: InputDecoration(
                                  labelText: 'Unidad *',
                                  hintText: 'UND, PA, M3...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onChanged: (v) =>
                                    unidadController.value = unidadController
                                        .value
                                        .copyWith(text: v.toUpperCase()),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: precioController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Precio Costo \$',
                                  prefixIcon: const Icon(Icons.attach_money),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Botones de Acción
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (nombreController.text.isEmpty ||
                                        unidadController.text.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Nombre y Unidad son obligatorios',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    setModalState(() => isSaving = true);
                                    final data = {
                                      'codigo': codigoController.text.isEmpty
                                          ? null
                                          : codigoController.text,
                                      'nombre': nombreController.text,
                                      'descripcion': descController.text,
                                      'categoria_id': catId,
                                      'unidad': unidadController.text
                                          .toUpperCase(),
                                      'precio_costo':
                                          double.tryParse(
                                            precioController.text,
                                          ) ??
                                          0.0,
                                    };

                                    try {
                                      if (isEdit) {
                                        await _apiService.updateMaterial(
                                          product['id'],
                                          data,
                                        );
                                      } else {
                                        await _apiService.createMaterial(data);
                                      }
                                      if (mounted) {
                                        Navigator.pop(context);
                                        _loadData();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isEdit
                                                  ? 'Producto actualizado'
                                                  : 'Producto creado',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setModalState(() => isSaving = false);
                                      if (mounted)
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFA000),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    isEdit
                                        ? 'GUARDAR CAMBIOS'
                                        : 'CREAR PRODUCTO',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showNewCategoryDialog({
    required Function(Map<String, dynamic>) onCreated,
  }) {
    final controller = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Nueva Categoría'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre de la Categoría',
              hintText: 'Ej: Pinturas, Aceros...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (controller.text.isEmpty) return;
                      setModalState(() => isSaving = true);
                      try {
                        final newCat = await _apiService.createCategoria({
                          'nombre': controller.text,
                        });
                        await _loadData(); // Refresca la lista global de categorías
                        if (mounted) {
                          onCreated(newCat);
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        setModalState(() => isSaving = false);
                        if (mounted)
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 15,
                      width: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }
}
