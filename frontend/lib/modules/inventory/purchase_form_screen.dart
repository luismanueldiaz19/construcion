import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';
import '../../services/project_service.dart';
import '../../services/inventory_service.dart';
import '../../services/purchase_service.dart';
import '../../core/constants.dart';
import '../../widgets/proveedor_dialog.dart';
import '../../models/proveedor.dart';
import '../../widgets/search_selector_dialog.dart';

class PurchaseFormScreen extends StatefulWidget {
  const PurchaseFormScreen({super.key});

  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProjectService _projectService = ProjectService();
  final InventoryService _inventoryService = InventoryService();
  final PurchaseService _purchaseService = PurchaseService();

  int? _selectedProveedorId;
  int? _selectedProyectoId;
  String _tipoCompra = 'Contado';
  DateTime _fecha = DateTime.now();
  DateTime? _fechaVencimiento;

  List<dynamic> _materiales = [];
  List<dynamic> _proyectos = [];
  List<Proveedor> _proveedores = [];
  List<Map<String, dynamic>> _items = [];

  final _ordenController = TextEditingController();
  final _codigoController = TextEditingController();
  final _comprobanteController = TextEditingController();
  final _notaController = TextEditingController();
  final _horizontalScrollController = ScrollController();

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _addItem();
  }

  Future<void> _loadData() async {
    try {
      final materials = await _inventoryService.getMateriales();
      final projects = await _projectService.getProyectos(estado: 'Activo');
      final suppliers = await _purchaseService.getProveedores();
      setState(() {
        _materiales = materials;
        _proyectos = projects
            .map((p) => p.toJson())
            .toList(); // Convertir a Map para compatibilidad con el resto del código
        _proveedores = suppliers;
        _isLoading = false;
      });
    } catch (e) {
      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _addItem() {
    // Validar que el último ítem agregado esté completo antes de permitir agregar otro
    if (_items.isNotEmpty) {
      final lastItem = _items.last;
      if (lastItem['material_id'] == null ||
          (lastItem['cantidad'] ?? 0) <= 0 ||
          (lastItem['precio_unitario'] ?? 0) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Por favor complete el material actual antes de agregar otro',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() {
      _items.add({
        'material_id': null,
        'cantidad': 0.0,
        'precio_unitario': 0.0,
      });
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProveedorId == null || _selectedProyectoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione proveedor y proyecto')),
      );
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() => _isSubmitting = true);

    // Validar que todos los ítems tengan un material seleccionado
    bool allItemsValid = _items.every((item) => item['material_id'] != null);
    if (!allItemsValid) {
      setState(() => _isSubmitting = false);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Hay materiales sin seleccionar en el detalle'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final data = {
        'proveedor_id': _selectedProveedorId,
        'proyecto_id': _selectedProyectoId,
        'fecha': DateFormat('yyyy-MM-dd').format(_fecha),
        'fecha_vencimiento': _fechaVencimiento != null
            ? DateFormat('yyyy-MM-dd').format(_fechaVencimiento!)
            : null,
        'tipo_compra': _tipoCompra,
        'orden': _ordenController.text,
        'codigo': _codigoController.text,
        'comprobante': _comprobanteController.text,
        'nota': _notaController.text,
        'items': _items
            .map(
              (item) => {
                'material_id': item['material_id'],
                'cantidad': item['cantidad'],
                'precio_unitario': item['precio_unitario'],
              },
            )
            .toList(),
      };

      final result = await _purchaseService.createCompra(data);
      if (mounted) {
        final compraId = result['id'];
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Compra registrada con éxito'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'IMPRIMIR TICKET',
              textColor: Colors.white,
              onPressed: () => _openPurchasePdf(compraId),
            ),
          ),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _openPurchasePdf(int compraId) async {
    final url = Uri.parse('$host/api/v1/compras/$compraId/pdf');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el PDF')),
        );
      }
    }
  }

  @override
  void dispose() {
    _ordenController.dispose();
    _codigoController.dispose();
    _comprobanteController.dispose();
    _notaController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _selectedProveedorId = null;
      _selectedProyectoId = null;
      _tipoCompra = 'Contado';
      _fecha = DateTime.now();
      _fechaVencimiento = null;
      _ordenController.clear();
      _codigoController.clear();
      _comprobanteController.clear();
      _notaController.clear();
      _items = [
        {'material_id': null, 'cantidad': 0.0, 'precio_unitario': 0.0},
      ];
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: '\$');
    double total = _items.fold(
      0,
      (sum, item) => sum + (item['cantidad'] * item['precio_unitario']),
    );
    double subtotal = total / 1.18;
    double itbis = total - subtotal;

    final width = MediaQuery.of(context).size.width;
    final isLargeScreen = width > 950;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Nueva Compra de Materiales'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                AbsorbPointer(
                  absorbing: _isSubmitting,
                  child: isLargeScreen
                      ? Form(
                          key: _formKey,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left: items table + totals + button
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildItemsSection(),
                                      const SizedBox(height: 24),
                                      _buildFooterSection(
                                        subtotal,
                                        itbis,
                                        total,
                                        f,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Right: Metadata invoice details card
                              Container(
                                width: 400,
                                padding: const EdgeInsets.only(
                                  top: 24,
                                  right: 24,
                                  bottom: 24,
                                ),
                                child: SingleChildScrollView(
                                  child: _buildHeaderCard(isLargeScreen: true),
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeaderCard(isLargeScreen: false),
                                const SizedBox(height: 24),
                                _buildItemsSection(),
                                const SizedBox(height: 24),
                                _buildFooterSection(subtotal, itbis, total, f),
                              ],
                            ),
                          ),
                        ),
                ),
                if (_isSubmitting)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 24,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                'Registrando Compra...',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildHeaderCard({required bool isLargeScreen}) {
    final List<Widget> fields = [
      _buildSearchableSelector(
        label: 'Proveedor',
        value: _selectedProveedorId,
        items: _proveedores,
        onChanged: (v) => setState(() => _selectedProveedorId = v),
        displayMapper: (p) => p.nombre,
      ),
      DropdownButtonFormField<int>(
        value: _selectedProyectoId,
        decoration: InputDecoration(
          labelText: 'Proyecto Destino',
          prefixIcon: const Icon(Icons.business_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: _proyectos
            .map(
              (p) => DropdownMenuItem<int>(
                value: p['id'],
                child: Text(p['nombre']),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _selectedProyectoId = v),
      ),
      DropdownButtonFormField<String>(
        value: _tipoCompra,
        decoration: InputDecoration(
          labelText: 'Tipo de Compra',
          prefixIcon: const Icon(Icons.payment_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: const [
          DropdownMenuItem(
            value: 'Contado',
            child: Text('Contado (Pago Inmediato)'),
          ),
          DropdownMenuItem(
            value: 'Crédito',
            child: Text('Crédito (Cuenta por Pagar)'),
          ),
        ],
        onChanged: (v) => setState(() => _tipoCompra = v!),
      ),
      InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _fecha,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (date != null) setState(() => _fecha = date);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Fecha de Factura',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          ),
          child: Text(DateFormat('dd/MM/yyyy').format(_fecha)),
        ),
      ),
      if (_tipoCompra == 'Crédito')
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate:
                  _fechaVencimiento ?? _fecha.add(const Duration(days: 30)),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              setState(() => _fechaVencimiento = date);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Fecha de Vencimiento',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.event_note, size: 18),
              hintText: 'Seleccione fecha de vencimiento',
            ),
            child: Text(
              _fechaVencimiento != null
                  ? DateFormat('dd/MM/yyyy').format(_fechaVencimiento!)
                  : 'No seleccionada',
            ),
          ),
        ),
      TextField(
        controller: _ordenController,
        decoration: InputDecoration(
          labelText: 'Orden #',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: const Icon(Icons.receipt_long, size: 18),
        ),
      ),
      TextField(
        controller: _codigoController,
        decoration: InputDecoration(
          labelText: 'Código Ref.',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: const Icon(Icons.qr_code, size: 18),
        ),
      ),
      TextField(
        controller: _comprobanteController,
        decoration: InputDecoration(
          labelText: 'Comprobante',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: const Icon(Icons.confirmation_number, size: 18),
        ),
      ),
      TextField(
        controller: _notaController,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: 'Notas / Observaciones',
          alignLabelWithHint: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: const Icon(Icons.info_outline, size: 18),
        ),
      ),
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: AppTheme.accentColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Detalles de Compra',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: isLargeScreen
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: fields
                        .map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: f,
                          ),
                        )
                        .toList(),
                  )
                : Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: fields
                        .map((f) => SizedBox(width: 350, child: f))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Detalle de Materiales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text('Agregar Material'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Scrollbar(
                controller: _horizontalScrollController,
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth > 850
                            ? constraints.maxWidth - 32
                            : 850,
                      ),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(3.5), // Material
                          1: FlexColumnWidth(1.0), // Cant
                          2: FlexColumnWidth(1.2), // Precio
                          3: FlexColumnWidth(1.2), // ITBIS
                          4: FlexColumnWidth(1.5), // Total
                          5: FlexColumnWidth(0.6), // Delete
                        },
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: [
                          // Header Row
                          TableRow(
                            children: [
                              _buildTableHeader('Descripción del Material'),
                              _buildTableHeader('Cant.'),
                              _buildTableHeader('Precio Unit.'),
                              _buildTableHeader('ITBIS (18%)'),
                              _buildTableHeader('Importe Total'),
                              const SizedBox(), // Empty for delete button
                            ],
                          ),
                          // Data Rows
                          ...List.generate(
                            _items.length,
                            (index) => _buildItemTableRow(index),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(String label) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
          fontSize: 13,
        ),
      ),
    );
  }

  TableRow _buildItemTableRow(int index) {
    final item = _items[index];
    return TableRow(
      children: [
        // Material Selector
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: _buildSearchableSelector(
            label: 'Material',
            value: item['material_id'],
            items: _materiales,
            inTable: true,
            onChanged: (v) {
              // Verificar si el material ya ha sido seleccionado en otra fila
              bool isDuplicate = _items.any(
                (element) => element['material_id'] == v,
              );
              if (isDuplicate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Este material ya ha sido agregado a la lista',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              setState(() {
                item['material_id'] = v;
                final selectedMaterial = _materiales.cast<dynamic>().firstWhere(
                  (m) => m['id'] == v,
                  orElse: () => null,
                );
                if (selectedMaterial != null) {
                  item['precio_unitario'] =
                      double.tryParse(
                        selectedMaterial['precio_costo']?.toString() ?? '0',
                      ) ??
                      0.0;
                }
              });
            },
            displayMapper: (m) => "${m['nombre']} (${m['unidad']})",
          ),
        ),
        // Cantidad
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: TextFormField(
            initialValue: item['cantidad'] == 0
                ? ''
                : item['cantidad'].toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
            ],
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
            validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? '!' : null,
            onChanged: (v) =>
                setState(() => item['cantidad'] = double.tryParse(v) ?? 0.0),
          ),
        ),
        // Precio Unitario
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: TextFormField(
            key: Key("price_${item['material_id']}_$index"),
            initialValue: item['precio_unitario'] == 0
                ? ''
                : item['precio_unitario'].toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              prefixText: '\$',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
            validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? '!' : null,
            onChanged: (v) => setState(
              () => item['precio_unitario'] = double.tryParse(v) ?? 0.0,
            ),
          ),
        ),
        // ITBIS
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: Text(
              NumberFormat('#,###.##').format(
                (item['cantidad'] * item['precio_unitario']) -
                    (item['cantidad'] * item['precio_unitario'] / 1.18),
              ),
              style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
          ),
        ),
        // Total
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.03),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              NumberFormat(
                '#,###.##',
              ).format(item['cantidad'] * item['precio_unitario']),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                fontSize: 13,
              ),
            ),
          ),
        ),
        // Delete Action
        IconButton(
          onPressed: () => _removeItem(index),
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          tooltip: 'Eliminar ítem',
        ),
      ],
    );
  }

  Widget _buildSearchableSelector({
    required String label,
    required dynamic value,
    required List<dynamic> items,
    required Function(dynamic) onChanged,
    required String Function(dynamic) displayMapper,
    bool inTable = false,
  }) {
    final selectedItem = items.cast<dynamic>().firstWhere(
      (i) => (i is Proveedor ? i.id : i['id']) == value,
      orElse: () => null,
    );
    final displayText = selectedItem != null
        ? displayMapper(selectedItem)
        : 'Seleccione $label';

    return InkWell(
      onTap: () => _showSearchDialog(label, items, onChanged, displayMapper),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: inTable ? null : label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(inTable ? 8 : 12),
          ),
          contentPadding: inTable
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 12)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          suffixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
          isDense: inTable,
        ),
        child: Text(
          displayText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selectedItem != null ? Colors.black : Colors.grey[600],
            fontSize: inTable ? 13 : 14,
          ),
        ),
      ),
    );
  }

  void _showSearchDialog(
    String title,
    List<dynamic> items,
    Function(dynamic) onSelect,
    String Function(dynamic) displayMapper,
  ) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => SearchSelectorDialog(
        title: title,
        items: items,
        displayMapper: displayMapper,
        subtitleMapper: (item) {
          if (title == 'Material') {
            return "Código: ${item['codigo'] ?? 'N/A'} | Unidad: ${item['unidad']}";
          }
          if (title == 'Proveedor') {
            return "RNC: ${(item as Proveedor).rnc ?? 'N/A'}";
          }
          return null;
        },
        onAdd: () {
          Navigator.pop(context); // Close search dialog
          if (title == 'Proveedor') {
            _quickAddProveedor();
          } else if (title == 'Material') {
            _quickAddMaterial();
          }
        },
      ),
    );

    if (result != null) {
      onSelect(result);
    }
  }

  void _quickAddProveedor() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProveedorDialog(
        onSaved: () async {
          final updatedList = await _purchaseService.getProveedores();
          setState(() => _proveedores = updatedList);
        },
      ),
    );
  }

  void _quickAddMaterial() async {
    final codigoController = TextEditingController();
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    final unidadController = TextEditingController();
    final precioController = TextEditingController();
    final categorias = await _inventoryService.getCategorias();
    int? selectedCatId;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.add_circle_outline, color: AppTheme.accentColor),
              const SizedBox(width: 8),
              const Text('Agregar Material Rápido'),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codigoController,
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
                  DropdownButtonFormField<int>(
                    value: selectedCatId,
                    decoration: InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    items: categorias
                        .map(
                          (c) => DropdownMenuItem<int>(
                            value: c['id'],
                            child: Text(c['nombre']),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedCatId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(
                        Icons.inventory_2_outlined,
                        size: 20,
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descripcionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Descripción detallada',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
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
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            unidadController.value = unidadController.value
                                .copyWith(text: v.toUpperCase());
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: precioController,
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
                            prefixIcon: const Icon(
                              Icons.attach_money,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
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
              onPressed: () {
                codigoController.dispose();
                nombreController.dispose();
                descripcionController.dispose();
                unidadController.dispose();
                precioController.dispose();
                Navigator.pop(context);
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nombreController.text.isEmpty ||
                    unidadController.text.isEmpty)
                  return;
                try {
                  await _inventoryService.createMaterial({
                    'codigo': codigoController.text.isEmpty
                        ? null
                        : codigoController.text,
                    'nombre': nombreController.text,
                    'descripcion': descripcionController.text.isEmpty
                        ? null
                        : descripcionController.text,
                    'unidad': unidadController.text.toUpperCase(),
                    'precio_costo':
                        double.tryParse(precioController.text) ?? 0.0,
                    'categoria_id': selectedCatId,
                  });
                  final updatedList = await _inventoryService.getMateriales();
                  setState(() => _materiales = updatedList);
                  if (mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Material creado')),
                  );
                  codigoController.dispose();
                  nombreController.dispose();
                  descripcionController.dispose();
                  unidadController.dispose();
                  precioController.dispose();
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterSection(
    double subtotal,
    double itbis,
    double total,
    NumberFormat f,
  ) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Text(
                  'El total incluye ITBIS (18%) calculado de forma automática sobre los materiales aplicables.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
            _buildTotals(subtotal, itbis, total, f),
          ],
        ),
        const SizedBox(height: 24),
        _buildActions(),
      ],
    );
  }

  Widget _buildTotals(
    double subtotal,
    double itbis,
    double total,
    NumberFormat f,
  ) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildTotalRow('Sub-total:', f.format(subtotal)),
          const SizedBox(height: 8),
          _buildTotalRow('ITBIS (18%):', f.format(itbis)),
          const Divider(height: 32),
          _buildTotalRow(
            'TOTAL GENERAL:',
            f.format(total),
            isBold: true,
            color: AppTheme.accentColor,
            fontSize: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
    double fontSize = 14,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black87 : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isBold ? fontSize : 14,
            color: color ?? (isBold ? Colors.black87 : Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'PROCESANDO...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            : const Text(
                'REGISTRAR COMPRA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }
}
