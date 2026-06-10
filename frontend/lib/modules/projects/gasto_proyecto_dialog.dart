import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/project_service.dart';
import '../../services/accounting_service.dart';
import '../../services/purchase_service.dart';
import '../../models/gasto_proyecto.dart';
import '../../models/proveedor.dart';
import '../../models/proyecto.dart';

class GastoProyectoDialog extends StatefulWidget {
  final Proyecto proyecto;
  const GastoProyectoDialog({super.key, required this.proyecto});

  @override
  State<GastoProyectoDialog> createState() => _GastoProyectoDialogState();
}

class _GastoProyectoDialogState extends State<GastoProyectoDialog> {
  final ProjectService _projectService = ProjectService();
  final AccountingService _accountingService = AccountingService();
  final PurchaseService _purchaseService = PurchaseService();
  final _montoController = TextEditingController();
  final _descController = TextEditingController();
  final _searchController = TextEditingController();

  List<dynamic> _cuentasCostos = [];
  List<Proveedor> _proveedores = [];
  List<Proveedor> _proveedoresFiltrados = [];
  List<dynamic> _bancos = [];
  List<dynamic> _subpartidas = [];

  int? _cuentaCostoId;
  int? _proveedorId;
  int? _bancoId;
  int? _subpartidaId;
  String _metodoPago = 'Transferencia';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subpartidas = widget.proyecto.partidas.expand((p) {
      return p.subpartidas.map(
        (s) => {
          'id': s.id,
          'descripcion': s.descripcion,
          'partida_nombre': p.descripcion,
        },
      );
    }).toList();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _accountingService.getCatalogo(),
        _purchaseService.getProveedores(),
        _accountingService.getBancos(),
      ]);
      setState(() {
        // Filtramos para mostrar solo cuentas que empiezan con '5' (Costos)
        _cuentasCostos = (results[0])
            .where((c) => c['codigo'].toString().startsWith('5'))
            .toList();

        _proveedores = results[1] as List<Proveedor>;
        _bancos = results[2];
        _isLoading = false;

        if (_bancos.isNotEmpty) {
          _bancoId = _bancos[0]['id'];
        }
      });
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterProveedores(String query) {
    setState(() {
      if (query.isEmpty) {
        _proveedoresFiltrados = [];
      } else {
        _proveedoresFiltrados = _proveedores
            .where(
              (p) => p.name.toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
      }
    });
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

    setState(() => _isSaving = true);
    try {
      await _projectService.createGastoProyecto(
        GastoProyecto(
          proyectoId: widget.proyecto.id!,
          subpartidaId: _subpartidaId,
          proveedorId: _proveedorId,
          cuentaCostoId: _cuentaCostoId,
          monto: double.parse(_montoController.text),
          tipoGasto: _cuentasCostos.firstWhere(
            (c) => c['id'] == _cuentaCostoId,
          )['nombre'],
          descripcion: _descController.text,
          fecha: DateTime.now(),
          metodoPago: _metodoPago,
          bancoId: _metodoPago == 'Crédito' ? null : _bancoId,
        ),
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Gasto registrado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: _isLoading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cabecera profesional
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF003366),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Registrar Gastos',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.proyecto.nombre,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sección de Proveedor
                          const Text(
                            'Proveedor / Trabajador',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildProveedorSearch(),
                          const SizedBox(height: 20),

                          // Tipo de Gasto
                          DropdownButtonFormField<int>(
                            value: _cuentaCostoId,
                            decoration: InputDecoration(
                              labelText: 'Tipo de Gasto (Cuenta)',
                              prefixIcon: const Icon(Icons.category_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: _cuentasCostos
                                .map(
                                  (c) => DropdownMenuItem<int>(
                                    value: c['id'] as int,
                                    child: Text(
                                      c['nombre'],
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _cuentaCostoId = v),
                          ),
                          const SizedBox(height: 16),

                          // Descripción
                          TextField(
                            controller: _descController,
                            decoration: InputDecoration(
                              labelText: 'Descripción / Nota',
                              prefixIcon: const Icon(
                                Icons.description_outlined,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Monto y Método
                          Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: TextField(
                                  controller: _montoController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}'),
                                    ),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Monto \$',
                                    prefixIcon: const Icon(Icons.attach_money),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 5,
                                child: DropdownButtonFormField<String>(
                                  value: _metodoPago,
                                  decoration: InputDecoration(
                                    labelText: 'Método',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items:
                                      [
                                            'Transferencia',
                                            'Efectivo',
                                            'Cheque',
                                            'Crédito',
                                          ]
                                          .map(
                                            (m) => DropdownMenuItem(
                                              value: m,
                                              child: Text(
                                                m,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (v) =>
                                      setState(() => _metodoPago = v!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Banco
                          if (_metodoPago != 'Crédito')
                            DropdownButtonFormField<int>(
                              value: _bancoId,
                              decoration: InputDecoration(
                                labelText: 'Cuenta de Origen (Banco)',
                                prefixIcon: const Icon(
                                  Icons.account_balance_outlined,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: _bancos
                                  .map(
                                    (b) => DropdownMenuItem<int>(
                                      value: b['id'] as int,
                                      child: Text(
                                        b['nombre'],
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => _bancoId = v),
                            ),
                          const SizedBox(height: 16),

                          // Partida Relacionada
                          DropdownButtonFormField<int?>(
                            value: _subpartidaId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Partida Relacionada (Opcional)',
                              prefixIcon: const Icon(Icons.link),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: _subpartidas
                                .map(
                                  (s) => DropdownMenuItem<int>(
                                    value: s['id'] as int,
                                    child: Text(
                                      "[${s['partida_nombre']}] ${s['descripcion'] ?? s['nombre']}",
                                      style: const TextStyle(fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _subpartidaId = v),
                          ),
                          const SizedBox(height: 32),

                          // Botón de Guardar
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveGasto,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFFFFA000,
                                ), // Naranja corporativo
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _isSaving
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'GUARDAR GASTO CONTABLE',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProveedorSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _filterProveedores,
            decoration: const InputDecoration(
              hintText: 'Buscar proveedor...',
              prefixIcon: Icon(Icons.search),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          if (_proveedoresFiltrados.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _proveedoresFiltrados.length,
                itemBuilder: (context, index) {
                  final p = _proveedoresFiltrados[index];
                  final isSelected = _proveedorId == p.id;
                  return ListTile(
                    visualDensity: VisualDensity.compact,
                    title: Text(
                      p.name,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        _proveedorId = p.id;
                        _searchController.text = p.name;
                        _proveedoresFiltrados = [];
                      });
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
