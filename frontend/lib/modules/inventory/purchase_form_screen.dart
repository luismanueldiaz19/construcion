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

    setState(() => _isSubmitting = true);

    // Validar que todos los ítems tengan un material seleccionado
    bool allItemsValid = _items.every((item) => item['material_id'] != null);
    if (!allItemsValid) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
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
        ScaffoldMessenger.of(context).showSnackBar(
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: '\$');
    double total = _items.fold(
      0,
      (sum, item) => sum + (item['cantidad'] * item['precio_unitario']),
    );
    double subtotal = total / 1.18;
    double itbis = total - subtotal;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Nueva Compra de Materiales'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: AbsorbPointer(
                    absorbing: _isSubmitting,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeaderCard(),
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
                                  color: Color(0xFF003366),
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

  Widget _buildHeaderCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF1E4D7B), // Color azul oscuro del modelo
            child: const Text(
              'Detalles de Compra',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: 350,
                      child: _buildSearchableSelector(
                        label: 'Proveedor',
                        value: _selectedProveedorId,
                        items: _proveedores,
                        onChanged: (v) => setState(() => _selectedProveedorId = v),
                        displayMapper: (p) => p.nombre,
                      ),
                    ),
                    SizedBox(
                      width: 350,
                      child: DropdownButtonFormField<int>(
                        value: _selectedProyectoId,
                        decoration: const InputDecoration(
                          labelText: 'Proyecto Destino',
                          border: OutlineInputBorder(),
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
                    ),
                    SizedBox(
                      width: 350,
                      child: DropdownButtonFormField<String>(
                        value: _tipoCompra,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Compra',
                          border: OutlineInputBorder(),
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
                    ),
                    SizedBox(
                      width: 350,
                      child: InkWell(
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
                          decoration: const InputDecoration(
                            labelText: 'Fecha de Factura',
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('dd/MM/yyyy').format(_fecha)),
                              const Icon(Icons.calendar_today, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_tipoCompra == 'Crédito') ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 350,
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate:
                                _fechaVencimiento ??
                                _fecha.add(const Duration(days: 30)),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setState(() => _fechaVencimiento = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha de Vencimiento',
                            border: OutlineInputBorder(),
                            hintText: 'Seleccione fecha de vencimiento',
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fechaVencimiento != null
                                    ? DateFormat('dd/MM/yyyy').format(_fechaVencimiento!)
                                    : 'No seleccionada',
                              ),
                              const Icon(Icons.event_note, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: 228,
                      child: TextField(
                        controller: _ordenController,
                        decoration: const InputDecoration(
                          labelText: 'Orden #',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.receipt_long, size: 18),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 228,
                      child: TextField(
                        controller: _codigoController,
                        decoration: const InputDecoration(
                          labelText: 'Código Ref.',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.qr_code, size: 18),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 228,
                      child: TextField(
                        controller: _comprobanteController,
                        decoration: const InputDecoration(
                          labelText: 'Comprobante',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.confirmation_number, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20, color: Color(0xFF1E4D7B)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _notaController,
                    decoration: const InputDecoration(
                      hintText: 'Notas / Observaciones del material...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                  label: const Text('Agregar Material'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E4D7B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
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
                color: Color(0xFF003366),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text('Agregar Material'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
                foregroundColor: Colors.white,
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
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: Scrollbar(
            controller: _horizontalScrollController,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 900,
                  child: Table(
                    columnWidths: const {
                      0: FixedColumnWidth(350), // Material
                      1: FixedColumnWidth(80),  // Cant
                      2: FixedColumnWidth(120), // Precio
                      3: FixedColumnWidth(120), // ITBIS
                      4: FixedColumnWidth(150), // Total
                      5: FixedColumnWidth(50),  // Delete
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
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
            onChanged: (v) {
              // Verificar si el material ya ha sido seleccionado en otra fila
              bool isDuplicate = _items.any(
                (element) => element['material_id'] == v,
              );
              if (isDuplicate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Este material ya ha sido agregado a la lista'),
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
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
            ),
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
            decoration: const InputDecoration(
              prefixText: '\$',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
            ),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue[100]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              NumberFormat(
                '#,###.##',
              ).format(item['cantidad'] * item['precio_unitario']),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
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
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.search),
        ),
        child: Text(
          displayText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selectedItem != null ? Colors.black : Colors.grey[600],
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
    final nombreController = TextEditingController();
    final unidadController = TextEditingController();
    final precioController = TextEditingController();
    final categorias = await _inventoryService.getCategorias();
    int? selectedCatId;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar Material Rápido'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: selectedCatId,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: unidadController,
                      decoration: const InputDecoration(
                        labelText: 'Unidad *',
                        border: OutlineInputBorder(),
                      ),
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
                      decoration: const InputDecoration(
                        labelText: 'Precio',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
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
                if (nombreController.text.isEmpty ||
                    unidadController.text.isEmpty)
                  return;
                try {
                  await _inventoryService.createMaterial({
                    'nombre': nombreController.text,
                    'unidad': unidadController.text.toUpperCase(),
                    'precio_costo':
                        double.tryParse(precioController.text) ?? 0.0,
                    'categoria_id': selectedCatId,
                    'codigo':
                        'GEN-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                  });
                  final updatedList = await _inventoryService.getMateriales();
                  setState(() => _materiales = updatedList);
                  if (mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Material creado')),
                  );
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
      ),
    );
  }

  Widget _buildFooterSection(double subtotal, double itbis, double total, NumberFormat f) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Text(
                  'Detalle compra de Materiales editor\n- mas campos de nota',
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
        color: Colors.blueGrey[50]?.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
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
            color: Colors.green[700],
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
          backgroundColor: const Color(0xFF1E4D7B),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
      ),
    );
  }
}
