import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';
import '../../services/accounting_service.dart';
import '../../core/constants.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final AccountingService _accountingService = AccountingService();
  List<dynamic> _history = [];
  bool _isLoadingHistory = true;

  // ── Filtros ──────────────────────────────────────────────
  String _searchQuery = '';
  String? _filterTipo;
  String? _filterMetodoPago;
  DateTime? _filterFechaDesde;
  DateTime? _filterFechaHasta;
  double? _filterMontoMin;
  double? _filterMontoMax;

  int get _activeFilterCount {
    int count = 0;
    if (_filterTipo != null) count++;
    if (_filterMetodoPago != null) count++;
    if (_filterFechaDesde != null || _filterFechaHasta != null) count++;
    if (_filterMontoMin != null || _filterMontoMax != null) count++;
    return count;
  }

  // Valores únicos derivados del historial
  List<String> get _metodosPago {
    final Set<String> set = {};
    for (var item in _history) {
      final m = item['metodo_pago']?.toString() ?? '';
      if (m.isNotEmpty) set.add(m);
    }
    return set.toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final data = await _accountingService.getAllPagosHistorial();
      if (!mounted) return;
      setState(() {
        _history = data;
        _isLoadingHistory = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingHistory = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar historial: $e')));
    }
  }

  List<dynamic> get _filteredHistory {
    return _history.where((item) {
      // Búsqueda de texto
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          item['entidad'].toString().toLowerCase().contains(query) ||
          item['proyecto'].toString().toLowerCase().contains(query) ||
          item['concepto'].toString().toLowerCase().contains(query);

      // Tipo
      final matchesTipo = _filterTipo == null || item['tipo'] == _filterTipo;

      // Método de pago
      final matchesMetodo =
          _filterMetodoPago == null ||
          item['metodo_pago']?.toString() == _filterMetodoPago;

      // Rango de fecha
      bool matchesFecha = true;
      try {
        final fecha = DateTime.parse(item['fecha'].toString());
        if (_filterFechaDesde != null && fecha.isBefore(_filterFechaDesde!)) {
          matchesFecha = false;
        }
        if (_filterFechaHasta != null &&
            fecha.isAfter(_filterFechaHasta!.add(const Duration(days: 1)))) {
          matchesFecha = false;
        }
      } catch (_) {}

      // Rango de monto
      final double monto = double.tryParse(item['monto'].toString()) ?? 0;
      final matchesMonto =
          (_filterMontoMin == null || monto >= _filterMontoMin!) &&
          (_filterMontoMax == null || monto <= _filterMontoMax!);

      return matchesSearch &&
          matchesTipo &&
          matchesMetodo &&
          matchesFecha &&
          matchesMonto;
    }).toList();
  }

  void _clearAllFilters() {
    setState(() {
      _filterTipo = null;
      _filterMetodoPago = null;
      _filterFechaDesde = null;
      _filterFechaHasta = null;
      _filterMontoMin = null;
      _filterMontoMax = null;
    });
  }

  // ── Bottom Sheet de Filtros ──────────────────────────────
  void _showFiltersBottomSheet() {
    // Copias temporales para edición en el sheet
    String? tempTipo = _filterTipo;
    String? tempMetodo = _filterMetodoPago;
    DateTime? tempDesde = _filterFechaDesde;
    DateTime? tempHasta = _filterFechaHasta;
    final TextEditingController montoMinCtrl = TextEditingController(
      text: _filterMontoMin?.toStringAsFixed(0) ?? '',
    );
    final TextEditingController montoMaxCtrl = TextEditingController(
      text: _filterMontoMax?.toStringAsFixed(0) ?? '',
    );
    final DateFormat dateFmt = DateFormat('dd/MM/yyyy');
    final metodos = _metodosPago;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  // Header del sheet
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Filtros Avanzados',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              tempTipo = null;
                              tempMetodo = null;
                              tempDesde = null;
                              tempHasta = null;
                              montoMinCtrl.clear();
                              montoMaxCtrl.clear();
                            });
                          },
                          child: Text(
                            'Limpiar todo',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Contenido scrollable
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── TIPO DE MOVIMIENTO ──────────────
                          _sheetSectionLabel(
                            Icons.swap_horiz_rounded,
                            'Tipo de Movimiento',
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: [
                              _filterChip(
                                label: 'Todos',
                                selected: tempTipo == null,
                                onTap: () =>
                                    setSheetState(() => tempTipo = null),
                              ),
                              _filterChip(
                                label: 'Compra',
                                icon: Icons.arrow_upward,
                                color: Colors.blue[700]!,
                                selected: tempTipo == 'Compra',
                                onTap: () =>
                                    setSheetState(() => tempTipo = 'Compra'),
                              ),
                              _filterChip(
                                label: 'Cobro',
                                icon: Icons.arrow_downward,
                                color: Colors.green[700]!,
                                selected: tempTipo == 'Cobro',
                                onTap: () =>
                                    setSheetState(() => tempTipo = 'Cobro'),
                              ),
                              _filterChip(
                                label: 'Proyecto',
                                icon: Icons.construction,
                                color: Colors.orange[700]!,
                                selected: tempTipo == 'Proyecto',
                                onTap: () =>
                                    setSheetState(() => tempTipo = 'Proyecto'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ── MÉTODO DE PAGO ──────────────────
                          _sheetSectionLabel(
                            Icons.payment_rounded,
                            'Método de Pago',
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _filterChip(
                                label: 'Todos',
                                selected: tempMetodo == null,
                                onTap: () =>
                                    setSheetState(() => tempMetodo = null),
                              ),
                              ...metodos.map(
                                (m) => _filterChip(
                                  label: m,
                                  selected: tempMetodo == m,
                                  onTap: () =>
                                      setSheetState(() => tempMetodo = m),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ── RANGO DE FECHAS ─────────────────
                          _sheetSectionLabel(
                            Icons.date_range_rounded,
                            'Rango de Fechas',
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _datePickerButton(
                                  label: 'Desde',
                                  date: tempDesde,
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: ctx,
                                      initialDate: tempDesde ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                      builder: (context, child) =>
                                          _datePickerTheme(context, child),
                                    );
                                    if (picked != null) {
                                      setSheetState(() => tempDesde = picked);
                                    }
                                  },
                                  onClear: tempDesde != null
                                      ? () => setSheetState(
                                          () => tempDesde = null,
                                        )
                                      : null,
                                  dateFmt: dateFmt,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _datePickerButton(
                                  label: 'Hasta',
                                  date: tempHasta,
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: ctx,
                                      initialDate: tempHasta ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                      builder: (context, child) =>
                                          _datePickerTheme(context, child),
                                    );
                                    if (picked != null) {
                                      setSheetState(() => tempHasta = picked);
                                    }
                                  },
                                  onClear: tempHasta != null
                                      ? () => setSheetState(
                                          () => tempHasta = null,
                                        )
                                      : null,
                                  dateFmt: dateFmt,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ── RANGO DE MONTO ──────────────────
                          _sheetSectionLabel(
                            Icons.attach_money_rounded,
                            'Rango de Monto',
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: montoMinCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: _sheetInputDecoration(
                                    label: 'Mínimo',
                                    prefix: '\$',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: montoMaxCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: _sheetInputDecoration(
                                    label: 'Máximo',
                                    prefix: '\$',
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // ── Botón Aplicar ───────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _filterTipo = tempTipo;
                            _filterMetodoPago = tempMetodo;
                            _filterFechaDesde = tempDesde;
                            _filterFechaHasta = tempHasta;
                            _filterMontoMin = double.tryParse(
                              montoMinCtrl.text.replaceAll(',', ''),
                            );
                            _filterMontoMax = double.tryParse(
                              montoMaxCtrl.text.replaceAll(',', ''),
                            );
                          });
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.check_rounded),
                        label: const Text(
                          'Aplicar Filtros',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Helpers del Sheet ────────────────────────────────────
  Widget _sheetSectionLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    Color? color,
  }) {
    final effectiveColor = color ?? AppTheme.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? effectiveColor.withValues(alpha: 0.12)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? effectiveColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: selected ? effectiveColor : Colors.grey[600],
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? effectiveColor : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePickerButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required VoidCallback? onClear,
    required DateFormat dateFmt,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: date != null
              ? AppTheme.primaryColor.withValues(alpha: 0.06)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null
                ? AppTheme.primaryColor.withValues(alpha: 0.4)
                : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 15,
              color: date != null ? AppTheme.primaryColor : Colors.grey[500],
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                date != null ? dateFmt.format(date) : label,
                style: TextStyle(
                  fontSize: 13,
                  color: date != null
                      ? AppTheme.primaryColor
                      : Colors.grey[500],
                  fontWeight: date != null
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 15, color: Colors.grey[500]),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _sheetInputDecoration({
    required String label,
    String? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      labelStyle: TextStyle(fontSize: 13, color: Colors.grey[600]),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _datePickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.light(
          primary: AppTheme.primaryColor,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: AppTheme.textPrimary,
        ),
      ),
      child: child!,
    );
  }

  // ── BUILD ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: '\$');
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        title: const Text(
          'Historial de Pagos y Cobros',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar Historial',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCards(f),
          _buildSearchAndFilter(),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : _buildHistoryTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(NumberFormat f) {
    double totalIngresos = 0;
    double totalEgresos = 0;

    for (var item in _history) {
      final double monto = double.tryParse(item['monto'].toString()) ?? 0;
      if (item['tipo'] == 'Cobro') {
        totalIngresos += monto;
      } else {
        totalEgresos += monto;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildSummaryItem(
            'Total Recibido (Ingresos)',
            f.format(totalIngresos),
            Colors.green[700]!,
            Icons.trending_up,
          ),
          const SizedBox(width: 16),
          _buildSummaryItem(
            'Total Pagado (Egresos)',
            f.format(totalEgresos),
            Colors.red[700]!,
            Icons.trending_down,
          ),
          const SizedBox(width: 16),
          _buildSummaryItem(
            'Balance Neto',
            f.format(totalIngresos - totalEgresos),
            (totalIngresos - totalEgresos) >= 0
                ? Colors.blue[700]!
                : Colors.purple[700]!,
            Icons.account_balance,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    final hasActiveFilters = _activeFilterCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Campo de búsqueda
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por proyecto, entidad o concepto...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(width: 10),

          // Botón de filtros con badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showFiltersBottomSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: hasActiveFilters
                          ? AppTheme.primaryColor.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasActiveFilters
                            ? AppTheme.primaryColor.withValues(alpha: 0.4)
                            : Colors.grey[200]!,
                        width: hasActiveFilters ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: hasActiveFilters
                              ? AppTheme.primaryColor
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Filtros',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: hasActiveFilters
                                ? AppTheme.primaryColor
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Badge con número de filtros activos
              if (hasActiveFilters)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '$_activeFilterCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Botón limpiar filtros (si hay activos)
          if (hasActiveFilters) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 20),
              tooltip: 'Limpiar filtros',
              style: IconButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.red[200]!),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final f = NumberFormat.currency(symbol: '\$');
    final filtered = _filteredHistory;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron registros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Prueba con otra búsqueda o filtro.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            if (_activeFilterCount > 0) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _clearAllFilters,
                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: const Text('Limpiar filtros'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return _buildHistoryCard(item, f);
      },
    );
  }

  Widget _buildHistoryCard(dynamic item, NumberFormat f) {
    final String tipo = item['tipo'];
    final bool isCompra = tipo == 'Compra';
    final bool isCobro = tipo == 'Cobro';
    final double monto = double.tryParse(item['monto'].toString()) ?? 0;

    Color badgeColor;
    Color iconColor;
    IconData icon;
    String tipoLabel;
    Color amountColor;
    String prefix;

    if (isCobro) {
      badgeColor = Colors.green[50]!;
      iconColor = Colors.green[700]!;
      icon = Icons.arrow_downward;
      tipoLabel = 'Ingreso (Cobro)';
      amountColor = Colors.green[700]!;
      prefix = '+';
    } else if (isCompra) {
      badgeColor = Colors.blue[50]!;
      iconColor = Colors.blue[700]!;
      icon = Icons.arrow_upward;
      tipoLabel = 'Egreso (Compra)';
      amountColor = Colors.red[700]!;
      prefix = '-';
    } else {
      badgeColor = Colors.orange[50]!;
      iconColor = Colors.orange[700]!;
      icon = Icons.arrow_upward;
      tipoLabel = 'Egreso (Gasto)';
      amountColor = Colors.orange[800]!;
      prefix = '-';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Type badge, Amount, and PDF button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 12, color: iconColor),
                        const SizedBox(width: 4),
                        Text(
                          tipoLabel,
                          style: TextStyle(
                            color: iconColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$prefix${f.format(monto)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: amountColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // PDF Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openPdf(item['tipo'], item['id']),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[50],
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_outlined,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Main Info: Entity Name
              Text(
                item['entidad'] ?? 'Sin Entidad',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              // Project & Concept
              Row(
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Proyecto: ${item['proyecto']}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                        fontSize: 12.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (item['concepto'] != null &&
                  item['concepto'].toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  item['concepto'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
              const Divider(height: 24, thickness: 0.5),

              // Bottom row: Date & Payment method chips
              Row(
                children: [
                  // Date badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 11,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item['fecha'],
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Payment Method badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.payment_outlined,
                          size: 11,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item['metodo_pago'],
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPdf(String tipo, int id) async {
    final url = Uri.parse('$host/api/v1/pagos-historial/$tipo/$id/pdf');
    try {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el PDF')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al abrir PDF: $e')));
    }
  }
}
