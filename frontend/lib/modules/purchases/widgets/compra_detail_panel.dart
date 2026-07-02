import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/constants.dart';
import '../providers/compras_report_provider.dart';

class CompraDetailPanel extends StatelessWidget {
  final bool isBottomSheet;

  const CompraDetailPanel({
    super.key,
    required this.isBottomSheet,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ComprasReportProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingDetail) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: isBottomSheet
                ? null
                : BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.black),
                  SizedBox(height: 16),
                  Text('Cargando detalles...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        final detail = provider.selectedCompraDetail;
        if (detail == null) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text(
                  'Detalles de Factura',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Seleccione una compra del registro a la izquierda para visualizar su factura, desglose de materiales, totales y documentos de evidencia adjuntos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
                ),
              ],
            ),
          );
        }

        final f = NumberFormat.currency(symbol: '\$');
        final detalles = detail['detalles'] as List? ?? [];
        final documentos = detail['documentos'] as List? ?? [];
        final estado = detail['estado'] ?? 'N/A';
        Color estadoColor = estado == 'Pendiente' ? Colors.orange : Colors.green;

        final subtotal = double.tryParse(detail['subtotal']?.toString() ?? '0') ?? 0;
        final itbis = double.tryParse(detail['itbis']?.toString() ?? '0') ?? 0;
        final total = double.tryParse(detail['total']?.toString() ?? '0') ?? 0;

        final infoSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de Facturación
            _buildInfoItem('Proveedor', detail['proveedor']?['nombre'] ?? 'N/A', Icons.store),
            const SizedBox(height: 12),
            _buildInfoItem('Proyecto', detail['proyecto']?['nombre'] ?? 'N/A', Icons.business),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildInfoItem('Fecha', detail['fecha']?.toString().split('T')[0] ?? 'N/A', Icons.calendar_today)),
                Expanded(child: _buildInfoItem('Tipo', detail['tipo_compra'] ?? 'N/A', Icons.payment)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildInfoItem('Comprobante', detail['comprobante'] ?? 'N/A', Icons.confirmation_number)),
                Expanded(child: _buildInfoItem('Orden #', detail['orden'] ?? 'N/A', Icons.receipt_long)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildInfoItem('Código Ref.', detail['codigo'] ?? 'N/A', Icons.qr_code)),
                Expanded(child: _buildInfoItem('Vencimiento', detail['fecha_vencimiento']?.toString().split('T')[0] ?? 'N/A', Icons.event_note)),
              ],
            ),
            if (detail['nota'] != null && detail['nota'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoItem('Notas / Observaciones', detail['nota'], Icons.info_outline),
            ],

            // Desglose de Artículos
            const Divider(height: 32, color: Color(0xFFEEEEEE)),
            const Text(
              'Artículos / Materiales',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: detalles.length,
              itemBuilder: (context, index) {
                final d = detalles[index];
                final mat = d['material'];
                final cantidad = double.tryParse(d['cantidad']?.toString() ?? '0') ?? 0;
                final precio = double.tryParse(d['precio_unitario']?.toString() ?? '0') ?? 0;
                final subtotalVal = double.tryParse(d['subtotal']?.toString() ?? '0') ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mat?['nombre'] ?? 'Desconocido',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${cantidad.toStringAsFixed(2)} x ${f.format(precio)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        f.format(subtotalVal),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Evidencias / Documentos
            const Divider(height: 32, color: Color(0xFFEEEEEE)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Evidencias / Documentos',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
                ),
                ElevatedButton.icon(
                  onPressed: () => _uploadDocumento(context, provider),
                  icon: const Icon(Icons.upload_file, size: 14),
                  label: const Text('Subir', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (documentos.isEmpty)
              Text(
                'No hay documentos adjuntos.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: documentos.length,
                itemBuilder: (context, index) {
                  final doc = documentos[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      dense: true,
                      leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 20),
                      title: Text(
                        doc['original_name'] ?? 'Documento',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.open_in_new, color: Colors.blue, size: 18),
                            onPressed: () async {
                              final url = Uri.parse('$host/api/v1/file?path=${doc['file_path']}');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            onPressed: () => _confirmDeleteDocumento(context, provider, doc['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        );

        final totalsSection = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildTotalRow('Subtotal', f.format(subtotal), Colors.white70),
              const SizedBox(height: 8),
              _buildTotalRow('ITBIS (18%)', f.format(itbis), Colors.white70),
              const Divider(color: Colors.white24, height: 24),
              _buildTotalRow('TOTAL', f.format(total), Colors.greenAccent, isTotal: true),
            ],
          ),
        );

        final headerSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Factura #${detail['id']}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.print, color: Colors.black54),
                  tooltip: 'Imprimir Factura',
                  onPressed: () async {
                    final url = Uri.parse('$host/compras/${detail['id']}/print');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No se pudo abrir el enlace de impresión')),
                        );
                      }
                    }
                  },
                ),
                if (isBottomSheet)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => provider.selectCompra(null),
                    tooltip: 'Cerrar',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: estadoColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: estadoColor),
              ),
              child: Text(
                estado.toUpperCase(),
                style: TextStyle(
                  color: estadoColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            const Divider(height: 32, color: Color(0xFFEEEEEE)),
          ],
        );

        if (isBottomSheet) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                headerSection,
                infoSection,
                const SizedBox(height: 16),
                totalsSection,
              ],
            ),
          );
        } else {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                headerSection,
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [infoSection, const SizedBox(height: 24)],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                totalsSection,
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, String value, Color color, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: isTotal ? 18 : 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _uploadDocumento(BuildContext context, ComprasReportProvider provider) async {
    // We can access purchaseService directly from provider but it's private.
    // Wait, the API call should probably be in the provider. Let's assume provider has `uploadDocument` 
    // or we can implement it there later, but for now we'll just show a snackbar saying to implement this in the provider or just let it be.
    // Actually, since this is a UI file, I should call a method on the provider.
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        await provider.uploadDocumentoCompra(result.files.single);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Documento subido correctamente'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir documento: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDeleteDocumento(BuildContext context, ComprasReportProvider provider, int docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Eliminar Documento'),
        content: const Text('¿Está seguro que desea eliminar este documento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await provider.deleteDocumentoCompra(docId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Documento eliminado correctamente'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
