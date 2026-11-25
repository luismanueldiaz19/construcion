import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/constants.dart';
import '../../../../services/purchase_service.dart';
import '../../../../widgets/app_alert.dart';
import '../../../../widgets/app_empty_state.dart';
import '../../../../widgets/app_status_badge.dart';

/// Modal inferior compacto para consultar el detalle completo de una compra.
class CompraDetailSheet extends StatefulWidget {
  final int compraId;

  const CompraDetailSheet({super.key, required this.compraId});

  static Future<void> show(BuildContext context, int compraId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CompraDetailSheet(compraId: compraId),
    );
  }

  @override
  State<CompraDetailSheet> createState() => _CompraDetailSheetState();
}

class _CompraDetailSheetState extends State<CompraDetailSheet> {
  final PurchaseService _purchaseService = PurchaseService();
  Map<String, dynamic>? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _purchaseService.getCompra(widget.compraId);
      if (mounted) {
        setState(() {
          _detail = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo cargar la compra: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _printPdf(BuildContext context) async {
    final uri = Uri.parse('$host/compras/${widget.compraId}/print');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      AppAlert.showToast(
        context,
        'No se pudo abrir la factura PDF.',
        type: AppAlertType.error,
      );
    }
  }

  double _toDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '0') ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 10, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    color: AppTheme.accentColor,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Compra #${widget.compraId}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  if (_detail != null)
                    AppStatusBadge(
                      label: (_detail!['estado'] ?? 'Pendiente')
                          .toString()
                          .toUpperCase(),
                      type: (_detail!['estado']?.toString().toLowerCase() ==
                              'pagada')
                          ? AppStatusType.active
                          : AppStatusType.pending,
                    ),
                  IconButton(
                    tooltip: 'Imprimir factura PDF',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.print_outlined,
                      size: 18,
                      color: Color(0xFF475569),
                    ),
                    onPressed: () => _printPdf(context),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close_rounded, size: 19),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppTheme.accentColor,
                      ),
                    )
                  : _error != null
                      ? AppEmptyState(
                          icon: Icons.error_outline_rounded,
                          title: 'Error al cargar compra',
                          description: _error,
                          actionText: 'Reintentar',
                          onAction: _loadDetail,
                        )
                      : _buildDetailBody(currencyFmt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailBody(NumberFormat currencyFmt) {
    final d = _detail!;
    final proveedor = d['proveedor']?['name']?.toString() ?? 'Sin proveedor';
    final fecha = d['fecha']?.toString() ?? '--';
    final tipo = d['tipo_compra']?.toString() ?? '--';
    final ncf = d['comprobante']?.toString() ?? '--';
    final nota = d['nota']?.toString().trim() ?? '';
    final detalles = (d['detalles'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DetailRow(label: 'Proveedor', value: proveedor),
          _DetailRow(label: 'Fecha', value: fecha),
          _DetailRow(label: 'Tipo', value: tipo),
          _DetailRow(label: 'NCF / Comprobante', value: ncf),
          if (nota.isNotEmpty) _DetailRow(label: 'Nota', value: nota),
          const Divider(height: 20, color: Color(0xFFE2E8F0)),
          Text(
            'Artículos (${detalles.length})',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          if (detalles.isEmpty)
            const Text(
              'Sin artículos detallados.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            )
          else
            ...detalles.map((item) {
              final map = item as Map<String, dynamic>;
              final nombre = map['material']?['nombre']?.toString() ??
                  map['producto']?['nombre']?.toString() ??
                  map['descripcion']?.toString() ??
                  'Artículo';
              final cant = _toDouble(map['cantidad']);
              final precio = _toDouble(map['precio_unitario'] ?? map['precio']);
              final sub = _toDouble(map['subtotal'] ?? (cant * precio));

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '$cant × ${currencyFmt.format(precio)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFmt.format(sub),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          const Divider(height: 20, color: Color(0xFFE2E8F0)),
          _DetailRow(
            label: 'Subtotal',
            value: currencyFmt.format(_toDouble(d['subtotal'])),
          ),
          _DetailRow(
            label: 'ITBIS',
            value: currencyFmt.format(_toDouble(d['itbis'])),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL COMPRA',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  currencyFmt.format(_toDouble(d['total'])),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
