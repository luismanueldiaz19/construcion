import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class PurchaseFormScreen extends StatefulWidget {
  const PurchaseFormScreen({super.key});

  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  int? _selectedProveedorId;
  int? _selectedProyectoId;
  String _tipoCompra = 'Contado';
  DateTime _fecha = DateTime.now();

  List<dynamic> _materiales = [];
  List<dynamic> _proyectos = [];
  List<dynamic> _proveedores = [];
  List<Map<String, dynamic>> _items = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _addItem();
  }

  Future<void> _loadData() async {
    try {
      final materials = await _apiService.getMateriales();
      final projects = await _apiService.getProyectos(estado: 'Activo');
      final suppliers = await _apiService.getProveedores();
      setState(() {
        _materiales = materials;
        _proyectos = projects;
        _proveedores = suppliers;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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

    setState(() => _isLoading = true);

    try {
      final data = {
        'proveedor_id': _selectedProveedorId,
        'proyecto_id': _selectedProyectoId,
        'fecha': DateFormat('yyyy-MM-dd').format(_fecha),
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

      await _apiService.createCompra(data);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: '\$');
    double subtotal = _items.fold(
      0,
      (sum, item) => sum + (item['cantidad'] * item['precio_unitario']),
    );
    double itbis = subtotal * 0.18;
    double total = subtotal + itbis;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Compra de Materiales')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
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
                  child: DropdownButtonFormField<int>(
                    value: _selectedProveedorId,
                    decoration: const InputDecoration(
                      labelText: 'Proveedor',
                      border: OutlineInputBorder(),
                    ),
                    items: _proveedores
                        .map(
                          (p) => DropdownMenuItem<int>(
                            value: p['id'],
                            child: Text(p['nombre']),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedProveedorId = v),
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
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<int>(
              value: item['material_id'],
              decoration: const InputDecoration(
                labelText: 'Material',
                border: OutlineInputBorder(),
              ),
              items: _materiales
                  .map(
                    (m) => DropdownMenuItem<int>(
                      value: m['id'],
                      child: Text("${m['nombre']} (${m['unidad']})"),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => item['material_id'] = v),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cant.',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) =>
                  setState(() => item['cantidad'] = double.tryParse(v) ?? 0.0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Precio Unit.',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              onChanged: (v) => setState(
                () => item['precio_unitario'] = double.tryParse(v) ?? 0.0,
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
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF003366),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'PROCESAR COMPRA Y REGISTRAR EN CONTABILIDAD',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
