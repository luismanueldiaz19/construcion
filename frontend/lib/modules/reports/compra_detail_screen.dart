import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants.dart';
import '../../services/purchase_service.dart';

class CompraDetailScreen extends StatefulWidget {
  final int compraId;

  const CompraDetailScreen({super.key, required this.compraId});

  @override
  State<CompraDetailScreen> createState() => _CompraDetailScreenState();
}

class _CompraDetailScreenState extends State<CompraDetailScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  bool _isLoading = true;
  Map<String, dynamic>? _compra;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCompra();
  }

  Future<void> _loadCompra() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _purchaseService.getCompra(widget.compraId);
      setState(() {
        _compra = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Factura #${widget.compraId}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Factura #${widget.compraId}')),
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (_compra == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Factura #${widget.compraId}')),
        body: const Center(child: Text('No se encontró la compra.')),
      );
    }

    final f = NumberFormat.currency(symbol: '\$');
    final detalles = _compra!['detalles'] as List? ?? [];

    // Configuración visual adaptada al "Design System" general (Color Azul Oscuro)
    const primaryColor = Color(0xFF003366);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detalle de Compra #${_compra!['id']}',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Imprimir Factura',
            onPressed: () async {
              final url = Uri.parse('$host/compras/${_compra!['id']}/print');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo abrir el enlace de impresión'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(primaryColor, f),
                const SizedBox(height: 24),
                const Text(
                  'Materiales / Artículos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildItemsTable(detalles, f),
                const SizedBox(height: 24),
                _buildTotalsCard(f),
                const SizedBox(height: 24),
                _buildDocumentosSection(primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Color primaryColor, NumberFormat f) {
    final estado = _compra!['estado'] ?? 'N/A';
    Color estadoColor = estado == 'Pendiente' ? Colors.orange : Colors.green;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FACTURA #${_compra!['id']}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: estadoColor),
                  ),
                  child: Text(
                    estado.toUpperCase(),
                    style: TextStyle(
                      color: estadoColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Proveedor',
                    _compra!['proveedor']?['nombre'] ?? 'N/A',
                    Icons.store,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Proyecto',
                    _compra!['proyecto']?['nombre'] ?? 'N/A',
                    Icons.business,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Fecha',
                    _compra!['fecha']?.toString().split('T')[0] ?? 'N/A',
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Tipo',
                    _compra!['tipo_compra'] ?? 'N/A',
                    Icons.payment,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Comprobante',
                    _compra!['comprobante'] ?? 'N/A',
                    Icons.confirmation_number,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Orden #',
                    _compra!['orden'] ?? 'N/A',
                    Icons.receipt_long,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Código Ref.',
                    _compra!['codigo'] ?? 'N/A',
                    Icons.qr_code,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Vencimiento',
                    _compra!['fecha_vencimiento']?.toString().split('T')[0] ??
                        'N/A',
                    Icons.event_note,
                  ),
                ),
              ],
            ),
            if (_compra!['nota'] != null &&
                _compra!['nota'].toString().isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Notas / Observaciones',
                      _compra!['nota'] ?? 'N/A',
                      Icons.info_outline,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildItemsTable(List<dynamic> detalles, NumberFormat f) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
        columns: const [
          DataColumn(
            label: Text(
              'Código',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Material / Descripción',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Cantidad',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'Precio Unitario',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'Subtotal',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
        ],
        rows: detalles.map((d) {
          final mat = d['material'];
          final cantidad =
              double.tryParse(d['cantidad']?.toString() ?? '0') ?? 0;
          final precio =
              double.tryParse(d['precio_unitario']?.toString() ?? '0') ?? 0;
          final subtotal =
              double.tryParse(d['subtotal']?.toString() ?? '0') ?? 0;

          return DataRow(
            cells: [
              DataCell(Text(mat?['codigo'] ?? 'N/A')),
              DataCell(Text(mat?['nombre'] ?? 'Desconocido')),
              DataCell(Text(cantidad.toStringAsFixed(2))),
              DataCell(Text(f.format(precio))),
              DataCell(
                Text(
                  f.format(subtotal),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTotalsCard(NumberFormat f) {
    final subtotal =
        double.tryParse(_compra!['subtotal']?.toString() ?? '0') ?? 0;
    final itbis = double.tryParse(_compra!['itbis']?.toString() ?? '0') ?? 0;
    final total = double.tryParse(_compra!['total']?.toString() ?? '0') ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 300,
          child: Card(
            elevation: 4,
            color: const Color(0xFF003366),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildTotalRow(
                    'Subtotal',
                    f.format(subtotal),
                    Colors.white70,
                  ),
                  const SizedBox(height: 8),
                  _buildTotalRow(
                    'ITBIS (18%)',
                    f.format(itbis),
                    Colors.white70,
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  _buildTotalRow(
                    'TOTAL',
                    f.format(total),
                    Colors.greenAccent,
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(
    String label,
    String value,
    Color color, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentosSection(Color primaryColor) {
    final documentos = _compra!['documentos'] as List? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Evidencias y Documentos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _uploadDocumento,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Subir Evidencia'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (documentos.isEmpty)
              const Text(
                'No hay documentos adjuntos.',
                style: TextStyle(color: Colors.grey),
              ),
            if (documentos.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: documentos.length,
                itemBuilder: (context, index) {
                  final doc = documentos[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.insert_drive_file,
                      color: Colors.blueGrey,
                    ),
                    title: Text(doc['original_name'] ?? 'Documento'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.open_in_new,
                            color: Colors.blue,
                          ),
                          onPressed: () async {
                            final url = Uri.parse(
                              '$host/api/v1/file?path=${doc['file_path']}',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No se pudo abrir el documento',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteDocumento(doc['id']),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadDocumento() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _isLoading = true);
        await _purchaseService.uploadDocumentoCompra(
          widget.compraId,
          result.files.single,
        );
        await _loadCompra(); // Recargar para ver el nuevo documento
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Documento subido correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir documento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteDocumento(int docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Documento'),
        content: const Text('¿Está seguro que desea eliminar este documento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _purchaseService.deleteDocumentoCompra(docId);
        await _loadCompra();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Documento eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
