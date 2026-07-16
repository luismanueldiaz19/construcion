import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants.dart';
import '../../../widgets/custom_button.dart';

class ConciliacionesScreen extends StatefulWidget {
  const ConciliacionesScreen({super.key});

  @override
  State<ConciliacionesScreen> createState() => _ConciliacionesScreenState();
}

class _ConciliacionesScreenState extends State<ConciliacionesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = true;
  List<Map<String, dynamic>> _mesesCierre = [];

  // Variables for Conciliaciones Tab
  List<dynamic> _bancos = [];
  int? _selectedBancoId;
  int _selectedMonth = DateTime.now().month;
  final TextEditingController _saldoBancoController = TextEditingController(
    text: '0.00',
  );
  List<dynamic> _movimientos = [];
  double _saldoInicial = 0.0;
  bool _isLoadingMovimientos = false;

  double get _saldoConciliado {
    double sum = _saldoInicial;
    for (var mov in _movimientos) {
      if (mov['conciliado'] == true) {
        double debe = double.tryParse(mov['debe'].toString()) ?? 0.0;
        double haber = double.tryParse(mov['haber'].toString()) ?? 0.0;
        sum += (debe - haber);
      }
    }
    return sum;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchCierres();
    _fetchBancos();
  }

  Future<void> _fetchBancos() async {
    try {
      final response = await http.get(
        Uri.parse('$host/api/v1/contabilidad/conciliaciones/bancos'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _bancos = json.decode(response.body);
          if (_bancos.isNotEmpty) {
            _selectedBancoId = _bancos[0]['id'];
            _fetchMovimientos();
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching bancos: $e");
    }
  }

  Future<void> _fetchMovimientos() async {
    if (_selectedBancoId == null) return;
    setState(() {
      _isLoadingMovimientos = true;
    });
    try {
      final response = await http.get(
        Uri.parse(
          '$host/api/v1/contabilidad/conciliaciones/movimientos?banco_id=$_selectedBancoId&anio=$_selectedYear&mes=$_selectedMonth',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _movimientos = data['movimientos'];
          _saldoInicial = double.tryParse(data['saldo_inicial']?.toString() ?? '0.0') ?? 0.0;
          if (data['conciliacion'] != null) {
            _saldoBancoController.text = data['conciliacion']['saldo_banco']
                .toString();
          } else {
            _saldoBancoController.text = '0.00';
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching movimientos: $e");
    } finally {
      setState(() {
        _isLoadingMovimientos = false;
      });
    }
  }

  Future<void> _guardarConciliacion() async {
    double saldoBanco = double.tryParse(_saldoBancoController.text) ?? 0.0;
    List<int> conciliadosIds = _movimientos
        .where((m) => m['conciliado'] == true)
        .map<int>((m) => m['id'] as int)
        .toList();

    try {
      final response = await http.post(
        Uri.parse('$host/api/v1/contabilidad/conciliaciones/guardar'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'banco_id': _selectedBancoId,
          'anio': _selectedYear,
          'mes': _selectedMonth,
          'saldo_banco': saldoBanco,
          'saldo_sistema': _saldoConciliado,
          'movimientos_conciliados': conciliadosIds,
        }),
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conciliación guardada exitosamente')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar conciliación')),
      );
    }
  }

  Future<void> _fetchCierres() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('$host/api/v1/contabilidad/cierres?anio=$_selectedYear'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _mesesCierre = data.map((e) => e as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching cierres: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _toggleCierre(int index) async {
    final mes = _mesesCierre[index];
    final nuevoEstado = mes['estado'] == 'abierto' ? 'cerrado' : 'abierto';

    // Optimistic UI update
    setState(() {
      _mesesCierre[index]['estado'] = nuevoEstado;
    });

    try {
      final response = await http.post(
        Uri.parse('$host/api/v1/contabilidad/cierres/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'anio': _selectedYear,
          'mes': mes['mes'],
          'estado': nuevoEstado,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Error del servidor");
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nuevoEstado == 'cerrado'
                ? 'Mes de ${mes['nombre']} cerrado correctamente. (Candado activo)'
                : 'Mes de ${mes['nombre']} abierto.',
          ),
        ),
      );
    } catch (e) {
      // Revert if error
      setState(() {
        _mesesCierre[index]['estado'] = mes['estado'] == 'abierto'
            ? 'cerrado'
            : 'abierto';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cambiar el estado del periodo.'),
        ),
      );
    }
  }

  Widget _buildCierresTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestión de Cierres Contables',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              DropdownButton<int>(
                value: _selectedYear,
                items: [2025, 2026, 2027].map((int year) {
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(year.toString()),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedYear = newValue!;
                    _fetchCierres();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'El cierre bloquea la creación o edición de transacciones en ese periodo.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: ListView.builder(
                    itemCount: _mesesCierre.length,
                    itemBuilder: (context, index) {
                      final mes = _mesesCierre[index];
                      final isCerrado = mes['estado'] == 'cerrado';
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCerrado
                                ? Colors.red.shade100
                                : Colors.green.shade100,
                            child: Icon(
                              isCerrado ? Icons.lock : Icons.lock_open,
                              color: isCerrado ? Colors.red : Colors.green,
                            ),
                          ),
                          title: Text(
                            '${mes['nombre']} $_selectedYear',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Estado: ${isCerrado ? "CERRADO" : "ABIERTO"}',
                          ),
                          trailing: Switch(
                            value: isCerrado,
                            activeColor: Colors.red,
                            inactiveThumbColor: Colors.green,
                            onChanged: (bool value) {
                              _toggleCierre(index);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildConciliacionesTab() {
    double saldoBanco = double.tryParse(_saldoBancoController.text) ?? 0.0;
    double diferencia = saldoBanco - _saldoConciliado;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Cuenta Bancaria',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedBancoId,
                  items: _bancos
                      .map(
                        (b) => DropdownMenuItem<int>(
                          value: b['id'],
                          child: Text(
                            b['nombre'],
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedBancoId = val;
                    });
                    _fetchMovimientos();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Mes',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedMonth,
                  items: List.generate(
                    12,
                    (index) => DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text(
                        'Mes ${index + 1}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _selectedMonth = val!;
                    });
                    _fetchMovimientos();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _saldoBancoController,
                  decoration: const InputDecoration(
                    labelText: 'Saldo Estado de Cuenta',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) =>
                      setState(() {}), // Trigger rebuild for diferencia
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingMovimientos
                ? const Center(child: CircularProgressIndicator())
                : _movimientos.isEmpty
                ? const Center(
                    child: Text(
                      "No hay movimientos contables en este periodo.",
                    ),
                  )
                : ListView.builder(
                    itemCount: _movimientos.length,
                    itemBuilder: (context, index) {
                      final mov = _movimientos[index];
                      return CheckboxListTile(
                        title: Text('${mov['fecha']} - ${mov['glosa']}'),
                        subtitle: Text(
                          'Debe: \$${mov['debe']} | Haber: \$${mov['haber']}',
                        ),
                        value: mov['conciliado'] ?? false,
                        onChanged: (bool? value) {
                          setState(() {
                            _movimientos[index]['conciliado'] = value;
                          });
                        },
                      );
                    },
                  ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Saldo Inicial: \$${_saldoInicial.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  Text('Saldo Seleccionado: \$${_saldoConciliado.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              Text(
                'Diferencia: \$${diferencia.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: diferencia.abs() < 0.01 ? Colors.green : Colors.red,
                ),
              ),
              Row(
                children: [
                  CustomButton(
                    icon: Icons.picture_as_pdf,
                    text: 'Descargar PDF',
                    isOutlined: true,
                    onPressed: _selectedBancoId == null
                        ? null
                        : () async {
                            final url = Uri.parse(
                              '$host/api/v1/contabilidad/conciliaciones/pdf?banco_id=$_selectedBancoId&anio=$_selectedYear&mes=$_selectedMonth',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No se pudo abrir el PDF'),
                                  ),
                                );
                              }
                            }
                          },
                  ),
                  const SizedBox(width: 8),
                  CustomButton(
                    icon: Icons.save,
                    text: 'Guardar Conciliación',
                    color: diferencia.abs() < 0.01
                        ? Colors.green
                        : Colors.orange,
                    onPressed: _guardarConciliacion,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conciliaciones y Cierres Contables'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.lock_clock), text: "Cierres Contables"),
            Tab(
              icon: Icon(Icons.account_balance_wallet),
              text: "Conciliaciones Bancarias",
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildCierresTab(), _buildConciliacionesTab()],
      ),
    );
  }
}
