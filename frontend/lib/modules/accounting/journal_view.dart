import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../services/accounting_service.dart';

class JournalView extends StatefulWidget {
  const JournalView({super.key});

  @override
  State<JournalView> createState() => _JournalViewState();
}

class _JournalViewState extends State<JournalView> {
  final AccountingService _accountingService = AccountingService();
  List<dynamic> _asientos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAsientos();
  }

  Future<void> _loadAsientos() async {
    try {
      final data = await _accountingService.getAsientos();
      setState(() {
        _asientos = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAsiento(int id) async {
    print('delete asiento $id');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este asiento contable de forma manual?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _accountingService.deleteAsiento(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Asiento eliminado exitosamente')),
          );
          _loadAsientos();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: '\$');

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _asientos.length,
      itemBuilder: (context, index) {
        final asiento = _asientos[index];
        final detalles = asiento['detalles'] as List? ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Asiento #${asiento['id']} - ${asiento['referencia_tipo'] ?? 'General'}',
                  ),
                ),
                Text(
                  asiento['fecha'],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (context.watch<AuthProvider>().username == 'ludeveloper')
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    onPressed: () => _deleteAsiento(asiento['id']),
                    tooltip: 'Eliminar Asiento',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            subtitle: Text(asiento['glosa'] ?? 'Sin glosa'),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                  },
                  children: [
                    const TableRow(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            'Cuenta',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            'Debe',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            'Haber',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...detalles
                        .map(
                          (d) => TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  "${d['cuenta']['codigo']} ${d['cuenta']['nombre']}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  double.parse(d['debe'].toString()) > 0
                                      ? f.format(
                                          double.parse(d['debe'].toString()),
                                        )
                                      : '-',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  double.parse(d['haber'].toString()) > 0
                                      ? f.format(
                                          double.parse(d['haber'].toString()),
                                        )
                                      : '-',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
