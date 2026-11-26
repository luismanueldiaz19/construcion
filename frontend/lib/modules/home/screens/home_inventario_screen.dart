import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../models/local_inventory.dart';
import '../../../services/inventory_service.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_text_field.dart';
import '../../inventory/local_inventory_details_screen.dart';
import '../../inventory/project_inventory_details_screen.dart';

/// Módulo unificado y moderno de Inventario para la barra de navegación del Home.
class HomeInventarioScreen extends StatefulWidget {
  const HomeInventarioScreen({super.key});

  @override
  State<HomeInventarioScreen> createState() => _HomeInventarioScreenState();
}

class _HomeInventarioScreenState extends State<HomeInventarioScreen> {
  final InventoryService _inventoryService = InventoryService();
  final TextEditingController _searchController = TextEditingController();

  int _currentSubTab = 0; // 0 = Materiales, 1 = Almacenes, 2 = Por Obra
  bool _isLoading = true;
  String? _error;

  List<dynamic> _materiales = [];
  List<dynamic> _filteredMateriales = [];
  List<dynamic> _categorias = [];
  List<LocalInventory> _almacenes = [];
  List<dynamic> _inventarioObras = [];

  int? _selectedCategoriaId;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _searchController.addListener(_filterSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _inventoryService.getMateriales(),
        _inventoryService.getCategorias(),
        _inventoryService.getLocalInventories(),
        _inventoryService.getInventarioPorProyecto(),
      ]);

      if (mounted) {
        setState(() {
          _materiales = results[0];
          _categorias = results[1];
          _almacenes = results[2] as List<LocalInventory>;
          _inventarioObras = results[3];
          _isLoading = false;
          _filterSearch();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error al cargar inventario: $e';
        });
      }
    }
  }

  void _filterSearch() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (_currentSubTab == 0) {
        _filteredMateriales = _materiales.where((m) {
          final nombre = (m['nombre'] ?? '').toString().toLowerCase();
          final codigo = (m['codigo'] ?? '').toString().toLowerCase();
          final matchesQuery = query.isEmpty ||
              nombre.contains(query) ||
              codigo.contains(query);
          final matchesCat = _selectedCategoriaId == null ||
              m['categoria_id'] == _selectedCategoriaId;
          return matchesQuery && matchesCat;
        }).toList();
      }
    });
  }

  void _openCreateMaterialDialog() {
    final codigoCtrl = TextEditingController(
      text: 'MAT-${(DateTime.now().millisecondsSinceEpoch % 100000).toString().padLeft(5, '0')}',
    );
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    final unidadCtrl = TextEditingController(text: 'Unidad');
    int? catId = _categorias.isNotEmpty ? _categorias.first['id'] as int : null;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabecera Neo ERP
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF1E293B), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE31E24),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.add_box_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NUEVO MATERIAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                            SizedBox(height: 1.5),
                            Text(
                              'Registre un insumo o producto en el catálogo',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(dialogCtx),
                      ),
                    ],
                  ),
                ),

                // Formulario
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        AppTextField(
                          controller: codigoCtrl,
                          labelText: 'CÓDIGO *',
                          prefixIconData: Icons.qr_code_rounded,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: nombreCtrl,
                          labelText: 'NOMBRE DEL MATERIAL *',
                          hintText: 'Ej. Cemento Gris, Varilla 3/8...',
                          prefixIconData: Icons.category_rounded,
                        ),
                        const SizedBox(height: 14),
                        if (_categorias.isNotEmpty)
                          AppDropdown<int>(
                            labelText: 'CATEGORÍA *',
                            value: catId,
                            isExpanded: true,
                            prefixIconData: Icons.folder_open_rounded,
                            items: _categorias
                                .map(
                                  (c) => DropdownMenuItem<int>(
                                    value: c['id'] as int,
                                    child: Text(
                                      c['nombre']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setDlgState(() => catId = v),
                          ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: AppTextField(
                                controller: precioCtrl,
                                labelText: 'COSTO ESTIMADO (RD\$) *',
                                hintText: '0.00',
                                prefixIconData: Icons.monetization_on_outlined,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 5,
                              child: AppTextField(
                                controller: unidadCtrl,
                                labelText: 'UNIDAD DE MEDIDA',
                                hintText: 'Ej. Funda, m³, Unidad',
                                prefixIconData: Icons.straighten_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: descCtrl,
                          labelText: 'DESCRIPCIÓN ADICIONAL',
                          hintText: 'Especificaciones técnicas o marca...',
                          prefixIconData: Icons.notes_rounded,
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(
                      top: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton(
                        text: 'Cancelar',
                        variant: AppButtonVariant.outlined,
                        onPressed: () => Navigator.pop(dialogCtx),
                      ),
                      const SizedBox(width: 10),
                      AppButton(
                        text: 'Guardar Material',
                        icon: Icons.check_circle_outline_rounded,
                        variant: AppButtonVariant.primary,
                        isLoading: isSaving,
                        onPressed: () async {
                          if (nombreCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('El nombre es obligatorio.'),
                                backgroundColor: Color(0xFFDC2626),
                              ),
                            );
                            return;
                          }
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(dialogCtx);
                          setDlgState(() => isSaving = true);
                          try {
                            await _inventoryService.createMaterial({
                              'codigo': codigoCtrl.text.trim(),
                              'nombre': nombreCtrl.text.trim(),
                              'descripcion': descCtrl.text.trim(),
                              'categoria_id': catId,
                              'unidad': unidadCtrl.text.trim(),
                              'precio_costo':
                                  double.tryParse(precioCtrl.text.trim()) ?? 0.0,
                              'stock_global': 0,
                              'estado': true,
                            });
                            if (mounted) {
                              navigator.pop();
                              _loadAllData();
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Material creado con éxito'),
                                  backgroundColor: Color(0xFF16A34A),
                                ),
                              );
                            }
                          } catch (e) {
                            setDlgState(() => isSaving = false);
                            if (mounted) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: const Color(0xFFDC2626),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openCreateAlmacenDialog() {
    final nombreCtrl = TextEditingController();
    final ubicacionCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabecera Neo ERP
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF1E293B), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE31E24),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.warehouse_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NUEVO ALMACÉN / DEPÓSITO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                            SizedBox(height: 1.5),
                            Text(
                              'Almacén para herramientas y materiales',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(dialogCtx),
                      ),
                    ],
                  ),
                ),

                // Formulario
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      AppTextField(
                        controller: nombreCtrl,
                        labelText: 'NOMBRE DEL ALMACÉN *',
                        hintText: 'Ej. Almacén Central, Depósito 1...',
                        prefixIconData: Icons.store_rounded,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: ubicacionCtrl,
                        labelText: 'UBICACIÓN FÍSICA',
                        hintText: 'Ej. Sede Central, Nave B...',
                        prefixIconData: Icons.location_on_outlined,
                      ),
                    ],
                  ),
                ),

                // Footer
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(
                      top: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton(
                        text: 'Cancelar',
                        variant: AppButtonVariant.outlined,
                        onPressed: () => Navigator.pop(dialogCtx),
                      ),
                      const SizedBox(width: 10),
                      AppButton(
                        text: 'Crear Almacén',
                        icon: Icons.check_circle_outline_rounded,
                        variant: AppButtonVariant.primary,
                        isLoading: isSaving,
                        onPressed: () async {
                          if (nombreCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('El nombre es obligatorio.'),
                                backgroundColor: Color(0xFFDC2626),
                              ),
                            );
                            return;
                          }
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(dialogCtx);
                          setDlgState(() => isSaving = true);
                          try {
                            await _inventoryService.createLocalInventory({
                              'name_inventario': nombreCtrl.text.trim(),
                              'location': ubicacionCtrl.text.trim(),
                            });
                            if (mounted) {
                              navigator.pop();
                              _loadAllData();
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Almacén creado con éxito'),
                                  backgroundColor: Color(0xFF16A34A),
                                ),
                              );
                            }
                          } catch (e) {
                            setDlgState(() => isSaving = false);
                            if (mounted) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: const Color(0xFFDC2626),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE31E24),
          strokeWidth: 2.5,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Color(0xFFDC2626),
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'Reintentar',
                icon: Icons.refresh_rounded,
                variant: AppButtonVariant.primary,
                onPressed: _loadAllData,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFE31E24),
      onRefresh: _loadAllData,
      child: Column(
        children: [
          // Selector de Subpestañas Superior
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Column(
              children: [
                // Segmentos
                Row(
                  children: [
                    Expanded(
                      child: _buildSubTabButton(
                        index: 0,
                        icon: Icons.category_rounded,
                        label: 'Materiales (${_materiales.length})',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSubTabButton(
                        index: 1,
                        icon: Icons.warehouse_rounded,
                        label: 'Almacenes (${_almacenes.length})',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSubTabButton(
                        index: 2,
                        icon: Icons.apartment_rounded,
                        label: 'En Obras (${_inventarioObras.length})',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Buscador y Acción rápida según la subpestaña
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _searchController,
                        hintText: _currentSubTab == 0
                            ? 'Buscar por nombre o código de material...'
                            : _currentSubTab == 1
                                ? 'Filtrar almacenes...'
                                : 'Buscar por nombre de obra...',
                        prefixIconData: Icons.search_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_currentSubTab == 0)
                      AppButton(
                        text: 'Nuevo',
                        icon: Icons.add_rounded,
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.standard,
                        onPressed: _openCreateMaterialDialog,
                      )
                    else if (_currentSubTab == 1)
                      AppButton(
                        text: 'Nuevo',
                        icon: Icons.add_rounded,
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.standard,
                        onPressed: _openCreateAlmacenDialog,
                      ),
                  ],
                ),

                // Categorías de filtro (solo para Materiales)
                if (_currentSubTab == 0 && _categorias.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 30,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCategoryChip(null, 'Todos'),
                        ..._categorias.map(
                          (c) => _buildCategoryChip(
                            c['id'] as int,
                            c['nombre']?.toString() ?? '',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Contenido según la subpestaña activa
          Expanded(
            child: _currentSubTab == 0
                ? _buildMaterialesList()
                : _currentSubTab == 1
                    ? _buildAlmacenesList()
                    : _buildInventarioObrasList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentSubTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _currentSubTab = index;
          _filterSearch();
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F172A)
                : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? const Color(0xFFE31E24) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(int? id, String label) {
    final isSelected = _selectedCategoriaId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategoriaId = id;
            _filterSearch();
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE31E24)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFE31E24)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialesList() {
    if (_filteredMateriales.isEmpty) {
      return const AppEmptyState(
        title: 'No hay materiales encontrados',
        description:
            'Intente con otro término de búsqueda o registre un nuevo material.',
        icon: Icons.inventory_2_outlined,
      );
    }

    final currencyFmt = NumberFormat.currency(symbol: 'RD\$ ');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredMateriales.length,
      itemBuilder: (context, index) {
        final m = _filteredMateriales[index];
        final bool estado = m['estado'] == true || m['estado'] == 1;
        final double precio =
            double.tryParse(m['precio_costo']?.toString() ?? '0') ?? 0.0;
        final int stock =
            int.tryParse(m['stock_global']?.toString() ?? '0') ?? 0;
        final catNombre = m['categoria']?['nombre'] ?? 'General';
        final catColor = _getCategoryColor(catNombre);
        final itemIcon = _getMaterialIcon(m['nombre'] ?? '', catNombre);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  estado ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _openEditMaterialDialog(m),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Icono temático de categoría con indicador sutil de estado
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: catColor.withValues(alpha: 0.2),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          itemIcon,
                          color: estado ? catColor : const Color(0xFF94A3B8),
                          size: 22,
                        ),
                      ),
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: estado
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF94A3B8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Info del Material
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A)
                                    .withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                m['codigo'] ?? 'S/C',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                catNombre,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: catColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          m['nombre'] ?? '',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: estado
                                ? const Color(0xFF0F172A)
                                : const Color(0xFF64748B),
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Unidad: ${m['unidad'] ?? 'Unidad'}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Precios & Stock destacados (Diseño limpio y profesional)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currencyFmt.format(precio),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: stock > 0
                              ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: stock > 0
                                ? const Color(0xFF16A34A)
                                    .withValues(alpha: 0.25)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          stock > 0
                              ? '$stock ${m['unidad'] ?? ''}'
                              : '0 ${m['unidad'] ?? 'und'}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: stock > 0
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Menú popup de opciones
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: Color(0xFF94A3B8),
                    ),
                    splashRadius: 18,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onSelected: (val) async {
                      if (val == 'edit') {
                        _openEditMaterialDialog(m);
                      } else if (val == 'toggle') {
                        final int? id = m['id'];
                        if (id != null) {
                          await _inventoryService.toggleMaterialEstado(id);
                          _loadAllData();
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        height: 36,
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: Color(0xFF0F172A),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Editar material',
                              style: TextStyle(fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        height: 36,
                        child: Row(
                          children: [
                            Icon(
                              estado
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 16,
                              color: estado
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF16A34A),
                            ),
                            SizedBox(width: 8),
                            Text(
                              estado ? 'Desactivar' : 'Activar',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: estado
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openEditMaterialDialog(Map<String, dynamic> material) {
    final int id = material['id'];
    final codigoCtrl = TextEditingController(text: material['codigo'] ?? '');
    final nombreCtrl = TextEditingController(text: material['nombre'] ?? '');
    final descCtrl = TextEditingController(text: material['descripcion'] ?? '');
    final precioCtrl = TextEditingController(
      text: material['precio_costo']?.toString() ?? '0.00',
    );
    final unidadCtrl =
        TextEditingController(text: material['unidad'] ?? 'Unidad');
    int? catId = material['categoria_id'];
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabecera Neo ERP
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF1E293B), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.edit_note_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EDITAR MATERIAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                            SizedBox(height: 1.5),
                            Text(
                              'Actualice código, precios y unidad de medida',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(dialogCtx),
                      ),
                    ],
                  ),
                ),

                // Formulario
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        AppTextField(
                          controller: codigoCtrl,
                          labelText: 'CÓDIGO *',
                          prefixIconData: Icons.qr_code_rounded,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: nombreCtrl,
                          labelText: 'NOMBRE DEL MATERIAL *',
                          prefixIconData: Icons.category_rounded,
                        ),
                        const SizedBox(height: 14),
                        if (_categorias.isNotEmpty)
                          AppDropdown<int>(
                            labelText: 'CATEGORÍA *',
                            value: catId,
                            isExpanded: true,
                            prefixIconData: Icons.folder_open_rounded,
                            items: _categorias
                                .map(
                                  (c) => DropdownMenuItem<int>(
                                    value: c['id'] as int,
                                    child: Text(
                                      c['nombre']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setDlgState(() => catId = v),
                          ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: AppTextField(
                                controller: precioCtrl,
                                labelText: 'COSTO ESTIMADO (RD\$) *',
                                prefixIconData: Icons.monetization_on_outlined,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 5,
                              child: AppTextField(
                                controller: unidadCtrl,
                                labelText: 'UNIDAD DE MEDIDA',
                                prefixIconData: Icons.straighten_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: descCtrl,
                          labelText: 'DESCRIPCIÓN ADICIONAL',
                          prefixIconData: Icons.notes_rounded,
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(
                      top: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton(
                        text: 'Cancelar',
                        variant: AppButtonVariant.outlined,
                        onPressed: () => Navigator.pop(dialogCtx),
                      ),
                      const SizedBox(width: 10),
                      AppButton(
                        text: 'Guardar Cambios',
                        icon: Icons.check_circle_outline_rounded,
                        variant: AppButtonVariant.primary,
                        isLoading: isSaving,
                        onPressed: () async {
                          if (nombreCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('El nombre es obligatorio.'),
                                backgroundColor: Color(0xFFDC2626),
                              ),
                            );
                            return;
                          }
                          final scaffoldMessenger =
                              ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(dialogCtx);
                          setDlgState(() => isSaving = true);
                          try {
                            await _inventoryService.updateMaterial(id, {
                              'codigo': codigoCtrl.text.trim(),
                              'nombre': nombreCtrl.text.trim(),
                              'descripcion': descCtrl.text.trim(),
                              'categoria_id': catId,
                              'unidad': unidadCtrl.text.trim(),
                              'precio_costo':
                                  double.tryParse(precioCtrl.text.trim()) ??
                                      0.0,
                            });
                            if (mounted) {
                              navigator.pop();
                              _loadAllData();
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('✅ Material actualizado con éxito'),
                                  backgroundColor: Color(0xFF16A34A),
                                ),
                              );
                            }
                          } catch (e) {
                            setDlgState(() => isSaving = false);
                            if (mounted) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: const Color(0xFFDC2626),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getMaterialIcon(String nombre, String categoria) {
    final n = nombre.toLowerCase();
    final c = categoria.toLowerCase();
    if (n.contains('cemento') ||
        c.contains('cemento') ||
        n.contains('arena') ||
        n.contains('grava')) {
      return Icons.grain_rounded;
    } else if (n.contains('alambre') ||
        n.contains('varilla') ||
        n.contains('clavo') ||
        n.contains('acero') ||
        n.contains('block')) {
      return Icons.construction_rounded;
    } else if (n.contains('pvc') ||
        n.contains('tubo') ||
        c.contains('plomer')) {
      return Icons.plumbing_rounded;
    } else if (n.contains('pint') || c.contains('pint')) {
      return Icons.format_paint_rounded;
    } else if (n.contains('cable') || c.contains('electr')) {
      return Icons.bolt_rounded;
    }
    return Icons.inventory_2_outlined;
  }

  Color _getCategoryColor(String categoria) {
    final c = categoria.toLowerCase();
    if (c.contains('plomer')) return const Color(0xFF0284C7);
    if (c.contains('electr')) return const Color(0xFFD97706);
    if (c.contains('gris') || c.contains('cemento')) {
      return const Color(0xFF475569);
    }
    if (c.contains('pint')) return const Color(0xFF7C3AED);
    if (c.contains('herram')) return const Color(0xFFEA580C);
    return const Color(0xFF2563EB);
  }

  Widget _buildAlmacenesList() {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _almacenes.where((a) {
      return query.isEmpty ||
          a.nameInventario.toLowerCase().contains(query) ||
          a.location.toLowerCase().contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return const AppEmptyState(
        title: 'No hay almacenes registrados',
        description:
            'Cree un almacén o depósito para gestionar herramientas y materiales.',
        icon: Icons.warehouse_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final inv = filtered[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE31E24).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.warehouse_rounded,
                color: Color(0xFFE31E24),
                size: 24,
              ),
            ),
            title: Text(
              inv.nameInventario,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF0F172A),
              ),
            ),
            subtitle: Text(
              inv.location.isNotEmpty
                  ? 'Ubicación: ${inv.location}'
                  : 'Sin ubicación física especificada',
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
            ),
            onTap: () async {
              if (inv.id != null) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocalInventoryDetailsScreen(
                      inventoryId: inv.id!,
                      inventoryName: inv.nameInventario,
                    ),
                  ),
                );
                _loadAllData();
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildInventarioObrasList() {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _inventarioObras.where((p) {
      final nombre = (p['nombre'] ?? '').toString().toLowerCase();
      return query.isEmpty || nombre.contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return const AppEmptyState(
        title: 'No se encontraron obras',
        description:
            'No hay proyectos con registros de inventario asignados.',
        icon: Icons.apartment_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final proj = filtered[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.apartment_rounded,
                color: Color(0xFF0F172A),
                size: 24,
              ),
            ),
            title: Text(
              proj['nombre'] ?? 'Sin nombre',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF0F172A),
              ),
            ),
            subtitle: const Text(
              'Ver balance de materiales y movimientos de obra',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
            ),
            onTap: () async {
              final int? id = proj['id'];
              if (id != null) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProjectInventoryDetailsScreen(
                      proyectoId: id,
                      proyectoNombre: proj['nombre'] ?? '',
                    ),
                  ),
                );
                _loadAllData();
              }
            },
          ),
        );
      },
    );
  }
}
