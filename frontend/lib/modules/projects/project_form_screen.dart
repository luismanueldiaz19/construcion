import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/project_service.dart';
import '../../models/proyecto.dart';
import '../../models/partida.dart';
import '../../models/subpartida.dart';
import '../../core/app_theme.dart';

class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({super.key});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProjectService _projectService = ProjectService();
  int _currentStep = 0;

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
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos requeridos.'),
        ),
      );
      return;
    }

    if (_partidas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes agregar al menos una partida.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final subtotal = _calculateSubtotal();
      final proyecto = Proyecto(
        nombre: _nombreController.text,
        cliente: _clienteController.text,
        ubicacion: _ubicacionController.text,
        presupuestoEstimado: subtotal,
        itbis: double.tryParse(_itbisController.text) ?? 0,
        transporte: double.tryParse(_transporteController.text) ?? 0,
        supervisionTecnica: double.tryParse(_supervisionController.text) ?? 0,
        otrosCostos: double.tryParse(_otrosCostosController.text) ?? 0,
        estado: _estado,
        notas: _notasController.text,
        partidas: _partidas.map((p) {
          return Partida(
            codigo: '',
            descripcion: p['descripcion'],
            subpartidas: (p['subpartidas'] as List).map((s) {
              return Subpartida(
                descripcion: s['descripcion'],
                unidad: s['unidad'],
                cantidad: s['cantidad'],
                costoUnitario: s['costo_unitario'],
                totalPresupuestado: s['cantidad'] * s['costo_unitario'],
              );
            }).toList(),
          );
        }).toList(),
      );

      await _projectService.createProyecto(proyecto);
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
    final f = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);
    double subtotal = _calculateSubtotal();
    double total =
        subtotal +
        (double.tryParse(_itbisController.text) ?? 0) +
        (double.tryParse(_transporteController.text) ?? 0) +
        (double.tryParse(_supervisionController.text) ?? 0) +
        (double.tryParse(_otrosCostosController.text) ?? 0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Nuevo Proyecto / Cotización'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.white.withValues(alpha: 0.95),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: kToolbarHeight + 20),
                      Expanded(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                              primary: AppTheme.primaryColor,
                            ),
                          ),
                          child: Stepper(
                            type: StepperType.horizontal,
                            currentStep: _currentStep,
                            onStepTapped: (step) =>
                                setState(() => _currentStep = step),
                            onStepContinue: () {
                              if (_currentStep < 2) {
                                setState(() => _currentStep += 1);
                              } else {
                                _save();
                              }
                            },
                            onStepCancel: () {
                              if (_currentStep > 0) {
                                setState(() => _currentStep -= 1);
                              }
                            },
                            elevation: 0,
                            controlsBuilder: (context, details) =>
                                const SizedBox.shrink(),
                            steps: [
                              Step(
                                title: const Text('Información'),
                                subtitle: const Text('Datos generales'),
                                isActive: _currentStep >= 0,
                                state: _currentStep > 0
                                    ? StepState.complete
                                    : StepState.indexed,
                                content: _buildHeaderSection(),
                              ),
                              Step(
                                title: const Text('Presupuesto'),
                                subtitle: const Text('Partidas y detalles'),
                                isActive: _currentStep >= 1,
                                state: _currentStep > 1
                                    ? StepState.complete
                                    : StepState.indexed,
                                content: _buildBudgetSection(f),
                              ),
                              Step(
                                title: const Text('Resumen'),
                                subtitle: const Text('Costos e impuestos'),
                                isActive: _currentStep >= 2,
                                state: _currentStep == 2
                                    ? StepState.editing
                                    : StepState.indexed,
                                content: _buildReviewSection(
                                  subtotal,
                                  total,
                                  f,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildBottomBar(total, f),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(double total, NumberFormat f) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'TOTAL ESTIMADO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Text(
                f.format(total),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (_currentStep > 0)
                TextButton(
                  onPressed: () => setState(() => _currentStep -= 1),
                  child: const Text('ATRÁS'),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_currentStep < 2) {
                    setState(() => _currentStep += 1);
                  } else {
                    _save();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(_currentStep == 2 ? 'FINALIZAR' : 'SIGUIENTE'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        _buildSectionTitle(Icons.info_outline, 'Datos Generales'),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _nombreController,
                        label: 'Nombre del Proyecto',
                        icon: Icons.business,
                        validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _estado,
                        decoration: InputDecoration(
                          labelText: 'Estado Inicial',
                          filled: true,
                          fillColor: Colors.grey.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: ['Cotización', 'Activo']
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
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
                      child: _buildTextField(
                        controller: _clienteController,
                        label: 'Cliente',
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _ubicacionController,
                        label: 'Ubicación',
                        icon: Icons.location_on_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _notasController,
                  label: 'Observaciones / Notas',
                  icon: Icons.note_alt_outlined,
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSection(NumberFormat f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(Icons.list_alt, 'Presupuesto Detallado'),
        ..._partidas.asMap().entries.map(
          (e) => _buildPartidaCard(e.key, e.value, f),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            onPressed: _addPartida,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text(
              'NUEVA PARTIDA',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildReviewSection(double subtotal, double total, NumberFormat f) {
    return Column(
      children: [
        _buildSectionTitle(
          Icons.summarize_outlined,
          'Resumen de Costos Indirectos',
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildSummaryItem(
                  'Sub-total Directo',
                  subtotal,
                  f,
                  isHeader: true,
                ),
                const Divider(height: 32),
                _buildCostInputRow(
                  'Transporte (Sugerido 4%)',
                  _transporteController,
                  () => _updateTransporte(subtotal),
                  f,
                ),
                _buildCostInputRow(
                  'ITBIS (Sugerido 18%)',
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
                _buildCostInputRow(
                  'Otros Costos Indirectos',
                  _otrosCostosController,
                  null,
                  f,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildSummaryItem(
                    'TOTAL FINAL ESTIMADO',
                    total,
                    f,
                    isTotal: true,
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPartidaCard(
    int pIndex,
    Map<String, dynamic> partida,
    NumberFormat f,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.02),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  radius: 14,
                  child: Text(
                    '${pIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: partida['descripcion'],
                    onChanged: (v) => partida['descripcion'] = v,
                    decoration: const InputDecoration(
                      hintText: 'Nombre de la Partida (Ej: Cimentación)',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _partidas.removeAt(pIndex)),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...(partida['subpartidas'] as List).asMap().entries.map(
                  (e) => _buildSubpartidaRow(pIndex, e.key, e.value, f),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => setState(
                    () => partida['subpartidas'].add({
                      'descripcion': '',
                      'unidad': 'GL',
                      'cantidad': 0.0,
                      'costo_unitario': 0.0,
                    }),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar Item'),
                ),
              ],
            ),
          ),
        ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: _buildSubField(
              initialValue: sub['descripcion'],
              label: 'Descripción',
              onChanged: (v) => sub['descripcion'] = v,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSubField(
              initialValue: sub['unidad'],
              label: 'Unidad',
              onChanged: (v) => sub['unidad'] = v,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSubField(
              initialValue: sub['cantidad'].toString(),
              label: 'Cant.',
              isNumber: true,
              onChanged: (v) =>
                  setState(() => sub['cantidad'] = double.tryParse(v) ?? 0.0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _buildSubField(
              initialValue: sub['costo_unitario'].toString(),
              label: 'Costo U.',
              isNumber: true,
              onChanged: (v) => setState(
                () => sub['costo_unitario'] = double.tryParse(v) ?? 0.0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(fontSize: 8, color: Colors.grey),
                ),
                FittedBox(
                  child: Text(
                    f.format(rowTotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(
              () => _partidas[pIndex]['subpartidas'].removeAt(sIndex),
            ),
            icon: const Icon(
              Icons.remove_circle_outline,
              color: Colors.orange,
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubField({
    required String initialValue,
    required String label,
    required Function(String) onChanged,
    bool isNumber = false,
  }) {
    return TextFormField(
      initialValue: initialValue == '0.0' ? '' : initialValue,
      onChanged: onChanged,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))]
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 10),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        border: InputBorder.none,
      ),
      style: const TextStyle(fontSize: 12),
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
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (onSuggest != null)
            IconButton(
              onPressed: onSuggest,
              icon: const Icon(
                Icons.auto_fix_high,
                color: Colors.blue,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (v) => setState(() {}),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                prefixText: '\$ ',
                isDense: true,
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.05),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    double value,
    NumberFormat f, {
    bool isHeader = false,
    bool isTotal = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : (isHeader ? 14 : 12),
            fontWeight: isTotal || isHeader
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        Text(
          f.format(value),
          style: TextStyle(
            fontSize: isTotal ? 20 : (isHeader ? 16 : 14),
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
