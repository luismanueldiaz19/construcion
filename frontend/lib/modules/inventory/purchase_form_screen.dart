import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';
import '../../services/project_service.dart';
import '../../services/inventory_service.dart';
import '../../services/purchase_service.dart';
import '../../core/constants.dart';
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
  List<dynamic> _proveedores = [];
  List<Map<String, dynamic>> _items = [];

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
        _proyectos = projects.map((p) => p.toJson()).toList(); // Convertir a Map para compatibilidad con el resto del código
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

    try {
      final data = {
        'proveedor_id': _selectedProveedorId,
        'proyecto_id': _selectedProyectoId,
        'fecha': DateFormat('yyyy-MM-dd').format(_fecha),
        'fecha_vencimiento': _fechaVencimiento != null
            ? DateFormat('yyyy-MM-dd').format(_fechaVencimiento!)
            : null,
        'tipo_compra': _tipoCompra,
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

  void _resetForm() {
    setState(() {
      _selectedProveedorId = null;
      _selectedProyectoId = null;
      _tipoCompra = 'Contado';
      _fecha = DateTime.now();
      _fechaVencimiento = null;
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
        title: Text('Nueva Compra de Materiales'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 32),
                          const Text(
                            'Detalle de Materiales',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildItemsList(),
                          const SizedBox(height: 24),
                          _buildTotals(subtotal, itbis, total, f),
                          const SizedBox(height: 32),
                          _buildActions(),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isSubmitting)
                  Container(
                    color: Colors.black.withValues(alpha: 0.1),
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
                              SizedBox(height: 16),
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

  Widget _buildHeader() {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSearchableSelector(
                    label: 'Proveedor',
                    value: _selectedProveedorId,
                    items: _proveedores,
                    onChanged: (v) => setState(() => _selectedProveedorId = v),
                    displayMapper: (p) => p['nombre'],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
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
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
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
                const SizedBox(width: 16),
                Expanded(
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
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_tipoCompra == 'Crédito') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
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
                                  ? DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_fechaVencimiento!)
                                  : 'No seleccionada',
                            ),
                            const Icon(Icons.event_note),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return Column(
      children: [
        ...List.generate(_items.length, (index) => _buildItemRow(index)),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _addItem,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Agregar otro material'),
        ),
      ],
    );
  }

  Widget _buildItemRow(int index) {
    final item = _items[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _buildSearchableSelector(
              label: 'Material',
              value: item['material_id'],
              items: _materiales,
              onChanged: (v) {
                setState(() {
                  item['material_id'] = v;
                  final selectedMaterial = _materiales.firstWhere(
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
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue: item['cantidad'] == 0
                  ? ''
                  : item['cantidad'].toString(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Cant.',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (double.tryParse(v ?? '') ?? 0) <= 0 ? '!' : null,
              onChanged: (v) =>
                  setState(() => item['cantidad'] = double.tryParse(v) ?? 0.0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: TextFormField(
              key: Key("price_${item['material_id']}_$index"),
              initialValue: item['precio_unitario'] == 0
                  ? ''
                  : item['precio_unitario'].toString(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Precio Unit.',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              validator: (v) =>
                  (double.tryParse(v ?? '') ?? 0) <= 0 ? '!' : null,
              onChanged: (v) => setState(
                () => item['precio_unitario'] = double.tryParse(v) ?? 0.0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'ITBIS',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              child: Text(
                NumberFormat('#,###.##').format(
                  (item['cantidad'] * item['precio_unitario']) -
                      (item['cantidad'] * item['precio_unitario'] / 1.18),
                ),
                style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Importe',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              child: Text(
                NumberFormat(
                  '#,###.##',
                ).format(item['cantidad'] * item['precio_unitario']),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _removeItem(index),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchableSelector({
    required String label,
    required dynamic value,
    required List<dynamic> items,
    required Function(dynamic) onChanged,
    required String Function(dynamic) displayMapper,
  }) {
    final selectedItem = items.firstWhere(
      (i) => i['id'] == value,
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
            return "RNC: ${item['rnc'] ?? 'N/A'}";
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
    final nombreController = TextEditingController();
    final rncController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Proveedor Rápido'),
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
            TextField(
              controller: rncController,
              decoration: const InputDecoration(
                labelText: 'RNC/Cédula',
                border: OutlineInputBorder(),
              ),
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
              if (nombreController.text.isEmpty) return;
              try {
                await _purchaseService.createProveedor({
                  'nombre': nombreController.text,
                  'rnc': rncController.text,
                });
                final updatedList = await _purchaseService.getProveedores();
                setState(() => _proveedores = updatedList);
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Proveedor creado')),
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

  Widget _buildTotals(
    double subtotal,
    double itbis,
    double total,
    NumberFormat f,
  ) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blueGrey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildTotalRow('Sub-total:', f.format(subtotal)),
            _buildTotalRow('ITBIS (18%):', f.format(itbis)),
            const Divider(height: 24),
            _buildTotalRow(
              'TOTAL GENERAL:',
              f.format(total),
              isBold: true,
              color: Colors.green[800],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isBold ? 18 : 14,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF003366),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
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
                      color: Color(0xFF003366),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
