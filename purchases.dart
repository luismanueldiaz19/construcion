class ProjectPurchasesView extends StatefulWidget {
  final Proyecto proyecto;
  const ProjectPurchasesView({super.key, required this.proyecto});

  @override
  State<ProjectPurchasesView> createState() => _ProjectPurchasesViewState();
}

class _ProjectPurchasesViewState extends State<ProjectPurchasesView> {
  final PurchaseService _purchaseService = PurchaseService();
  bool _isLoading = true;
  List<Compra> _compras = [];
  String? _errorMessage;

  double _totalSubtotal = 0;
  double _totalItbis = 0;
  double _totalGeneral = 0;

  @override
  void initState() {
    super.initState();
    _loadCompras();
  }

  @override
  void didUpdateWidget(covariant ProjectPurchasesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.proyecto.id != oldWidget.proyecto.id) {
      _loadCompras();
    }
  }

  Future<void> _loadCompras() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _purchaseService.getComprasReporte(
        {'proyecto_id': widget.proyecto.id},
        1,
        100, // Load up to 100 purchases
      );
      final List<dynamic> data = response['data'] ?? [];

      if (mounted) {
        setState(() {
          _compras = data.map((json) => Compra.fromJson(json)).toList();
          if (response['summary'] != null) {
            final summary = response['summary'];
            _totalSubtotal =
                double.tryParse(summary['subtotal']?.toString() ?? '0') ?? 0.0;
            _totalItbis =
                double.tryParse(summary['itbis']?.toString() ?? '0') ?? 0.0;
            _totalGeneral =
                double.tryParse(summary['total']?.toString() ?? '0') ?? 0.0;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error al cargar compras:\n$_errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadCompras,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary header cards
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Compras',
                  f.format(_totalGeneral),
                  Colors.blue[700]!,
                  Icons.shopping_bag,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Subtotal',
                  f.format(_totalSubtotal),
                  Colors.grey[700]!,
                  Icons.receipt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Total ITBIS',
                  f.format(_totalItbis),
                  Colors.orange[700]!,
                  Icons.percent,
                ),
              ),
            ],
          ),
        ),

        // List of purchases
        Expanded(
          child: _compras.isEmpty
              ? const Center(
                  child: Text(
                    'No hay compras registradas en este proyecto.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _compras.length,
                  itemBuilder: (context, index) {
                    final c = _compras[index];
                    final double total = c.total;
                    final double subtotal = c.subtotal;
                    final double itbis = total - subtotal;
                    final isRecibido = c.estado == 'Recibido';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade100),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              (isRecibido ? Colors.green : Colors.orange)
                                  .withOpacity(0.1),
                          child: Icon(
                            isRecibido
                                ? Icons.check_circle
                                : Icons.hourglass_empty,
                            color: isRecibido ? Colors.green : Colors.orange,
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              c.proveedor?.name ?? 'Proveedor Desconocido',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              f.format(total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF1A1C1E),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey[50],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'ID: #${c.id} ΓÇó ${c.tipoCompra}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blueGrey[750],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    c.fecha.split('T')[0],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Subtotal: ${f.format(subtotal)} ΓÇó ITBIS: ${f.format(itbis)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (c.comprobante != null &&
                                      c.comprobante!.isNotEmpty) ...[
                                    const Text(' ΓÇó '),
                                    Text(
                                      'NCF: ${c.comprobante}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            final url = Uri.parse(
                              '$host/compras/${c.id}/print',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No se pudo abrir el recibo de compra',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          tooltip: 'Imprimir Factura',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
