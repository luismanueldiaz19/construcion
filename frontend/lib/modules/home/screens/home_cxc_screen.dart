import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../../services/accounting_service.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_confirm_dialog.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_status_badge.dart';
import '../../../widgets/app_text_field.dart';
import '../../accounting/widgets/registrar_cobro_sheet.dart';

/// Módulo compacto de Cuentas por Cobrar (CXC) integrado en el Home unificado.
class HomeCxcScreen extends StatefulWidget {
  const HomeCxcScreen({super.key});

  @override
  State<HomeCxcScreen> createState() => _HomeCxcScreenState();
}

class _HomeCxcScreenState extends State<HomeCxcScreen> {
  final AccountingService _accountingService = AccountingService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _cuentas = [];
  List<dynamic> _historial = [];
  List<dynamic> _bancos = [];

  bool _isLoading = true;
  String? _error;
  int _activeTab = 0; // 0 = Pendientes, 1 = Historial
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _accountingService.getCuentasPorCobrar(),
        _accountingService.getBancos(),
        _accountingService.getAllPagosHistorial(),
      ]);

      if (!mounted) return;
      setState(() {
        _cuentas = results[0];
        _bancos = results[1];
        _historial = results[2]
            .where((item) => item['tipo'] == 'Cobro')
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar CXC: $e';
        _isLoading = false;
      });
    }
  }

  double _toDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '0') ?? 0.0;

  List<dynamic> get _pendientes {
    return _cuentas.where((c) {
      if (_toDouble(c['saldo']) <= 0.01) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final proyecto = c['proyecto']?.toString().toLowerCase() ?? '';
      final cliente = c['cliente']?.toString().toLowerCase() ?? '';
      return proyecto.contains(q) || cliente.contains(q);
    }).toList();
  }

  List<dynamic> get _filteredHistorial {
    if (_searchQuery.isEmpty) return _historial;
    final q = _searchQuery.toLowerCase();
    return _historial.where((item) {
      final proyecto = item['proyecto']?.toString().toLowerCase() ?? '';
      final entidad = item['entidad']?.toString().toLowerCase() ?? '';
      final concepto = item['concepto']?.toString().toLowerCase() ?? '';
      return proyecto.contains(q) || entidad.contains(q) || concepto.contains(q);
    }).toList();
  }

  Future<void> _openCobroSheet(dynamic cuenta) async {
    final created = await RegistrarCobroSheet.show(
      context,
      cuenta: Map<String, dynamic>.from(cuenta as Map),
      bancos: _bancos,
    );
    if (created == true) {
      _loadData();
    }
  }

  Future<void> _openUrl(
    String rawUrl, {
    required String errorMessage,
    bool external = false,
  }) async {
    final uri = Uri.parse(rawUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: external
            ? LaunchMode.externalApplication
            : LaunchMode.platformDefault,
      );
    } else if (mounted) {
      AppAlert.showToast(context, errorMessage, type: AppAlertType.error);
    }
  }

  Future<void> _deleteComprobante(int id) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: '¿Eliminar comprobante?',
      message:
          'Se eliminará el archivo adjunto de este cobro. Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      isDestructive: true,
    );
    if (!confirmed) return;

    try {
      await _accountingService.deleteComprobantePago(id);
      if (mounted) {
        AppAlert.showToast(
          context,
          'Comprobante eliminado.',
          type: AppAlertType.success,
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        AppAlert.showToast(
          context,
          'Error al eliminar comprobante: $e',
          type: AppAlertType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);
    final pendientes = _pendientes;
    final historial = _filteredHistorial;

    final totalPorCobrar = _cuentas
        .where((c) => _toDouble(c['saldo']) > 0.01)
        .fold<double>(0.0, (sum, c) => sum + _toDouble(c['saldo']));
    final totalCobrado = _historial.fold<double>(
      0.0,
      (sum, item) => sum + _toDouble(item['monto']),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Barra superior: Segmento Pendientes / Historial + Buscador
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _TabPill(
                        label: 'Pendientes (${pendientes.length})',
                        icon: Icons.pending_actions_rounded,
                        selected: _activeTab == 0,
                        onTap: () => setState(() => _activeTab = 0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TabPill(
                        label: 'Historial (${historial.length})',
                        icon: Icons.history_rounded,
                        selected: _activeTab == 1,
                        onTap: () => setState(() => _activeTab = 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _searchController,
                  hintText: _activeTab == 0
                      ? 'Buscar proyecto o cliente...'
                      : 'Buscar proyecto, cliente o concepto...',
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
              ],
            ),
          ),

          // Franja de KPIs compactos
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _CxcKpiTile(
                    label: 'Por Cobrar',
                    value: currencyFmt.format(totalPorCobrar),
                    color: const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CxcKpiTile(
                    label: 'Total Cobrado',
                    value: currencyFmt.format(totalCobrado),
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),

          // Contenido principal
          Expanded(
            child: _buildBody(currencyFmt, pendientes, historial),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    NumberFormat currencyFmt,
    List<dynamic> pendientes,
    List<dynamic> historial,
  ) {
    if (_isLoading && _cuentas.isEmpty && _historial.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppTheme.accentColor,
        ),
      );
    }

    if (_error != null && _cuentas.isEmpty) {
      return AppEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'No se pudieron cargar las cuentas por cobrar',
        description: _error,
        actionText: 'Reintentar',
        onAction: _loadData,
      );
    }

    if (_activeTab == 0) {
      if (pendientes.isEmpty) {
        return const AppEmptyState(
          icon: Icons.check_circle_outline_rounded,
          title: 'Sin cuentas pendientes',
          description:
              'Todas las cuentas por cobrar están al día o no coinciden con tu búsqueda.',
        );
      }

      return RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.accentColor,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          itemCount: pendientes.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
          itemBuilder: (context, index) {
            final c = pendientes[index];
            final proyecto = c['proyecto']?.toString() ?? 'Proyecto';
            final cliente = c['cliente']?.toString() ?? 'Sin cliente';
            final total = _toDouble(c['total'] ?? c['monto_total']);
            final cobrado = _toDouble(c['pagado'] ?? c['cobrado']);
            final saldo = _toDouble(c['saldo']);
            final pct = total > 0 ? (cobrado / total * 100).clamp(0.0, 100.0) : 0.0;

            return InkWell(
              onTap: () => _openCobroSheet(c),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                proyecto,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cliente,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
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
                            const Text(
                              'SALDO PENDIENTE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            Text(
                              currencyFmt.format(saldo),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct / 100.0,
                                  minHeight: 5,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Cobrado ${pct.toStringAsFixed(0)}% · ${currencyFmt.format(cobrado)} de ${currencyFmt.format(total)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        AppButton(
                          text: 'Cobrar',
                          icon: Icons.payments_outlined,
                          size: AppButtonSize.compact,
                          variant: AppButtonVariant.primary,
                          borderRadius: 8,
                          onPressed: () => _openCobroSheet(c),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    // Tab 1: Historial de cobros
    if (historial.isEmpty) {
      return const AppEmptyState(
        icon: Icons.history_rounded,
        title: 'Sin cobros registrados',
        description: 'No se encontraron cobros en el historial.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.accentColor,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        itemCount: historial.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
        itemBuilder: (context, index) {
          final item = historial[index];
          final monto = _toDouble(item['monto']);
          final proyecto = item['proyecto']?.toString() ?? 'Proyecto';
          final entidad = item['entidad']?.toString() ?? 'Cliente';
          final concepto = item['concepto']?.toString() ?? '';
          final fecha = item['fecha']?.toString() ?? '';
          final metodo = item['metodo_pago']?.toString() ?? '';
          final id = item['id'] as int?;
          final comprobantePath =
              item['original']?['comprobante_path']?.toString();

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proyecto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        concepto.isNotEmpty ? '$entidad · $concepto' : entidad,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 6,
                        runSpacing: 3,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (metodo.isNotEmpty)
                            AppStatusBadge(
                              label: metodo,
                              type: AppStatusType.active,
                            ),
                          if (fecha.isNotEmpty)
                            Text(
                              fecha,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFmt.format(monto),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (comprobantePath != null &&
                            comprobantePath.isNotEmpty) ...[
                          IconButton(
                            tooltip: 'Ver comprobante',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.attach_file_rounded,
                              size: 16,
                              color: AppTheme.ledhouseBlue,
                            ),
                            onPressed: () => _openUrl(
                              '$host/storage/$comprobantePath',
                              errorMessage: 'No se pudo abrir el comprobante.',
                              external: true,
                            ),
                          ),
                          if (id != null)
                            IconButton(
                              tooltip: 'Eliminar comprobante',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                                color: AppTheme.dangerColor,
                              ),
                              onPressed: () => _deleteComprobante(id),
                            ),
                        ],
                        if (id != null)
                          IconButton(
                            tooltip: 'Recibo PDF',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.picture_as_pdf_outlined,
                              size: 17,
                              color: AppTheme.accentColor,
                            ),
                            onPressed: () => _openUrl(
                              '$host/api/v1/pagos-historial/Cobro/$id/pdf',
                              errorMessage:
                                  'No se pudo abrir el recibo PDF.',
                              external: true,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accentColor : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.accentColor : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CxcKpiTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CxcKpiTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
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
