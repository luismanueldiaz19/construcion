import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class ProfitLossView extends StatefulWidget {
  const ProfitLossView({super.key});

  @override
  State<ProfitLossView> createState() => _ProfitLossViewState();
}

class _ProfitLossViewState extends State<ProfitLossView> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  int? _selectedProyectoId;
  List<dynamic> _proyectos = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final proyectosData = await _apiService.getProyectos();
      setState(() => _proyectos = proyectosData);
      await _loadData();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getEstadoResultados(proyectoId: _selectedProyectoId);
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _data == null) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Filtrar por Proyecto: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              DropdownButton<int?>(
                value: _selectedProyectoId,
                hint: const Text('Toda la Empresa (Global)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Toda la Empresa (Global)')),
                  ..._proyectos.map((p) => DropdownMenuItem(value: p['id'], child: Text(p['nombre']))),
                ],
                onChanged: (v) {
                  setState(() => _selectedProyectoId = v);
                  _loadData();
                },
              ),
            ],
          ),
        ),
        if (_isLoading) const LinearProgressIndicator(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: _buildReportCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard() {
    if (_data == null) return const Center(child: Text('No hay datos disponibles'));
    final f = NumberFormat.currency(symbol: '\$');

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      const Text('ESTADO DE RESULTADOS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      Text(_selectedProyectoId == null ? 'CONSOLIDADO EMPRESARIAL' : 'PROYECTO ESPECÍFICO', style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
                      Text('Fecha del reporte: ${_data!['fecha_reporte']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      const Divider(height: 40, thickness: 2),
                    ],
                  ),
                ),
                _buildSectionTitle('INGRESOS OPERACIONALES'),
                _buildLine('Ingresos por Proyectos / Construcción', _data!['ingresos'], isSub: true),
                const SizedBox(height: 16),
                _buildTotalLine('TOTAL INGRESOS', _data!['ingresos']),
                
                const SizedBox(height: 40),
                _buildSectionTitle('COSTOS DE VENTAS'),
                _buildLine('Costos de Construcción (Materiales y MO)', _data!['costos'], isSub: true),
                const SizedBox(height: 16),
                _buildTotalLine('TOTAL COSTOS', _data!['costos'], isNegative: true),
                
                const Divider(height: 40, thickness: 2, color: Colors.black12),
                _buildTotalLine('UTILIDAD BRUTA', _data!['utilidad_bruta'], isBold: true, color: Colors.blue[900]),
                
                const SizedBox(height: 40),
                _buildSectionTitle('GASTOS OPERATIVOS'),
                _buildLine('Gastos Administrativos y Otros', _data!['gastos'], isSub: true),
                const SizedBox(height: 16),
                _buildTotalLine('TOTAL GASTOS', _data!['gastos'], isNegative: true),
                
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('UTILIDAD NETA DEL PERIODO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(f.format(_data!['utilidad_neta']), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _data!['utilidad_neta'] >= 0 ? Colors.green[700] : Colors.red)),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey)),
    );
  }

  Widget _buildLine(String label, dynamic value, {bool isSub = false}) {
    final f = NumberFormat.currency(symbol: '\$');
    return Padding(
      padding: EdgeInsets.only(left: isSub ? 24 : 0, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[800])),
          Text(f.format(value)),
        ],
      ),
    );
  }

  Widget _buildTotalLine(String label, dynamic value, {bool isNegative = false, bool isBold = false, Color? color}) {
    final f = NumberFormat.currency(symbol: '\$');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, fontSize: 16)),
        Text(
          "${isNegative ? '(' : ''}${f.format(value)}${isNegative ? ')' : ''}", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)
        ),
      ],
    );
  }
}
