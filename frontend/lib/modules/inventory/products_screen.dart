import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_theme.dart';
import '../../services/inventory_service.dart';
import 'package:intl/intl.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<dynamic> _materiales = [];
  List<dynamic> _filteredMateriales = [];
  List<dynamic> _categorias = [];
  bool _isLoading = true;

  // Controllers and active filters
  final TextEditingController _searchController = TextEditingController();
  int? _selectedCategoriaId;

  // Form controllers and states
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _unidadController = TextEditingController();
  int? _editingCategoriaId;
  Map<String, dynamic>? _editingProduct;
  bool _isAddingProduct = false;
  bool _isSavingForm = false;

  bool get _isFilterActive =>
      _searchController.text.isNotEmpty || _selectedCategoriaId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _codigoController.dispose();
    _nombreController.dispose();
    _descController.dispose();
    _precioController.dispose();
    _unidadController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final materials = await _inventoryService.getMateriales();
      final categories = await _inventoryService.getCategorias();
      setState(() {
        _materiales = materials;
        _categorias = categories;
        _filterData();

        // Sincronizar el producto en edición con los datos frescos cargados del servidor
        if (_editingProduct != null) {
          final fresh = _materiales.firstWhere(
            (m) => m['id'] == _editingProduct!['id'],
            orElse: () => null,
          );
          if (fresh != null) {
            _editingProduct = fresh;
            _codigoController.text = fresh['codigo'] ?? '';
            _nombreController.text = fresh['nombre'] ?? '';
            _descController.text = fresh['descripcion'] ?? '';
            _precioController.text = fresh['precio_costo']?.toString() ?? '';
            _unidadController.text = fresh['unidad'] ?? '';
            _editingCategoriaId = fresh['categoria_id'];
          } else {
            _editingProduct = null;
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
      }
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

  void _selectProductForEdit(Map<String, dynamic> product) {
    setState(() {
      _editingProduct = product;
      _isAddingProduct = false;
      _codigoController.text = product['codigo'] ?? '';
      _nombreController.text = product['nombre'] ?? '';
      _descController.text = product['descripcion'] ?? '';
      _precioController.text = product['precio_costo']?.toString() ?? '';
      _unidadController.text = product['unidad'] ?? '';
      _editingCategoriaId = product['categoria_id'];
    });
  }

  void _startAddingProduct() {
    setState(() {
      _editingProduct = null;
      _isAddingProduct = true;
      _codigoController.clear();
      _nombreController.clear();
      _descController.clear();
      _precioController.clear();
      _unidadController.clear();
      _editingCategoriaId = null;
    });
  }

  void _cancelForm() {
    setState(() {
      _editingProduct = null;
      _isAddingProduct = false;
      _codigoController.clear();
      _nombreController.clear();
      _descController.clear();
      _precioController.clear();
      _unidadController.clear();
      _editingCategoriaId = null;
    });
  }

  void _onEditProductPressed(Map<String, dynamic> product, bool isLargeScreen) {
    _selectProductForEdit(product);
    if (!isLargeScreen) {
      _showFormBottomSheet();
    }
  }

  void _onCreateProductPressed(bool isLargeScreen) {
    _startAddingProduct();
    if (!isLargeScreen) {
      _showFormBottomSheet();
    }
  }

  Future<void> _toggleEstado(int id) async {
    try {
      await _inventoryService.toggleMaterialEstado(id);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cambiar estado: $e')));
      }
    }
  }

  void _showFormBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 600),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: _buildProductForm(
                      isBottomSheet: true,
                      onStateChanged: () {
                        setModalState(() {});
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        _cancelForm();
      }
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtrar Productos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
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
                    onChanged: (v) {
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedCategoriaId,
                    decoration: InputDecoration(
                      labelText: 'Categoría',
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
                      setState(() {
                        _selectedCategoriaId = v;
                      });
                      _filterData();
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'APLICAR FILTROS',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChips() {
    if (!_isFilterActive) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Text(
            'Filtros activos: ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                if (_searchController.text.isNotEmpty)
                  Chip(
                    label: Text('Buscar: "${_searchController.text}"'),
                    onDeleted: () {
                      _searchController.clear();
                      _filterData();
                    },
                    deleteIcon: const Icon(Icons.close, size: 16),
                    backgroundColor: Colors.blue[50],
                  ),
                if (_selectedCategoriaId != null)
                  Chip(
                    label: Text(
                      'Categoría: ${_categorias.firstWhere((c) => c['id'] == _selectedCategoriaId, orElse: () => {'nombre': ''})['nombre']}',
                    ),
                    onDeleted: () {
                      setState(() {
                        _selectedCategoriaId = null;
                      });
                      _filterData();
                    },
                    deleteIcon: const Icon(Icons.close, size: 16),
                    backgroundColor: Colors.blue[50],
                  ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _selectedCategoriaId = null;
                    });
                    _filterData();
                  },
                  child: const Text('Limpiar todo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductForm({
    required bool isBottomSheet,
    VoidCallback? onStateChanged,
  }) {
    final bool isEdit = _editingProduct != null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: isBottomSheet
          ? null
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                children: [
                  Icon(
                    isEdit ? Icons.edit_note : Icons.add_business,
                    color: AppTheme.accentColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEdit ? 'Editar Producto' : 'Nuevo Producto',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              if (isBottomSheet)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              else
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _cancelForm,
                  tooltip: 'Cancelar',
                ),
            ],
          ),
          const Divider(height: 24),
          if (isEdit) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Estado: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Chip(
                      label: Text(
                        (_editingProduct!['estado'] == 'activo' ||
                                _editingProduct!['estado'] == true ||
                                _editingProduct!['estado'] == 1)
                            ? 'ACTIVO'
                            : 'INACTIVO',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor:
                          (_editingProduct!['estado'] == 'activo' ||
                              _editingProduct!['estado'] == true ||
                              _editingProduct!['estado'] == 1)
                          ? Colors.green
                          : Colors.red,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () async {
                    await _toggleEstado(_editingProduct!['id']);
                    if (onStateChanged != null) onStateChanged();
                  },
                  icon: Icon(
                    (_editingProduct!['estado'] == 'activo' ||
                            _editingProduct!['estado'] == true ||
                            _editingProduct!['estado'] == 1)
                        ? Icons.block
                        : Icons.check_circle,
                    color:
                        (_editingProduct!['estado'] == 'activo' ||
                            _editingProduct!['estado'] == true ||
                            _editingProduct!['estado'] == 1)
                        ? Colors.orange
                        : Colors.green,
                    size: 18,
                  ),
                  label: Text(
                    (_editingProduct!['estado'] == 'activo' ||
                            _editingProduct!['estado'] == true ||
                            _editingProduct!['estado'] == 1)
                        ? 'Desactivar'
                        : 'Activar',
                    style: TextStyle(
                      color:
                          (_editingProduct!['estado'] == 'activo' ||
                              _editingProduct!['estado'] == true ||
                              _editingProduct!['estado'] == 1)
                          ? Colors.orange
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
          ],

          const Text(
            'Identificación',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _codigoController,
            decoration: InputDecoration(
              labelText: 'SKU / Código',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.qr_code, size: 20),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _editingCategoriaId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                  items: _categorias
                      .map<DropdownMenuItem<int>>(
                        (c) => DropdownMenuItem<int>(
                          value: c['id'],
                          child: Text(
                            c['nombre'],
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _editingCategoriaId = v;
                    });
                    if (onStateChanged != null) onStateChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.blue),
                  tooltip: 'Nueva Categoría',
                  onPressed: () => _showNewCategoryDialog(
                    onCreated: (newCat) {
                      setState(() {
                        _editingCategoriaId = newCat['id'];
                      });
                      if (onStateChanged != null) onStateChanged();
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'Información General',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nombreController,
            decoration: InputDecoration(
              labelText: 'Nombre del Producto *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Descripción detallada',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Especificaciones Técnicas',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _unidadController,
                  decoration: InputDecoration(
                    labelText: 'Unidad *',
                    hintText: 'UND, PA...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                  onChanged: (v) {
                    _unidadController.value = _unidadController.value.copyWith(
                      text: v.toUpperCase(),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _precioController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Precio Costo \$',
                    prefixIcon: const Icon(Icons.attach_money, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              if (!isBottomSheet) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelForm,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('CANCELAR'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: isBottomSheet ? 1 : 2,
                child: ElevatedButton(
                  onPressed: _isSavingForm
                      ? null
                      : () => _saveProduct(isBottomSheet),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSavingForm
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEdit ? 'GUARDAR' : 'CREAR',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveProduct(bool isBottomSheet) async {
    if (_nombreController.text.isEmpty || _unidadController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y Unidad son obligatorios')),
      );
      return;
    }

    setState(() => _isSavingForm = true);
    final data = {
      'codigo': _codigoController.text.isEmpty ? null : _codigoController.text,
      'nombre': _nombreController.text,
      'descripcion': _descController.text.isEmpty ? null : _descController.text,
      'categoria_id': _editingCategoriaId,
      'unidad': _unidadController.text.toUpperCase(),
      'precio_costo': double.tryParse(_precioController.text) ?? 0.0,
    };

    try {
      if (_editingProduct != null) {
        await _inventoryService.updateMaterial(_editingProduct!['id'], data);
      } else {
        await _inventoryService.createMaterial(data);
      }
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingProduct != null
                  ? 'Producto actualizado'
                  : 'Producto creado',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      if (isBottomSheet) {
        Navigator.pop(context);
      }
      _cancelForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingForm = false);
      }
    }
  }

  Widget _buildPlaceholderForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Detalles de Producto',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Seleccione un producto de la tabla para editar sus datos, o presione "Nuevo Producto" para agregar uno nuevo al catálogo.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _onCreateProductPressed(true),
            icon: const Icon(Icons.add_box, size: 20),
            label: const Text('Crear Nuevo Producto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ],
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
                        final newCat = await _inventoryService.createCategoria({
                          'nombre': controller.text,
                        });
                        await _loadData(); // Refresca la lista global de categorías
                        if (mounted) {
                          onCreated(newCat);
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        setModalState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
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

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final width = MediaQuery.of(context).size.width;
    final isLargeScreen = width > 950;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Administración de Productos'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          OutlinedButton.icon(
            onPressed: () => _showFilterBottomSheet(),
            icon: Icon(
              _isFilterActive ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _isFilterActive
                  ? AppTheme.accentColor
                  : AppTheme.textSecondary,
              size: 20,
            ),
            label: Text(
              'Filtrar',
              style: TextStyle(
                color: _isFilterActive
                    ? AppTheme.accentColor
                    : AppTheme.textSecondary,
                fontWeight: _isFilterActive
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _isFilterActive
                    ? AppTheme.accentColor
                    : Colors.grey[300]!,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _onCreateProductPressed(isLargeScreen),
            icon: const Icon(Icons.add_box),
            label: const Text('Nuevo Producto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterChips(),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _filteredMateriales.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No se encontraron productos.',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 16,
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        Expanded(
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              return SingleChildScrollView(
                                                scrollDirection: Axis.vertical,
                                                child: SingleChildScrollView(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  child: ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                      minWidth:
                                                          constraints.maxWidth,
                                                    ),
                                                    child: DataTable(
                                                      showCheckboxColumn: false,
                                                      headingRowColor:
                                                          WidgetStateProperty.all(
                                                            Colors.grey[100],
                                                          ),
                                                      columns: const [
                                                        DataColumn(
                                                          label: Text('Código'),
                                                        ),
                                                        DataColumn(
                                                          label: Text(
                                                            'Producto',
                                                          ),
                                                        ),
                                                        DataColumn(
                                                          label: Text(
                                                            'Categoría',
                                                          ),
                                                        ),
                                                        DataColumn(
                                                          label: Text(
                                                            'U. Medida',
                                                          ),
                                                        ),
                                                        DataColumn(
                                                          label: Text(
                                                            'Precio Costo',
                                                          ),
                                                        ),
                                                        DataColumn(
                                                          label: Text('Estado'),
                                                        ),
                                                      ],
                                                      rows: _filteredMateriales.map((
                                                        m,
                                                      ) {
                                                        final bool isActive =
                                                            m['estado'] ==
                                                                'activo' ||
                                                            m['estado'] ==
                                                                true ||
                                                            m['estado'] == 1;
                                                        final bool isSelected =
                                                            _editingProduct !=
                                                                null &&
                                                            _editingProduct!['id'] ==
                                                                m['id'];
                                                        return DataRow(
                                                          selected: isSelected,
                                                          onSelectChanged:
                                                              (selected) {
                                                                if (selected !=
                                                                        null &&
                                                                    selected) {
                                                                  _onEditProductPressed(
                                                                    m,
                                                                    isLargeScreen,
                                                                  );
                                                                }
                                                              },
                                                          cells: [
                                                            DataCell(
                                                              Text(
                                                                m['codigo'] ??
                                                                    'N/A',
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Text(
                                                                    m['nombre'],
                                                                    style: const TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                  if (m['descripcion'] !=
                                                                          null &&
                                                                      m['descripcion']
                                                                          .toString()
                                                                          .isNotEmpty)
                                                                    Text(
                                                                      m['descripcion'],
                                                                      style: const TextStyle(
                                                                        fontSize:
                                                                            11,
                                                                        color: Colors
                                                                            .grey,
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
                                                            DataCell(
                                                              Text(
                                                                m['unidad'] ??
                                                                    '',
                                                              ),
                                                            ),
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
                                                                  isActive
                                                                      ? 'ACTIVO'
                                                                      : 'INACTIVO',
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                ),
                                                                backgroundColor:
                                                                    isActive
                                                                    ? Colors
                                                                          .green
                                                                    : Colors
                                                                          .red,
                                                                padding:
                                                                    EdgeInsets
                                                                        .zero,
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                      if (isLargeScreen)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 16.0,
                            right: 16.0,
                            bottom: 16.0,
                          ),
                          child: SizedBox(
                            width: 380,
                            child: _editingProduct != null || _isAddingProduct
                                ? _buildProductForm(isBottomSheet: false)
                                : _buildPlaceholderForm(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
