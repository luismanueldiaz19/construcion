import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/auth_provider.dart';
import '../../../../core/constants.dart';
import '../providers/compras_report_provider.dart';

/// Panel de detalles de compra ultra-compacto y ergonómico.
/// Optimizado para panel lateral en desktop y modal bottom-sheet en mobile.
class CompraDetailPanel extends StatelessWidget {
  final bool isBottomSheet;

  const CompraDetailPanel({super.key, required this.isBottomSheet});

  @override
  Widget build(BuildContext context) {
    return Consumer<ComprasReportProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingDetail) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: isBottomSheet
                ? null
                : BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Cargando detalles...',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isMaster =
            authProvider.username?.toLowerCase() == 'master' ||
            authProvider.username?.toLowerCase() == 'ludeveloper';

        final detail = provider.selectedCompraDetail;
        if (detail == null) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 44,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Detalles de Factura',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Seleccione una compra del registro para visualizar su factura, materiales y evidencias.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        final f = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);
        final detalles = detail['detalles'] as List? ?? [];
        final documentos = detail['documentos'] as List? ?? [];
        final estado = detail['estado'] ?? 'N/A';
        final bool isPagado = estado.toString().toLowerCase() == 'pagado';
        final Color estadoColor = isPagado
            ? const Color(0xFF16A34A)
            : const Color(0xFFEA580C);

        final subtotal =
            double.tryParse(detail['subtotal']?.toString() ?? '0') ?? 0;
        final itbis = double.tryParse(detail['itbis']?.toString() ?? '0') ?? 0;
        final total = double.tryParse(detail['total']?.toString() ?? '0') ?? 0;

        // Header compacto
        final header = Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    'Factura #${detail['id']}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: estadoColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      estado.toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: estadoColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isMaster)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 17,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                tooltip: 'Eliminar Compra',
                onPressed: () =>
                    _confirmDeleteCompra(context, provider, detail['id']),
              ),
            IconButton(
              icon: const Icon(
                Icons.print_outlined,
                color: Color(0xFF64748B),
                size: 17,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              tooltip: 'Imprimir Factura',
              onPressed: () async {
                final url = Uri.parse('$host/compras/${detail['id']}/print');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: Color(0xFF64748B),
                size: 17,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              tooltip: 'Cerrar',
              onPressed: () {
                if (isBottomSheet) {
                  Navigator.pop(context);
                } else {
                  provider.selectCompra(null);
                }
              },
            ),
          ],
        );

        // Cuadrícula compacta de datos
        final infoGrid = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfo(
                    'PROVEEDOR',
                    detail['proveedor']?['nombre'] ?? 'N/A',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactInfo(
                    'PROYECTO',
                    detail['proyecto']?['nombre'] ?? 'N/A',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfo(
                    'FECHA',
                    detail['fecha']?.toString().split('T')[0] ?? 'N/A',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactInfo(
                    'TIPO',
                    detail['tipo_compra'] ?? 'N/A',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfo(
                    'COMPROBANTE',
                    detail['comprobante'] ?? 'N/A',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactInfo('ORDEN #', detail['orden'] ?? 'N/A'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfo(
                    'CÓDIGO REF',
                    detail['codigo'] ?? 'N/A',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactInfo(
                    'VENCIMIENTO',
                    detail['fecha_vencimiento']?.toString().split('T')[0] ??
                        'N/A',
                  ),
                ),
              ],
            ),
            if (detail['nota'] != null &&
                detail['nota'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildCompactInfo('NOTAS', detail['nota'].toString()),
            ],
          ],
        );

        // Artículos y Materiales ultra-compactos
        final articulosSection = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ARTÍCULOS Y MATERIALES',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  '${detalles.length} partidas',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  // Cabecera mini
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    color: const Color(0xFFF8FAFC),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'DESCRIPCIÓN',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'CANTIDAD',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'TOTAL',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  // Filas compactas
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: detalles.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final d = detalles[index];
                      final mat = d['material'];
                      final cantidad =
                          double.tryParse(d['cantidad']?.toString() ?? '0') ??
                          0;
                      final precio =
                          double.tryParse(
                            d['precio_unitario']?.toString() ?? '0',
                          ) ??
                          0;
                      final subtotalVal =
                          double.tryParse(d['subtotal']?.toString() ?? '0') ??
                          0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                mat?['nombre'] ?? 'Material',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${cantidad.toStringAsFixed(2)} x ${f.format(precio)}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                f.format(subtotalVal),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );

        // Evidencias y Documentos compactos
        final evidenciasSection = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DOCUMENTOS Y EVIDENCIAS',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.3,
                  ),
                ),
                InkWell(
                  onTap: () => _uploadDocumento(context, provider),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.upload_file_rounded,
                          size: 14,
                          color: AppTheme.accentColor,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Subir',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (documentos.isEmpty)
              const Text(
                'Sin documentos adjuntos.',
                style: TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF94A3B8),
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Column(
                children: documentos.map((doc) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.picture_as_pdf_outlined,
                          color: Colors.redAccent,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            doc['original_name'] ?? 'Documento',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.open_in_new_rounded,
                            size: 14,
                            color: Color(0xFF2563EB),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 22,
                            minHeight: 22,
                          ),
                          onPressed: () async {
                            final url = Uri.parse(
                              '$host/api/v1/file?path=${doc['file_path']}',
                            );
                            if (await canLaunchUrl(url)) await launchUrl(url);
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 22,
                            minHeight: 22,
                          ),
                          onPressed: () => _confirmDeleteDocumento(
                            context,
                            provider,
                            doc['id'],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        );

        // Bloque de Totales compacto (Moderna tarjeta oscura delgada)
        final totalsBox = Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniTotal('SUBTOTAL', f.format(subtotal)),
              Container(width: 1, height: 20, color: Colors.white24),
              _buildMiniTotal('ITBIS (18%)', f.format(itbis)),
              Container(width: 1, height: 20, color: Colors.white24),
              _buildMiniTotal('TOTAL', f.format(total), isHighlight: true),
            ],
          ),
        );

        if (isBottomSheet) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 8),
                infoGrid,
                const SizedBox(height: 10),
                articulosSection,
                const SizedBox(height: 10),
                evidenciasSection,
                const SizedBox(height: 10),
                totalsBox,
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 6),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      infoGrid,
                      const SizedBox(height: 10),
                      articulosSection,
                      const SizedBox(height: 10),
                      evidenciasSection,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              totalsBox,
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTotal(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isHighlight ? const Color(0xFF4ADE80) : Colors.white60,
            letterSpacing: 0.3,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 13 : 11,
            fontWeight: FontWeight.bold,
            color: isHighlight ? const Color(0xFF4ADE80) : Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> _uploadDocumento(
    BuildContext context,
    ComprasReportProvider provider,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      await provider.uploadDocumentoCompra(result.files.single.path!);
    }
  }

  Future<void> _confirmDeleteDocumento(
    BuildContext context,
    ComprasReportProvider provider,
    int docId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Eliminar Documento',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '¿Está seguro de eliminar este documento adjunto?',
          style: TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) await provider.deleteDocumentoCompra(docId);
  }

  Future<void> _confirmDeleteCompra(
    BuildContext context,
    ComprasReportProvider provider,
    int compraId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Eliminar Compra',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '¿Está seguro de eliminar esta factura? Esta acción afectará los registros contables y de inventario.',
          style: TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) await provider.deleteCompra(compraId);
  }
}
