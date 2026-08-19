import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/cxp_provider.dart';
import '../widgets/cxp_form_dialog.dart';
import '../../../../widgets/hover_total_card.dart';

class CxpScreen extends StatefulWidget {
  const CxpScreen({super.key});

  @override
  State<CxpScreen> createState() => _CxpScreenState();
}

class _CxpScreenState extends State<CxpScreen> {
  final currencyFormatter = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  String _statusFilter = 'Todos';
  String _searchQuery = '';
  bool _soloVencidos = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CxpProvider>(context, listen: false).fetchCxps();
    });
  }

  void _showFormDialog([cxp]) {
    showDialog(
      context: context,
      builder: (_) => CxpFormDialog(cxp: cxp),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cuentas por Pagar (CXP)',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                Provider.of<CxpProvider>(context, listen: false).fetchCxps(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Consumer<CxpProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.cxps.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.cxps.isEmpty) {
            return Center(
              child: Text(
                'Error: ${provider.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final filteredCxps = provider.cxps.where((cxp) {
            bool matchesStatus =
                _statusFilter == 'Todos' ||
                cxp.estado.toLowerCase() == _statusFilter.toLowerCase();
            if (!matchesStatus) return false;

            if (_soloVencidos &&
                !_isPastDue(cxp.fechaVencimiento, cxp.estado)) {
              return false;
            }

            if (_searchQuery.isEmpty) return true;

            final q = _searchQuery.toLowerCase();
            return cxp.proveedor.toLowerCase().contains(q) ||
                cxp.documento.toLowerCase().contains(q);
          }).toList();

          double totalFactura = 0;
          double totalPendiente = 0;
          double totalVencido = 0;

          for (var cxp in filteredCxps) {
            totalFactura += cxp.montoFactura;
            totalPendiente += cxp.montoPendiente;
            if (_isPastDue(cxp.fechaVencimiento, cxp.estado)) {
              totalVencido += cxp.montoPendiente;
            }
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
                          'Listado de Cuentas por Pagar',
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
                                  labelText: 'Buscar por proveedor o documento',
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
                                    setState(
                                      () => _soloVencidos = val ?? false,
                                    );
                                  },
                                ),
                                const Text('Solo Vencidos'),
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
                              DataColumn(label: Text('Proveedor')),
                              DataColumn(label: Text('Monto Factura')),
                              DataColumn(label: Text('Monto Pendiente')),
                              DataColumn(label: Text('Vencimiento')),
                              DataColumn(label: Text('Estado')),
                              DataColumn(label: Text('Acciones')),
                            ],
                            rows: filteredCxps.map((cxp) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      cxp.documento,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(cxp.proveedor)),
                                  DataCell(
                                    Text(
                                      currencyFormatter.format(
                                        cxp.montoFactura,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      currencyFormatter.format(
                                        cxp.montoPendiente,
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: cxp.montoPendiente <= 0
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
                                          cxp.fechaVencimiento,
                                          style: TextStyle(
                                            color:
                                                _isPastDue(
                                                  cxp.fechaVencimiento,
                                                  cxp.estado,
                                                )
                                                ? Colors.red
                                                : null,
                                            fontWeight:
                                                _isPastDue(
                                                  cxp.fechaVencimiento,
                                                  cxp.estado,
                                                )
                                                ? FontWeight.bold
                                                : null,
                                          ),
                                        ),
                                        if (_isPastDue(
                                          cxp.fechaVencimiento,
                                          cxp.estado,
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
                                          cxp.estado,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        cxp.estado.toUpperCase(),
                                        style: TextStyle(
                                          color: _getStatusColor(cxp.estado),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      tooltip: 'Editar / Pagar',
                                      onPressed: () => _showFormDialog(cxp),
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
        label: const Text('Nueva CXP', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
