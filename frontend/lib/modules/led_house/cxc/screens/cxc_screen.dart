import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/cxc_model.dart';
import '../providers/cxc_provider.dart';
import '../widgets/cxc_form_dialog.dart';
import '../widgets/cxc_soporte_dialog.dart';
import '../../../../widgets/hover_total_card.dart';

class CxcScreen extends StatefulWidget {
  const CxcScreen({super.key});

  @override
  State<CxcScreen> createState() => _CxcScreenState();
}

class _CxcScreenState extends State<CxcScreen> {
  final currencyFormatter = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  String _searchQuery = '';
  String _statusFilter = 'Todos';
  bool _soloVencidos = false;
  bool _conVisita = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CxcProvider>(context, listen: false).fetchCxcs();
    });
  }

  void _showFormDialog([cxc]) {
    showDialog(
      context: context,
      builder: (_) => CxcFormDialog(cxc: cxc),
    );
  }

  void _showSoporteDialog(cxc) {
    showDialog(
      context: context,
      builder: (_) => CxcSoporteDialog(cxc: cxc),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pagado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  bool _isPastDue(String dateStr, String status) {
    if (status.toLowerCase() != 'pendiente') return false;
    try {
      final date = DateTime.parse(dateStr);
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      return date.isBefore(todayDate);
    } catch (e) {
      return false;
    }
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n');
  }

  List<CxcModel> _getFilteredList(List<CxcModel> list) {
    return list.where((cxc) {
      bool matchesStatus =
          _statusFilter == 'Todos' ||
          cxc.estado.toLowerCase() == _statusFilter.toLowerCase();
      if (!matchesStatus) return false;

      if (_soloVencidos && !_isPastDue(cxc.fechaVencimiento, cxc.estado)) {
        return false;
      }

      if (_conVisita && cxc.ultimaFechaVisita == null) {
        return false;
      }

      if (_searchQuery.isEmpty) return true;

      final normalizedQuery = _normalizeText(_searchQuery);
      final normalizedCliente = _normalizeText(cxc.cliente);
      final normalizedDocumento = _normalizeText(cxc.documento);

      return normalizedCliente.contains(normalizedQuery) ||
          normalizedDocumento.contains(normalizedQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cuentas por Cobrar (CXC)',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                Provider.of<CxcProvider>(context, listen: false).fetchCxcs(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Consumer<CxcProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.cxcs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.cxcs.isEmpty) {
            return Center(
              child: Text(
                'Error: ${provider.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final filteredCxcs = _getFilteredList(provider.cxcs);

          double totalFactura = 0;
          double totalPendiente = 0;
          double totalVencido = 0;
          int totalIntervenciones = 0;

          for (var cxc in filteredCxcs) {
            totalFactura += cxc.montoFactura;
            totalPendiente += cxc.montoPendiente;
            if (_isPastDue(cxc.fechaVencimiento, cxc.estado)) {
              totalVencido += cxc.montoPendiente;
            }
            totalIntervenciones += cxc.totalIntervenciones;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Listado de Cuentas por Cobrar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: 'Buscar por cliente o documento',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0,
                                    horizontal: 12,
                                  ),
                                ),
                                onChanged: (val) {
                                  setState(() => _searchQuery = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 200,
                              child: DropdownButtonFormField<String>(
                                value: _statusFilter,
                                decoration: InputDecoration(
                                  labelText: 'Estado',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0,
                                    horizontal: 12,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Todos',
                                    child: Text('Todos'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'pendiente',
                                    child: Text('Pendiente'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'pagado',
                                    child: Text('Pagado'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'cancelado',
                                    child: Text('Cancelado'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _statusFilter = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: _soloVencidos,
                                  onChanged: (val) {
                                    setState(() => _soloVencidos = val ?? false);
                                  },
                                ),
                                const Text('Solo Vencidos'),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: _conVisita,
                                  onChanged: (val) {
                                    setState(() => _conVisita = val ?? false);
                                  },
                                ),
                                const Text('Con Visita Programada'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              Colors.grey.shade100,
                            ),
                            columns: const [
                              DataColumn(label: Text('Documento')),
                              DataColumn(label: Text('Cliente')),
                              DataColumn(label: Text('Monto Factura')),
                              DataColumn(label: Text('Monto Pendiente')),
                              DataColumn(label: Text('Vencimiento')),
                              DataColumn(label: Text('Estado')),
                              DataColumn(label: Text('Intervenciones')),
                              DataColumn(label: Text('Próx. Visita')),
                              DataColumn(label: Text('Acciones')),
                            ],
                            rows: filteredCxcs.map((cxc) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      cxc.documento,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(cxc.cliente)),
                                  DataCell(
                                    Text(
                                      currencyFormatter.format(
                                        cxc.montoFactura,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      currencyFormatter.format(
                                        cxc.montoPendiente,
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: cxc.montoPendiente <= 0
                                            ? Colors.green
                                            : Colors.deepOrange,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          cxc.fechaVencimiento,
                                          style: TextStyle(
                                            color:
                                                _isPastDue(
                                                  cxc.fechaVencimiento,
                                                  cxc.estado,
                                                )
                                                ? Colors.red
                                                : null,
                                            fontWeight:
                                                _isPastDue(
                                                  cxc.fechaVencimiento,
                                                  cxc.estado,
                                                )
                                                ? FontWeight.bold
                                                : null,
                                          ),
                                        ),
                                        if (_isPastDue(
                                          cxc.fechaVencimiento,
                                          cxc.estado,
                                        )) ...[
                                          const SizedBox(width: 4),
                                          const Tooltip(
                                            message: 'Vencido',
                                            child: Icon(
                                              Icons.warning_amber_rounded,
                                              color: Colors.red,
                                              size: 16,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          cxc.estado,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        cxc.estado.toUpperCase(),
                                        style: TextStyle(
                                          color: _getStatusColor(cxc.estado),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(cxc.totalIntervenciones.toString()),
                                  ),
                                  DataCell(
                                    Text(cxc.ultimaFechaVisita ?? 'N/A'),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.support_agent,
                                            color: Colors.blue,
                                          ),
                                          tooltip: 'Gestión de Cobro',
                                          onPressed: () =>
                                              _showSoporteDialog(cxc),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.orange,
                                          ),
                                          tooltip: 'Editar / Pagar',
                                          onPressed: () => _showFormDialog(cxc),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HoverTotalCard(
                        title: 'TOTAL FACTURADO',
                        value: currencyFormatter.format(totalFactura),
                        color: Colors.blue,
                        icon: Icons.receipt_long,
                      ),
                      const SizedBox(width: 16),
                      HoverTotalCard(
                        title: 'TOTAL PENDIENTE',
                        value: currencyFormatter.format(totalPendiente),
                        color: Colors.orange.shade700,
                        icon: Icons.account_balance_wallet,
                      ),
                      const SizedBox(width: 16),
                      HoverTotalCard(
                        title: 'DEUDA VENCIDA',
                        value: currencyFormatter.format(totalVencido),
                        color: Colors.red,
                        icon: Icons.warning_amber_rounded,
                      ),
                      const SizedBox(width: 16),
                      HoverTotalCard(
                        title: 'INTERVENCIONES',
                        value: totalIntervenciones.toString(),
                        color: Colors.purple,
                        icon: Icons.support_agent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFormDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva CXC', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
