import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/proveedor.dart';
import '../../services/purchase_service.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  List<Proveedor> _proveedores = [];
  List<Proveedor> _filteredProveedores = [];
  bool _isLoading = true;

  // Controllers and active filters
  final TextEditingController _searchController = TextEditingController();

  // Form controllers and states
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rncController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  Proveedor? _editingSupplier;
  bool _isAddingSupplier = false;
  bool _isSavingForm = false;

  bool get _isFilterActive => _searchController.text.isNotEmpty;

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
    _nameController.dispose();
    _rncController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredProveedores = _proveedores
          .where(
            (p) =>
                p.nombre.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ||
                (p.rnc?.toLowerCase().contains(
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
      final data = await _purchaseService.getProveedores();
      setState(() {
        _proveedores = data;
        _filteredProveedores = data;

        // Sync editing supplier if active
        if (_editingSupplier != null) {
          final fresh = _proveedores.firstWhere(
            (p) => p.id == _editingSupplier!.id,
            orElse: () => Proveedor(nombre: ''),
          );
          if (fresh.id != null) {
            _editingSupplier = fresh;
            _nameController.text = fresh.nombre;
            _rncController.text = fresh.rnc ?? '';
            _phoneController.text = fresh.telefono ?? '';
            _addressController.text = fresh.direccion ?? '';
          } else {
            _editingSupplier = null;
          }
        }

        _isLoading = false;
        _onSearchChanged(); // Re-apply current search filter
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar proveedores: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectSupplierForEdit(Proveedor supplier) {
    setState(() {
      _editingSupplier = supplier;
      _isAddingSupplier = false;
      _nameController.text = supplier.nombre;
      _rncController.text = supplier.rnc ?? '';
      _phoneController.text = supplier.telefono ?? '';
      _addressController.text = supplier.direccion ?? '';
    });
  }

  void _startAddingSupplier() {
    setState(() {
      _editingSupplier = null;
      _isAddingSupplier = true;
      _nameController.clear();
      _rncController.clear();
      _phoneController.clear();
      _addressController.clear();
    });
  }

  void _cancelForm() {
    setState(() {
      _editingSupplier = null;
      _isAddingSupplier = false;
      _nameController.clear();
      _rncController.clear();
      _phoneController.clear();
      _addressController.clear();
    });
  }

  void _onEditSupplierPressed(Proveedor supplier, bool isLargeScreen) {
    _selectSupplierForEdit(supplier);
    if (!isLargeScreen) {
      _showFormBottomSheet();
    }
  }

  void _onCreateSupplierPressed(bool isLargeScreen) {
    _startAddingSupplier();
    if (!isLargeScreen) {
      _showFormBottomSheet();
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
                    child: _buildSupplierForm(
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
                        'Filtrar Proveedores',
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
                      hintText: 'Buscar por nombre o RNC...',
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
                Chip(
                  label: Text('Buscar: "${_searchController.text}"'),
                  onDeleted: () {
                    _searchController.clear();
                    _onSearchChanged();
                  },
                  deleteIcon: const Icon(Icons.close, size: 16),
                  backgroundColor: Colors.blue[50],
                ),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged();
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

  Widget _buildSupplierForm({
    required bool isBottomSheet,
    VoidCallback? onStateChanged,
  }) {
    final bool isEdit = _editingSupplier != null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: isBottomSheet
          ? null
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isEdit ? Icons.edit_note : Icons.person_add_alt_1,
                    color: AppTheme.accentColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEdit ? 'Editar Proveedor' : 'Nuevo Proveedor',
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
          const Text(
            'DATOS FISCALES',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              fontSize: 11,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nombre / Razón Social *',
              prefixIcon: const Icon(Icons.business, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            onChanged: (v) {
              if (onStateChanged != null) onStateChanged();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rncController,
            decoration: InputDecoration(
              labelText: 'RNC / Cédula',
              prefixIcon: const Icon(Icons.badge_outlined, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hintText: 'Ej: 131-XXXXX-X',
              isDense: true,
            ),
            onChanged: (v) {
              if (onStateChanged != null) onStateChanged();
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'CONTACTO Y UBICACIÓN',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              fontSize: 11,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Teléfono',
              prefixIcon: const Icon(Icons.phone, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            onChanged: (v) {
              if (onStateChanged != null) onStateChanged();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Dirección Completa',
              prefixIcon: const Icon(Icons.location_on, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            onChanged: (v) {
              if (onStateChanged != null) onStateChanged();
            },
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
                      : () => _saveSupplier(isBottomSheet),
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

  Future<void> _saveSupplier(bool isBottomSheet) async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El nombre es obligatorio')));
      return;
    }

    setState(() => _isSavingForm = true);

    final nuevoProveedor = Proveedor(
      id: _editingSupplier?.id,
      nombre: _nameController.text,
      rnc: _rncController.text,
      telefono: _phoneController.text,
      direccion: _addressController.text,
    );

    try {
      if (_editingSupplier != null) {
        await _purchaseService.updateProveedor(
          _editingSupplier!.id!,
          nuevoProveedor,
        );
      } else {
        await _purchaseService.createProveedor(nuevoProveedor);
      }
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingSupplier != null
                  ? 'Proveedor actualizado'
                  : 'Proveedor registrado',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      if (isBottomSheet && mounted) {
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
          Icon(Icons.contact_phone_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Detalles del Proveedor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Seleccione un proveedor de la tabla para editar sus datos, o presione "Nuevo Proveedor" para registrar uno nuevo.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _onCreateSupplierPressed(true),
            icon: const Icon(Icons.person_add_alt_1, size: 20),
            label: const Text('Registrar Proveedor'),
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isLargeScreen = width > 950;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Gestión de Proveedores'),
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
            onPressed: () => _onCreateSupplierPressed(isLargeScreen),
            icon: const Icon(Icons.person_add),
            label: const Text('Nuevo Proveedor'),
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
                              child: _filteredProveedores.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No se encontraron proveedores.',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 16,
                                        ),
                                      ),
                                    )
                                  : LayoutBuilder(
                                      builder: (context, constraints) {
                                        return SingleChildScrollView(
                                          scrollDirection: Axis.vertical,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                minWidth: constraints.maxWidth,
                                              ),
                                              child: DataTable(
                                                showCheckboxColumn: false,
                                                headingRowColor:
                                                    WidgetStateProperty.all(
                                                      Colors.grey[100],
                                                    ),
                                                columns: const [
                                                  DataColumn(
                                                    label: Text(
                                                      'Nombre / Empresa',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'RNC',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'Teléfono',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'Dirección',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                rows: _filteredProveedores.map((
                                                  p,
                                                ) {
                                                  final bool isSelected =
                                                      _editingSupplier !=
                                                          null &&
                                                      _editingSupplier!.id ==
                                                          p.id;
                                                  return DataRow(
                                                    selected: isSelected,
                                                    onSelectChanged: (selected) {
                                                      if (selected != null &&
                                                          selected) {
                                                        _onEditSupplierPressed(
                                                          p,
                                                          isLargeScreen,
                                                        );
                                                      }
                                                    },
                                                    cells: [
                                                      DataCell(Text(p.nombre)),
                                                      DataCell(
                                                        Text(p.rnc ?? 'N/A'),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          p.telefono ?? 'N/A',
                                                        ),
                                                      ),
                                                      DataCell(
                                                        SizedBox(
                                                          width: 250,
                                                          child: Text(
                                                            p.direccion ??
                                                                'N/A',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
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
                            child: _editingSupplier != null || _isAddingSupplier
                                ? _buildSupplierForm(isBottomSheet: false)
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
