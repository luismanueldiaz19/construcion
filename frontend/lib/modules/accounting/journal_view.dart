import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
                Text(
                  'Asiento #${asiento['id']} - ${asiento['referencia_tipo'] ?? 'General'}',
                ),
                Text(
                  asiento['fecha'],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
