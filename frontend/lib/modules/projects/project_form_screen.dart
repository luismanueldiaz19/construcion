import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({super.key});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _nombreController = TextEditingController();
  final _clienteController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _itbisController = TextEditingController(text: '0');
  final _transporteController = TextEditingController(text: '0');
  final _supervisionController = TextEditingController(text: '0');
  final _otrosCostosController = TextEditingController(text: '0');
  final _notasController = TextEditingController();

  String _estado = 'Cotización';
  List<Map<String, dynamic>> _partidas = [
    {
      'descripcion': '',
      'subpartidas': [
        {
          'descripcion': '',
          'unidad': 'GL',
          'cantidad': 0.0,
          'costo_unitario': 0.0,
        },
      ],
    },
  ];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  void _addPartida() {
    setState(() {
      _partidas.add({
        'descripcion': '',
        'subpartidas': [
          {
            'descripcion': '',
            'unidad': 'GL',
            'cantidad': 0.0,
            'costo_unitario': 0.0,
          },
        ],
      });
    });
  }

  double _calculateSubtotal() {
    double total = 0;
    for (var p in _partidas) {
      for (var s in (p['subpartidas'] as List)) {
        total += (s['cantidad'] as double) * (s['costo_unitario'] as double);
      }
    }
    return total;
  }

  void _updateTransporte(double subtotal) {
    _transporteController.text = (subtotal * 0.04).toStringAsFixed(2);
    setState(() {});
  }

  void _updateItbis(double subtotal) {
    _itbisController.text = (subtotal * 0.18).toStringAsFixed(2);
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_partidas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes agregar al menos una partida al proyecto.'),
        ),
      );
      return;
    }
    for (var p in _partidas) {
      if ((p['subpartidas'] as List).isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Todas las partidas deben tener al menos una sub-partida.',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'nombre': _nombreController.text,
        'cliente': _clienteController.text,
        'ubicacion': _ubicacionController.text,
        'itbis': double.tryParse(_itbisController.text) ?? 0,
        'transporte': double.tryParse(_transporteController.text) ?? 0,
        'supervision_tecnica':
            double.tryParse(_supervisionController.text) ?? 0,

        'otros_costos': double.tryParse(_otrosCostosController.text) ?? 0,
        'estado': _estado,
        'notas': _notasController.text,
        'partidas': _partidas,
      };

      await _apiService.createProyecto(data);
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
    final f = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    double subtotal = _calculateSubtotal();
    double total =
        subtotal +
        (double.tryParse(_itbisController.text) ?? 0) +
        (double.tryParse(_transporteController.text) ?? 0) +
        (double.tryParse(_supervisionController.text) ?? 0) +
        (double.tryParse(_otrosCostosController.text) ?? 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Proyecto / Cotización')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 32),
                    const Text(
                      'Presupuesto Detallado',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._partidas
                        .asMap()
                        .entries
                        .map((e) => _buildPartidaCard(e.key, e.value, f))
                        .toList(),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _addPartida,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Nueva Partida'),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSummaryCard(subtotal, total, f),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003366),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'GUARDAR PROYECTO',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Proyecto',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _estado,
                    decoration: const InputDecoration(
                      labelText: 'Estado Inicial',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Cotización', 'Activo']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _estado = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _clienteController,
                    decoration: const InputDecoration(
                      labelText: 'Cliente',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _ubicacionController,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notasController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observaciones / Notas para el Presupuesto',
                border: OutlineInputBorder(),
                hintText:
                    'Ej: Esta cotización incluye materiales y mano de obra...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartidaCard(
    int pIndex,
    Map<String, dynamic> partida,
    NumberFormat f,
  ) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: partida['descripcion'],
                    onChanged: (v) => partida['descripcion'] = v,
                    decoration: const InputDecoration(
                      labelText: 'Descripción de la Partida',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _partidas.removeAt(pIndex)),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            const Divider(),
            ...(partida['subpartidas'] as List)
                .asMap()
                .entries
                .map((e) => _buildSubpartidaRow(pIndex, e.key, e.value, f))
                .toList(),
            TextButton.icon(
              onPressed: () => setState(
                () => partida['subpartidas'].add({
                  'descripcion': '',
                  'unidad': 'GL',
                  'cantidad': 0.0,
                  'costo_unitario': 0.0,
                }),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Agregar Sub-Partida'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubpartidaRow(
    int pIndex,
    int sIndex,
    Map<String, dynamic> sub,
    NumberFormat f,
  ) {
    double rowTotal =
        (sub['cantidad'] as double) * (sub['costo_unitario'] as double);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: sub['descripcion'],
              onChanged: (v) => sub['descripcion'] = v,
              decoration: const InputDecoration(labelText: 'Descripción'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: sub['unidad'],
              onChanged: (v) => sub['unidad'] = v,
              decoration: const InputDecoration(labelText: 'Unid'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Req.' : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: sub['cantidad'].toString(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (v) =>
                  setState(() => sub['cantidad'] = double.tryParse(v) ?? 0.0),
              decoration: const InputDecoration(labelText: 'Cant'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: sub['costo_unitario'].toString(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (v) => setState(
                () => sub['costo_unitario'] = double.tryParse(v) ?? 0.0,
              ),
              decoration: const InputDecoration(labelText: 'Costo'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  f.format(rowTotal),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(
              () => (partidaAt(pIndex)['subpartidas'] as List).removeAt(sIndex),
            ),
            icon: const Icon(Icons.remove_circle, color: Colors.orange),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> partidaAt(int index) => _partidas[index];

  Widget _buildSummaryCard(double subtotal, double total, NumberFormat f) {
    return Card(
      color: const Color(0xFF003366),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildSummaryRow('Sub-total Directo', subtotal, Colors.white70, f),
            const Divider(color: Colors.white24),
            _buildCostInputRow(
              'Transporte (4% sug.)',
              _transporteController,
              () => _updateTransporte(subtotal),
              f,
            ),
            _buildCostInputRow(
              'ITBIS (18% sug.)',
              _itbisController,
              () => _updateItbis(subtotal),
              f,
            ),
            _buildCostInputRow(
              'Supervisión Técnica',
              _supervisionController,
              null,
              f,
            ),
            _buildCostInputRow('Otros Costos', _otrosCostosController, null, f),
            const Divider(color: Colors.white, thickness: 2),
            _buildSummaryRow(
              'TOTAL PRESUPUESTADO',
              total,
              Colors.greenAccent,
              f,
              isBig: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double value,
    Color color,
    NumberFormat f, {
    bool isBig = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: isBig ? 18 : 14,
              fontWeight: isBig ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            f.format(value),
            style: TextStyle(
              color: color,
              fontSize: isBig ? 24 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostInputRow(
    String label,
    TextEditingController controller,
    VoidCallback? onSuggest,
    NumberFormat f,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          if (onSuggest != null)
            IconButton(
              onPressed: onSuggest,
              icon: const Icon(
                Icons.auto_fix_high,
                color: Colors.blueAccent,
                size: 20,
              ),
            ),
          SizedBox(
            width: 150,
            child: TextField(
              controller: controller,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (v) => setState(() {}),
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                isDense: true,
                prefixText: '\$ ',
                prefixStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
