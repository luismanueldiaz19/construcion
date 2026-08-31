import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_theme.dart';
import '../models/cxp_model.dart';
import '../providers/cxp_provider.dart';
import '../widgets/cxp_form_dialog.dart';
import '../../../../widgets/hover_total_card.dart';

class CxpScreen extends StatefulWidget {
  const CxpScreen({super.key});

  @override
  State<CxpScreen> createState() => _CxpScreenState();
}

class _CxpScreenState extends State<CxpScreen> with TickerProviderStateMixin {
  final currencyFormatter = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  String _searchQuery = '';
  String _statusFilter = 'Todos';
  bool _soloVencidos = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CxpProvider>(context, listen: false).fetchCxps();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _searchQuery = query);
    });
  }

  void _showFormDialog([cxp]) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => CxpFormDialog(cxp: cxp),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pagado':
        return AppTheme.successColor;
      case 'cancelado':
        return AppTheme.dangerColor;
      default:
        return const Color(0xFFFB8C00); // Naranja
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

  List<CxpModel> _getFilteredList(List<CxpModel> list) {
    return list.where((cxp) {
      bool matchesStatus = _statusFilter == 'Todos' ||
          cxp.estado.toLowerCase() == _statusFilter.toLowerCase();
      if (!matchesStatus) return false;

      if (_soloVencidos && !_isPastDue(cxp.fechaVencimiento, cxp.estado)) {
        return false;
      }

      if (_searchQuery.isEmpty) return true;

      final normalizedQuery = _normalizeText(_searchQuery);
      final normalizedProveedor = _normalizeText(cxp.proveedor);
      final normalizedDocumento = _normalizeText(cxp.documento);

      return normalizedProveedor.contains(normalizedQuery) ||
          normalizedDocumento.contains(normalizedQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CxpProvider>(
      builder: (context, provider, _) {
        final filteredCxps = _getFilteredList(provider.cxps);

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

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(filteredCxps.length, provider.isLoading),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  children: [
                    _buildTotales(totalFactura, totalPendiente, totalVencido),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildSearchBar()),
                        const SizedBox(width: 12),
                        _buildFilterDropdown(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCheckboxes(),
                  ],
                ),
              ),
              Expanded(child: _buildContent(provider, filteredCxps)),
            ],
          ),
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(int total, bool isLoading) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.dangerColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.outbox_rounded,
              color: AppTheme.dangerColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cuentas por Pagar (CXP)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                if (!isLoading)
                  Text(
                    '$total ${total == 1 ? 'registro' : 'registros'}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          _buildHeaderButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Actualizar',
            onTap: () => Provider.of<CxpProvider>(context, listen: false).fetchCxps(),
          ),
          const SizedBox(width: 4),
          _buildHeaderButton(
            icon: Icons.add_rounded,
            tooltip: 'Nueva CXP',
            onTap: () => _showFormDialog(),
            color: AppTheme.accentColor,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
    Color color = Colors.white,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25), width: 1),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  // ── Totales ────────────────────────────────────────────────────────────────
  Widget _buildTotales(
    double facturado,
    double pendiente,
    double vencido,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          HoverTotalCard(
            title: 'TOTAL FACTURADO',
            value: currencyFormatter.format(facturado),
            color: AppTheme.ledhouseBlue,
            icon: Icons.receipt_long_rounded,
          ),
          const SizedBox(width: 12),
          HoverTotalCard(
            title: 'TOTAL PENDIENTE',
            value: currencyFormatter.format(pendiente),
            color: const Color(0xFFFB8C00),
            icon: Icons.account_balance_wallet_rounded,
          ),
          const SizedBox(width: 12),
          HoverTotalCard(
            title: 'DEUDA VENCIDA',
            value: currencyFormatter.format(vencido),
            color: AppTheme.dangerColor,
            icon: Icons.warning_amber_rounded,
          ),
        ],
      ),
    );
  }

  // ── Filtros ────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar proveedor o doc...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statusFilter,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade500),
          style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
          items: const [
            DropdownMenuItem(value: 'Todos', child: Text('Todos')),
            DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
            DropdownMenuItem(value: 'pagado', child: Text('Pagado')),
            DropdownMenuItem(value: 'cancelado', child: Text('Cancelado')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _statusFilter = val);
          },
        ),
      ),
    );
  }

  Widget _buildCheckboxes() {
    return Row(
      children: [
        _buildCustomCheckbox(
          label: 'Solo Vencidos',
          value: _soloVencidos,
          onChanged: (v) => setState(() => _soloVencidos = v),
        ),
      ],
    );
  }

  Widget _buildCustomCheckbox({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: value ? AppTheme.ledhouseBlue : Colors.transparent,
                border: Border.all(
                  color: value ? AppTheme.ledhouseBlue : Colors.grey.shade400,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: value
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: value ? Colors.black87 : Colors.grey.shade600,
                fontWeight: value ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Content ────────────────────────────────────────────────────────────────
  Widget _buildContent(CxpProvider provider, List<CxpModel> list) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppTheme.ledhouseBlue),
          strokeWidth: 3,
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar los datos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => provider.fetchCxps(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.dangerColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.outbox_rounded,
                size: 48,
                color: AppTheme.dangerColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No se encontraron resultados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3C4043),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajusta los filtros o agrega una nueva cuenta',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return _buildCxpCard(list[index]);
      },
    );
  }

  // ── Card ───────────────────────────────────────────────────────────────────
  Widget _buildCxpCard(CxpModel cxp) {
    final color = _getStatusColor(cxp.estado);
    final pastDue = _isPastDue(cxp.fechaVencimiento, cxp.estado);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showFormDialog(cxp),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border(left: BorderSide(color: color, width: 4)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.request_page_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 14),

                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Doc y Vencimiento
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              cxp.documento,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: pastDue ? AppTheme.dangerColor : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                cxp.fechaVencimiento,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: pastDue ? FontWeight.bold : FontWeight.normal,
                                  color: pastDue ? AppTheme.dangerColor : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Proveedor
                      Row(
                        children: [
                          Icon(Icons.storefront_rounded, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              cxp.proveedor,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Montos
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Factura',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                                Text(
                                  currencyFormatter.format(cxp.montoFactura),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF3C4043),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pendiente',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                                Text(
                                  currencyFormatter.format(cxp.montoPendiente),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: cxp.montoPendiente <= 0
                                        ? AppTheme.successColor
                                        : (pastDue ? AppTheme.dangerColor : const Color(0xFFFB8C00)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Badge de Estado
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Text(
                          cxp.estado.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Menú de acciones
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade400, size: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 8,
                  onSelected: (val) {
                    if (val == 'edit') _showFormDialog(cxp);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: const [
                          Icon(Icons.edit_rounded, size: 18, color: Color(0xFF1A73E8)),
                          SizedBox(width: 10),
                          Text('Editar / Pagar', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
