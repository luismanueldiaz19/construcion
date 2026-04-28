import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class GastoProyectoDialog extends StatefulWidget {
  final Map<String, dynamic> proyecto;
  const GastoProyectoDialog({super.key, required this.proyecto});

  @override
  State<GastoProyectoDialog> createState() => _GastoProyectoDialogState();
}

class _GastoProyectoDialogState extends State<GastoProyectoDialog> {
  final ApiService _apiService = ApiService();
  final _montoController = TextEditingController();
  final _descController = TextEditingController();
  final _searchController = TextEditingController();

  List<dynamic> _cuentasCostos = [];
  List<dynamic> _proveedores = [];
  List<dynamic> _proveedoresFiltrados = [];
  List<dynamic> _bancos = [];
  List<dynamic> _subpartidas = [];

  int? _cuentaCostoId;
  int? _proveedorId;
  int? _bancoId;
  int? _subpartidaId;
  String _metodoPago = 'Transferencia';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subpartidas = (widget.proyecto['partidas'] as List? ?? []).expand((p) {
      final sList = p['subpartidas'] as List? ?? [];
      final pNombre = p['nombre'] ?? p['descripcion'] ?? 'Partida';
      return sList.map((s) => {...s, 'partida_nombre': pNombre});
    }).toList();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _apiService.getCatalogo(),
        _apiService.getProveedores(),
        _apiService.getBancos(),
      ]);

      setState(() {
        final rawCatalogo = results[0] as List;
        print("DEBUG: Total cuentas en catálogo: ${rawCatalogo.length}");

        // Filtrar solo cuentas de COSTOS (5.xx) que sean de detalle
        _cuentasCostos = rawCatalogo.where((c) {
          final isDetalle =
              c['es_detalle'].toString() == '1' || c['es_detalle'] == true;
          final isCosto = c['codigo'].toString().startsWith('5');
          return isCosto && isDetalle;
        }).toList();

        print(
          "DEBUG: Cuentas de COSTOS (detalle) encontradas: ${_cuentasCostos.length}",
        );
        if (_cuentasCostos.isNotEmpty) {
          print("DEBUG: Primera cuenta: ${_cuentasCostos[0]}");
        }

        _proveedores = results[1] as List;
        _proveedoresFiltrados = _proveedores;

        _bancos = (results[2] as List)
            .where((b) => b['nombre'].toString().contains('Banco'))
            .toList();
        if (_bancos.isNotEmpty) _bancoId = _bancos[0]['id'];

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
      }
    }
  }

  void _filterProveedores(String query) {
    setState(() {
      _proveedoresFiltrados = _proveedores
          .where(
            (p) => p['nombre'].toString().toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E2E),
      title: const Text(
        'Registrar Gasto Contable',
        style: TextStyle(color: Colors.orangeAccent),
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // BUSCADOR DE PROVEEDORES
              const Text(
                'Proveedor / Trabajador',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Buscar proveedor...',
                        prefixIcon: Icon(Icons.search, color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                      onChanged: _filterProveedores,
                    ),
                    if (_searchController.text.isNotEmpty ||
                        _proveedorId == null)
                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                          itemCount: _proveedoresFiltrados.length,
                          itemBuilder: (context, index) {
                            final p = _proveedoresFiltrados[index];
                            return ListTile(
                              title: Text(
                                p['nombre'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                              selected: _proveedorId == p['id'],
                              onTap: () {
                                setState(() {
                                  _proveedorId = p['id'];
                                  _searchController.text = p['nombre'];
                                  _proveedoresFiltrados = [];
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // CUENTA CONTABLE DE COSTO
              DropdownButtonFormField<int>(
                value: _cuentaCostoId,
                dropdownColor: const Color(0xFF1E1E2E),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Tipo de Gasto (Cuenta Contable)',
                  labelStyle: TextStyle(color: Colors.white60),
                ),
                items: _cuentasCostos
                    .map(
                      (c) => DropdownMenuItem(
                        value: c['id'] as int,
                        child: Text(
                          "${c['codigo']} - ${c['nombre']}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _cuentaCostoId = v),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _descController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Descripción / Nota',
                  labelStyle: TextStyle(color: Colors.white60),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _montoController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monto \$',
                        labelStyle: TextStyle(color: Colors.white60),
                        prefixText: '\$ ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _metodoPago,
                      dropdownColor: const Color(0xFF1E1E2E),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Método',
                        labelStyle: TextStyle(color: Colors.white60),
                      ),
                      items: ['Transferencia', 'Cheque', 'Efectivo', 'Crédito']
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _metodoPago = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_metodoPago != 'Crédito')
                DropdownButtonFormField<int>(
                  value: _bancoId,
                  dropdownColor: const Color(0xFF1E1E2E),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Cuenta de Origen (Banco)',
                    labelStyle: TextStyle(color: Colors.white60),
                  ),
                  items: _bancos
                      .map(
                        (b) => DropdownMenuItem(
                          value: b['id'] as int,
                          child: Text(b['nombre']),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _bancoId = v),
                ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int?>(
                value: _subpartidaId,
                dropdownColor: const Color(0xFF1E1E2E),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Partida Relacionada',
                  labelStyle: TextStyle(color: Colors.white60),
                ),
                items: _subpartidas
                    .map(
                      (s) => DropdownMenuItem<int>(
                        value: s['id'] as int,
                        child: Text(
                          "[${s['partida_nombre']}] ${s['descripcion']}",
                          style: const TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _subpartidaId = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.white54),
          ),
        ),
        ElevatedButton(
          onPressed: _saveGasto,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.black,
          ),
          child: const Text('Guardar Gasto Contable'),
        ),
      ],
    );
  }

  Future<void> _saveGasto() async {
    if (_montoController.text.isEmpty ||
        _cuentaCostoId == null ||
        _proveedorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa los campos obligatorios'),
        ),
      );
      return;
    }

    try {
      await _apiService.createGastoProyecto({
        'proyecto_id': widget.proyecto['id'],
        'subpartida_id': _subpartidaId,
        'proveedor_id': _proveedorId,
        'cuenta_costo_id': _cuentaCostoId, // Enviamos la cuenta contable real
        'monto': double.parse(_montoController.text),
        'tipo_gasto': _cuentasCostos.firstWhere(
          (c) => c['id'] == _cuentaCostoId,
        )['nombre'],
        'descripcion': _descController.text,
        'fecha': DateTime.now().toIso8601String(),
        'metodo_pago': _metodoPago,
        'banco_id': _metodoPago == 'Crédito' ? null : _bancoId,
      });
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
