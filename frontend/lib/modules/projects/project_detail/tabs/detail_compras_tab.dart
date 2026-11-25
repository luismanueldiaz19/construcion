import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/constants.dart';
import '../../../../models/compra.dart';
import '../../../../models/proyecto.dart';
import '../../../../services/purchase_service.dart';
import '../../../../widgets/app_alert.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_empty_state.dart';
import '../../../../widgets/app_status_badge.dart';
import '../../../../widgets/app_text_field.dart';
import '../dialogs/compra_detail_sheet.dart';

/// Pestaña 5 (Compras): Filtros compactos, KPIs sin overflow y lista limpia integrada.
class DetailComprasTab extends StatefulWidget {
  final Proyecto proyecto;

  const DetailComprasTab({super.key, required this.proyecto});

  @override
  State<DetailComprasTab> createState() => _DetailComprasTabState();
}

class _DetailComprasTabState extends State<DetailComprasTab> {
  final PurchaseService _purchaseService = PurchaseService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<Compra> _compras = [];

  String _searchQuery = '';
  DateTimeRange? _dateRange;
  bool _sortDesc = true;

  @override
  void initState() {
    super.initState();
    _loadCompras();
  }

  @override
  void didUpdateWidget(covariant DetailComprasTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.proyecto.id != oldWidget.proyecto.id) {
      _loadCompras();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCompras() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _purchaseService.getComprasReporte(
        {'proyecto_id': widget.proyecto.id},
        1,
        1000,
      );
      final List<dynamic> data = response['data'] ?? [];
      if (mounted) {
        setState(() {
          _compras = data.map((json) => Compra.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar compras: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<Compra> get _filteredCompras {
    final list = _compras.where((c) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final prov = c.proveedor?.name.toLowerCase() ?? '';
        final ncf = c.comprobante?.toLowerCase() ?? '';
        final idStr = '#${c.id}';
        if (!prov.contains(q) && !ncf.contains(q) && !idStr.contains(q)) {
          return false;
        }
      }
      if (_dateRange != null) {
        final parsed = DateTime.tryParse(c.fecha);
        if (parsed != null) {
          final start = DateTime(
            _dateRange!.start.year,
            _dateRange!.start.month,
            _dateRange!.start.day,
          );
          final end = DateTime(
            _dateRange!.end.year,
            _dateRange!.end.month,
            _dateRange!.end.day,
            23,
            59,
            59,
          );
          if (parsed.isBefore(start) || parsed.isAfter(end)) return false;
        }
      }
      return true;
    }).toList();

    list.sort(
      (a, b) =>
          _sortDesc ? b.total.compareTo(a.total) : a.total.compareTo(b.total),
    );
    return list;
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _dateRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.accentColor,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Future<void> _openUrl(
    BuildContext context,
    String rawUrl, {
    required String errorMessage,
  }) async {
    final uri = Uri.parse(rawUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      AppAlert.showToast(context, errorMessage, type: AppAlertType.error);
    }
  }

  String _reportPdfUrl() {
    var url = '$host/reports/compras/pdf?proyecto_id=${widget.proyecto.id}';
    if (_dateRange != null) {
      final fmt = DateFormat('yyyy-MM-dd');
      url +=
          '&fecha_inicio=${fmt.format(_dateRange!.start)}&fecha_fin=${fmt.format(_dateRange!.end)}';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppTheme.accentColor,
          ),
        ),
      );
    }

    if (_error != null) {
      return AppEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'No se pudieron cargar las compras',
        description: _error,
        actionText: 'Reintentar',
        onAction: _loadCompras,
      );
    }

    final compras = _filteredCompras;
    final currencyFmt = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);
    final shortDate = DateFormat('dd/MM');

    final totalCompras = compras.fold<double>(0.0, (s, c) => s + c.total);
    final totalSubtotal = compras.fold<double>(0.0, (s, c) => s + c.subtotal);
    final totalItbis = compras.fold<double>(0.0, (s, c) => s + c.itbis);

    return RefreshIndicator(
      onRefresh: _loadCompras,
      color: AppTheme.accentColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Buscador
            AppTextField(
              controller: _searchController,
              hintText: 'Buscar proveedor, NCF o #ID...',
              prefixIconData: Icons.search_rounded,
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 17),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 8),

            // Controles compactos: Fecha, Ordenar, Imprimir
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppButton(
                  text: _dateRange == null
                      ? 'Fechas'
                      : '${shortDate.format(_dateRange!.start)} - ${shortDate.format(_dateRange!.end)}',
                  icon: Icons.date_range_rounded,
                  size: AppButtonSize.compact,
                  variant: _dateRange == null
                      ? AppButtonVariant.outlined
                      : AppButtonVariant.secondary,
                  borderRadius: 8,
                  onPressed: _pickDateRange,
                ),
                if (_dateRange != null)
                  IconButton(
                    tooltip: 'Limpiar fechas',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close_rounded, size: 17),
                    onPressed: () => setState(() => _dateRange = null),
                  ),
                AppButton(
                  text: _sortDesc ? 'Mayor' : 'Menor',
                  icon: _sortDesc
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  size: AppButtonSize.compact,
                  variant: AppButtonVariant.outlined,
                  borderRadius: 8,
                  onPressed: () => setState(() => _sortDesc = !_sortDesc),
                ),
                AppButton(
                  text: 'Imprimir',
                  icon: Icons.print_outlined,
                  size: AppButtonSize.compact,
                  variant: AppButtonVariant.outlined,
                  borderRadius: 8,
                  onPressed: () => _openUrl(
                    context,
                    _reportPdfUrl(),
                    errorMessage: 'No se pudo abrir el reporte de compras.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // KPIs compactos sin overflow
            _CompraKpiTile(
              label: 'Total Compras (${compras.length})',
              value: currencyFmt.format(totalCompras),
              color: const Color(0xFF2563EB),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _CompraKpiTile(
                    label: 'Subtotal',
                    value: currencyFmt.format(totalSubtotal),
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CompraKpiTile(
                    label: 'Total ITBIS',
                    value: currencyFmt.format(totalItbis),
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: Color(0xFFE2E8F0)),

            // Lista limpia de compras
            if (compras.isEmpty)
              const AppEmptyState(
                icon: Icons.shopping_cart_outlined,
                title: 'Sin compras registradas',
                description:
                    'No hay compras asociadas a este proyecto con los filtros actuales.',
              )
            else
              ...compras.map((c) {
                final isPaid = c.estado.toLowerCase() == 'pagada';
                return Column(
                  children: [
                    InkWell(
                      onTap: () => CompraDetailSheet.show(context, c.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: (isPaid
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFD97706))
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                isPaid
                                    ? Icons.check_rounded
                                    : Icons.schedule_rounded,
                                size: 15,
                                color: isPaid
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFD97706),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.proveedor?.name ?? 'Sin proveedor',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 3,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      AppStatusBadge(
                                        label: '#${c.id} · ${c.tipoCompra}',
                                        type: AppStatusType.info,
                                      ),
                                      Text(
                                        c.fecha,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    [
                                      'Sub: ${currencyFmt.format(c.subtotal)}',
                                      'ITBIS: ${currencyFmt.format(c.itbis)}',
                                      if (c.comprobante != null &&
                                          c.comprobante!.isNotEmpty)
                                        'NCF: ${c.comprobante}',
                                    ].join(' · '),
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFmt.format(c.total),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Ver detalle',
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(
                                        Icons.visibility_outlined,
                                        size: 17,
                                        color: AppTheme.ledhouseBlue,
                                      ),
                                      onPressed: () =>
                                          CompraDetailSheet.show(context, c.id),
                                    ),
                                    IconButton(
                                      tooltip: 'Imprimir factura PDF',
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(
                                        Icons.print_outlined,
                                        size: 17,
                                        color: AppTheme.accentColor,
                                      ),
                                      onPressed: () => _openUrl(
                                        context,
                                        '$host/compras/${c.id}/print',
                                        errorMessage:
                                            'No se pudo abrir la factura PDF.',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _CompraKpiTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CompraKpiTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
