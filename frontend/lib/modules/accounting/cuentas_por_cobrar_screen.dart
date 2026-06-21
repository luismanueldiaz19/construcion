import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';
import '../../services/accounting_service.dart';
import '../../core/constants.dart';
import '../../widgets/quick_date_filter.dart';

class CuentasPorCobrarScreen extends StatefulWidget {
  const CuentasPorCobrarScreen({super.key});

  @override
  State<CuentasPorCobrarScreen> createState() => _CuentasPorCobrarScreenState();
}

class _CuentasPorCobrarScreenState extends State<CuentasPorCobrarScreen> {
  final AccountingService _accountingService = AccountingService();
  List<dynamic> _cuentas = [];
  List<dynamic> _historialGlobal = [];
  List<dynamic> _bancos = [];
  bool _isLoading = true;
  bool _isLoadingHistorial = false;
  bool _isSubmitting = false;
  String _filter = '';
  DateFilterOption _selectedDateFilter = DateFilterOption.todos;

  dynamic _selectedCuenta;
  int? _selectedBancoId;
  DateTime _fechaPago = DateTime.now();
  String _metodoPago = 'Transferencia';
  double _porcentajePago = 100.0;
  PlatformFile? _comprobanteFile;

  final _montoController = TextEditingController();
  final _conceptoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _conceptoController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result != null) {
      setState(() {
        _comprobanteFile = result.files.first;
      });
    }
  }

  void _removeFile() {
    setState(() {
      _comprobanteFile = null;
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _accountingService.getCuentasPorCobrar(),
        _accountingService.getBancos(),
        _accountingService.getAllPagosHistorial(),
      ]);
      final data = results[0];
      final bancosData = results[1];
      final historialData = results[2];

      if (!mounted) return;
      setState(() {
        _cuentas = data;
        _bancos = bancosData;
        _historialGlobal = historialData
            .where((item) => item['tipo'] == 'Cobro')
            .toList();

        // Sincronizar cuenta seleccionada si existe
        if (_selectedCuenta != null) {
          final updated = _cuentas.firstWhere(
            (c) => c['id'] == _selectedCuenta['id'],
            orElse: () => null,
          );
          if (updated != null) {
            _selectedCuenta = updated;
            _montoController.text =
                (double.tryParse(updated['saldo'].toString()) ?? 0)
                    .toStringAsFixed(2);
          } else {
            _selectedCuenta = null;
          }
        }

        // Banco predeterminado
        if (_selectedBancoId == null && _bancos.isNotEmpty) {
          final primerBanco = _bancos.firstWhere(
            (b) => b['nombre'].toString().toLowerCase().contains('banco'),
            orElse: () => _bancos[0],
          );
          _selectedBancoId = primerBanco['id'];
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _confirmDeleteComprobante(int id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar comprobante?'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar el archivo adjunto de este pago? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _accountingService.deleteComprobantePago(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Comprobante eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar comprobante: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  List<dynamic> get _filteredCuentas {
    final pendientes = _cuentas
        .where((c) => (double.tryParse(c['saldo'].toString()) ?? 0) > 0.01)
        .toList();
    if (_filter.isEmpty) return pendientes;
    return pendientes.where((c) {
      final proyecto = c['proyecto'].toString().toLowerCase();
      final cliente = c['cliente'].toString().toLowerCase();
      return proyecto.contains(_filter.toLowerCase()) ||
          cliente.contains(_filter.toLowerCase());
    }).toList();
  }

  void _openPaymentBottomSheet(dynamic cuenta) {
    setState(() {
      _selectedCuenta = cuenta;
      _porcentajePago = 100.0;
      _montoController.text = (double.tryParse(cuenta['saldo'].toString()) ?? 0)
          .toStringAsFixed(2);
      _conceptoController.text = '';
      _fechaPago = DateTime.now();
      _metodoPago = 'Transferencia';
      _comprobanteFile = null;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: _buildPaymentFormPanel(isBottomSheet: true),
          ),
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _selectedCuenta = null;
        });
      }
    });
  }

  Future<void> _submitPago(bool isBottomSheet) async {
    final monto = double.tryParse(_montoController.text) ?? 0;
    final saldo = double.tryParse(_selectedCuenta['saldo'].toString()) ?? 0;

    if (monto <= 0 || _selectedBancoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete los campos correctamente'),
        ),
      );
      return;
    }

    if (monto > (saldo + 0.01)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El monto no puede exceder el saldo (\$${saldo.toStringAsFixed(2)})',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      http.MultipartFile? fileParam;
      if (_comprobanteFile != null) {
        if (_comprobanteFile!.bytes != null) {
          fileParam = http.MultipartFile.fromBytes(
            'comprobante',
            _comprobanteFile!.bytes!,
            filename: _comprobanteFile!.name,
          );
        } else if (_comprobanteFile!.path != null) {
          fileParam = await http.MultipartFile.fromPath(
            'comprobante',
            _comprobanteFile!.path!,
          );
        }
      }

      await _accountingService.createPago({
        'proyecto_id': _selectedCuenta['id'],
        'monto': monto,
        'fecha': DateFormat('yyyy-MM-dd').format(_fechaPago),
        'metodo_pago': _metodoPago,
        'banco_id': _selectedBancoId,
        'comentario': _conceptoController.text,
      }, file: fileParam);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pago registrado correctamente'),
            backgroundColor: Colors.green,
          ),
        );

        if (isBottomSheet) {
          Navigator.pop(context);
        } else {
          setState(() {
            _selectedCuenta = null;
          });
        }
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: '\$');
    final width = MediaQuery.of(context).size.width;
    final isLargeScreen = width > 950;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.textPrimary,
          title: const Text('Cuentas por Cobrar (CXC)'),
          bottom: const TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: [
              Tab(text: 'Pendientes de Cobro'),
              Tab(text: 'Historial General'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar Datos',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildPendientesTab(f, isLargeScreen),
                  _buildHistorialGlobalTab(f),
                ],
              ),
      ),
    );
  }

  Widget _buildPendientesTab(NumberFormat f, bool isLargeScreen) {
    return isLargeScreen
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Columna Izquierda: Tarjetas de resumen, buscador y listado
              Expanded(
                child: Column(
                  children: [
                    _buildSummaryCards(f),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar por proyecto o cliente...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (v) => setState(() => _filter = v),
                      ),
                    ),
                    Expanded(
                      child: _filteredCuentas.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay cuentas por cobrar pendientes',
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _filteredCuentas.length,
                              itemBuilder: (context, index) {
                                final cuenta = _filteredCuentas[index];
                                return _buildCuentaCard(
                                  cuenta,
                                  f,
                                  isLargeScreen,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              // Columna Derecha: Formulario de Registro de Cobro
              Padding(
                padding: const EdgeInsets.only(
                  top: 16.0,
                  right: 16.0,
                  bottom: 16.0,
                ),
                child: SizedBox(
                  width: 460,
                  child: _selectedCuenta != null
                      ? _buildPaymentFormPanel(isBottomSheet: false)
                      : _buildPlaceholderPanel(),
                ),
              ),
            ],
          )
        : Column(
            children: [
              _buildSummaryCards(f),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por proyecto o cliente...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (v) => setState(() => _filter = v),
                ),
              ),
              Expanded(
                child: _filteredCuentas.isEmpty
                    ? const Center(
                        child: Text('No hay cuentas por cobrar pendientes'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredCuentas.length,
                        itemBuilder: (context, index) {
                          final cuenta = _filteredCuentas[index];
                          return _buildCuentaCard(cuenta, f, isLargeScreen);
                        },
                      ),
              ),
            ],
          );
  }

  Widget _buildHistorialGlobalTab(NumberFormat f) {
    if (_isLoadingHistorial) {
      return const Center(child: CircularProgressIndicator());
    }

    final list = _historialGlobal.where((pago) {
      final dateStr = pago['fecha']?.toString();
      if (dateStr == null) return false;
      final date = DateTime.tryParse(dateStr);
      if (date == null) return false;
      return QuickDateFilter.isDateInFilter(date, _selectedDateFilter);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: QuickDateFilter(
                  selectedOption: _selectedDateFilter,
                  onChanged: (option) {
                    setState(() {
                      _selectedDateFilter = option;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(
                  child: Text('No hay cobros en este rango de fecha'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final pago = list[index];
                    final pMonto =
                        double.tryParse(pago['monto'].toString()) ?? 0;
                    final pFecha =
                        DateTime.tryParse(pago['fecha'].toString()) ??
                        DateTime.now();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_downward,
                              size: 20,
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pago['proyecto'] ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Cliente: ${pago['entidad'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${pago['metodo_pago']} • ${DateFormat('dd/MM/yyyy').format(pFecha)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '+${f.format(pMonto)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (pago['original'] != null &&
                              pago['original']['comprobante_path'] != null) ...[
                            IconButton(
                              icon: const Icon(
                                Icons.attachment,
                                color: Colors.blue,
                              ),
                              tooltip: 'Ver Comprobante Original',
                              onPressed: () async {
                                final url = Uri.parse(
                                  '$host/storage/${pago['original']['comprobante_path']}',
                                );
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              tooltip: 'Eliminar Comprobante',
                              onPressed: () =>
                                  _confirmDeleteComprobante(pago['id']),
                            ),
                            const SizedBox(width: 4),
                          ],
                          IconButton(
                            icon: const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.red,
                            ),
                            tooltip: 'Ver Recibo PDF',
                            onPressed: () async {
                              final url = Uri.parse(
                                '$host/api/v1/pagos-historial/Cobro/${pago['id']}/pdf',
                              );
                              if (await canLaunchUrl(url)) {
                                await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(NumberFormat f) {
    double totalPendiente = _cuentas.fold(
      0,
      (sum, item) => sum + (double.tryParse(item['saldo'].toString()) ?? 0),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildSummaryItem(
            'Total por Cobrar',
            f.format(totalPendiente),
            Colors.green[700]!,
            Icons.account_balance_wallet,
          ),
          const SizedBox(width: 16),
          _buildSummaryItem(
            'Proyectos con Saldo',
            _cuentas
                .where(
                  (c) => (double.tryParse(c['saldo'].toString()) ?? 0) > 0.01,
                )
                .length
                .toString(),
            Colors.blue[700]!,
            Icons.business,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCuentaCard(dynamic cuenta, NumberFormat f, bool isLargeScreen) {
    final double saldo = double.tryParse(cuenta['saldo'].toString()) ?? 0;
    final bool isSelected =
        _selectedCuenta != null && _selectedCuenta['id'] == cuenta['id'];

    Color cardColor = isSelected
        ? AppTheme.primaryColor.withValues(alpha: 0.02)
        : Colors.white;

    return Card(
      color: cardColor,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.accentColor : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (isLargeScreen) {
            setState(() {
              _selectedCuenta = cuenta;
              _porcentajePago = 100.0;
              _montoController.text =
                  (double.tryParse(cuenta['saldo'].toString()) ?? 0)
                      .toStringAsFixed(2);
              _conceptoController.text = '';
              _fechaPago = DateTime.now();
              _metodoPago = 'Transferencia';
              _comprobanteFile = null;
            });
          } else {
            _openPaymentBottomSheet(cuenta);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      cuenta['proyecto'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: saldo <= 0 ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cuenta['estado'],
                      style: TextStyle(
                        color: saldo <= 0
                            ? Colors.green[700]
                            : Colors.orange[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Cliente: ${cuenta['cliente']}',
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMontoCol(
                    'Total Contrato',
                    f.format(
                      double.tryParse(cuenta['monto_total'].toString()) ?? 0,
                    ),
                    Colors.black87,
                  ),
                  _buildMontoCol(
                    'Pagado',
                    f.format(
                      double.tryParse(cuenta['monto_pagado'].toString()) ?? 0,
                    ),
                    Colors.green[700]!,
                  ),
                  _buildMontoCol(
                    'Saldo Contrato',
                    f.format(double.tryParse(cuenta['saldo'].toString()) ?? 0),
                    Colors.red[700]!,
                  ),
                ],
              ),
              if (!isLargeScreen && saldo > 0) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openPaymentBottomSheet(cuenta),
                    icon: const Icon(Icons.add_card, size: 16),
                    label: const Text(
                      'REGISTRAR PAGO CLIENTE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMontoCol(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 72,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'Detalles de Cobro',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Seleccione un proyecto de la izquierda para registrar cobros o ver el desglose de su cuenta por cobrar.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentFormPanel({required bool isBottomSheet}) {
    final double saldo =
        double.tryParse(_selectedCuenta['saldo'].toString()) ?? 0;
    final List<dynamic> pagos = _selectedCuenta['pagos'] as List? ?? [];
    final f = NumberFormat.currency(symbol: '\$');

    Widget formContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información de Saldo
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo Pendiente:',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                f.format(saldo),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Slider de porcentaje de pago
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Porcentaje a Cobrar:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '${_porcentajePago.round()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primaryColor,
                      inactiveTrackColor: Colors.grey[200],
                      thumbColor: AppTheme.accentColor,
                      overlayColor: AppTheme.accentColor.withValues(
                        alpha: 0.12,
                      ),
                      valueIndicatorColor: AppTheme.primaryColor,
                      valueIndicatorTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Slider(
                      value: _porcentajePago,
                      min: 0.0,
                      max: 100.0,
                      divisions: 100,
                      label: '${_porcentajePago.round()}%',
                      onChanged: (val) {
                        setState(() {
                          _porcentajePago = val;
                          final nuevoMonto = saldo * (val / 100.0);
                          _montoController.text = nuevoMonto.toStringAsFixed(2);
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            // Botones rápidos (Chips)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [25, 50, 75, 100].map((pct) {
                final bool isSelected = _porcentajePago.round() == pct;
                return ChoiceChip(
                  label: Text('$pct%'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _porcentajePago = pct.toDouble();
                        final nuevoMonto = saldo * (pct / 100.0);
                        _montoController.text = nuevoMonto.toStringAsFixed(2);
                      });
                    }
                  },
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.bold,
                    fontSize: 12,
                  ),
                  backgroundColor: Colors.grey[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey[200]!,
                    ),
                  ),
                  showCheckmark: false,
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Campo de Monto
        TextField(
          controller: _montoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          onChanged: (val) {
            final double typedMonto = double.tryParse(val) ?? 0;
            if (saldo > 0) {
              setState(() {
                _porcentajePago = ((typedMonto / saldo) * 100.0).clamp(
                  0.0,
                  100.0,
                );
              });
            }
          },
          decoration: InputDecoration(
            labelText: 'Monto a Recibir',
            prefixIcon: const Icon(Icons.attach_money),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),

        // Método de Pago y Banco
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: DropdownButtonFormField<String>(
                value: _metodoPago,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Método',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ['Transferencia', 'Cheque']
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(m, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (v) => setState(() => _metodoPago = v!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 6,
              child: DropdownButtonFormField<int>(
                value: _selectedBancoId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Cuenta Destino',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _bancos
                    .map(
                      (b) => DropdownMenuItem<int>(
                        value: b['id'],
                        child: Text(
                          b['nombre'],
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (v) => setState(() => _selectedBancoId = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Selector de Comprobante (Opcional)
        if (_metodoPago == 'Transferencia') ...[
          _comprobanteFile == null
              ? SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Adjuntar Comprobante (Opcional)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _comprobanteFile!.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: _removeFile,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        tooltip: 'Eliminar archivo',
                      ),
                    ],
                  ),
                ),
          const SizedBox(height: 16),
        ],

        // Fecha de Pago
        InkWell(
          onTap: _isSubmitting
              ? null
              : () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _fechaPago,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _fechaPago = picked);
                  }
                },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fecha de Recibo',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(_fechaPago),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Comentario
        TextField(
          controller: _conceptoController,
          decoration: InputDecoration(
            labelText: 'Referencia / Nota',
            prefixIcon: const Icon(Icons.note_alt_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 32),

        // Botón de Registrar Pago
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : () => _submitPago(isBottomSheet),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'CONFIRMAR Y REGISTRAR COBRO',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
        ),

        // Historial de Cobros
        const Divider(height: 40),
        Row(
          children: [
            const Icon(Icons.history, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Historial de Cobros (${pagos.length})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (pagos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No se han registrado cobros para este proyecto.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          Column(
            children: pagos.map<Widget>((pago) {
              final pMonto = double.tryParse(pago['monto'].toString()) ?? 0;
              final pFecha =
                  DateTime.tryParse(pago['fecha'].toString()) ?? DateTime.now();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_downward,
                        size: 16,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pago['banco'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${pago['metodo_pago']} • ${DateFormat('dd/MM/yyyy').format(pFecha)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+${f.format(pMonto)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    if (pago['comprobante_path'] != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.attachment, color: Colors.blue),
                        tooltip: 'Ver Comprobante Original',
                        onPressed: () async {
                          final url = Uri.parse(
                            '$host/storage/${pago['comprobante_path']}',
                          );
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        tooltip: 'Eliminar Comprobante',
                        onPressed: () => _confirmDeleteComprobante(pago['id']),
                      ),
                    ],
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      tooltip: 'Ver Recibo PDF',
                      onPressed: () async {
                        final url = Uri.parse(
                          '$host/api/v1/pagos-historial/Cobro/${pago['id']}/pdf',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );

    final headerSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.add_card, color: AppTheme.accentColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Registrar Cobro',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _selectedCuenta['proyecto'],
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isBottomSheet)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            else
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedCuenta = null),
                tooltip: 'Deseleccionar',
              ),
          ],
        ),
        const Divider(height: 24),
      ],
    );

    if (isBottomSheet) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [headerSection, formContent],
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            headerSection,
            Expanded(child: SingleChildScrollView(child: formContent)),
          ],
        ),
      );
    }
  }
}
