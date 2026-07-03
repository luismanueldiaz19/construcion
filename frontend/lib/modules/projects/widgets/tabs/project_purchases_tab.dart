import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants.dart';
import '../../../../models/proyecto.dart';
import '../../../../models/compra.dart';
import '../../../../services/purchase_service.dart';

class ProjectPurchasesTab extends StatefulWidget {
  final Proyecto proyecto;
  const ProjectPurchasesTab({super.key, required this.proyecto});

  @override
  State<ProjectPurchasesTab> createState() => _ProjectPurchasesTabState();
}

class _ProjectPurchasesTabState extends State<ProjectPurchasesTab> {
  final PurchaseService _purchaseService = PurchaseService();
  bool _isLoading = true;
  List<Compra> _compras = [];
  String? _errorMessage;

  // Estado de los filtros
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortOrder = 'desc'; // 'desc' = Mayor a Menor, 'asc' = Menor a Mayor

  @override
  void initState() {
    super.initState();
    _loadCompras();
  }

  @override
  void didUpdateWidget(covariant ProjectPurchasesTab oldWidget) {
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
        1000, // Cargar suficientes para filtrar localmente
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
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Filtrado y Ordenamiento Combinado
  List<Compra> get _filteredCompras {
    List<Compra> filtered = _compras.where((c) {
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final proveedor = c.proveedor?.name.toLowerCase() ?? '';
        final comprobante = c.comprobante?.toLowerCase() ?? '';
        final idStr = c.id.toString();
        matchesSearch =
            proveedor.contains(query) ||
            comprobante.contains(query) ||
            idStr.contains(query);
      }

      bool matchesDate = true;
      if (_startDate != null && _endDate != null) {
        try {
          final cDate = DateTime.parse(c.fecha.split('T')[0]);
          final start = DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
          );
          final end = DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
            23,
            59,
            59,
          );
          matchesDate =
              cDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
              cDate.isBefore(end.add(const Duration(seconds: 1)));
        } catch (_) {}
      }

      return matchesSearch && matchesDate;
    }).toList();

    filtered.sort((a, b) {
      if (_sortOrder == 'desc') {
        return b.total.compareTo(a.total);
      } else {
        return a.total.compareTo(b.total);
      }
    });

    return filtered;
  }

  // Cálculos dinámicos basados en la lista filtrada
  double get _currentSubtotal =>
      _filteredCompras.fold(0, (sum, item) => sum + item.subtotal);
  double get _currentItbis => _filteredCompras.fold(
    0,
    (sum, item) => sum + (item.total - item.subtotal),
  );
  double get _currentTotal =>
      _filteredCompras.fold(0, (sum, item) => sum + item.total);

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
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

    final displayedCompras = _filteredCompras;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1100,
        ), // Optimizado para pantallas grandes
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Búsqueda y Filtros
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 320,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar proveedor o NCF...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.blue.shade700,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue.shade400),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: Icon(
                      Icons.date_range,
                      size: 18,
                      color: Colors.blue.shade700,
                    ),
                    label: Text(
                      _startDate == null
                          ? 'Filtrar Fecha'
                          : '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                      style: TextStyle(color: Colors.blue.shade800),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: _startDate != null
                          ? Colors.blue.shade50
                          : Colors.white,
                    ),
                    onPressed: _pickDateRange,
                  ),
                  if (_startDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      tooltip: 'Limpiar fecha',
                      onPressed: () => setState(() {
                        _startDate = null;
                        _endDate = null;
                      }),
                    ),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortOrder,
                        icon: const Icon(Icons.sort, color: Colors.grey),
                        items: [
                          DropdownMenuItem(
                            value: 'desc',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_downward,
                                  size: 16,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 8),
                                const Text('Mayor a Menor'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'asc',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_upward,
                                  size: 16,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 8),
                                const Text('Menor a Mayor'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (val) => setState(() => _sortOrder = val!),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.print, color: Colors.deepOrange),
                    label: const Text(
                      'Imprimir',
                      style: TextStyle(color: Colors.deepOrange),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      side: BorderSide(color: Colors.deepOrange.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.deepOrange.shade50,
                    ),
                    onPressed: () async {
                      String url =
                          '$host/reports/compras/pdf?proyecto_id=${widget.proyecto.id}';
                      if (_startDate != null && _endDate != null) {
                        url +=
                            '&fecha_inicio=${DateFormat('yyyy-MM-dd').format(_startDate!)}';
                        url +=
                            '&fecha_fin=${DateFormat('yyyy-MM-dd').format(_endDate!)}';
                      }
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                ],
              ),
            ),

            // Tarjetas de Resumen
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Compras',
                      f.format(_currentTotal),
                      Colors.blue[700]!,
                      Icons.shopping_bag,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Subtotal',
                      f.format(_currentSubtotal),
                      Colors.blueGrey[700]!,
                      Icons.receipt_long,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Total ITBIS',
                      f.format(_currentItbis),
                      Colors.orange[700]!,
                      Icons.percent,
                    ),
                  ),
                ],
              ),
            ),

            // Lista de Compras
            Expanded(
              child: displayedCompras.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No se encontraron compras con esos filtros.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: displayedCompras.length,
                      itemBuilder: (context, index) {
                        final c = displayedCompras[index];
                        final double total = c.total;
                        final double subtotal = c.subtotal;
                        final double itbis = total - subtotal;
                        final isRecibido = c.estado == 'Recibido';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.grey.shade50],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icono decorativo de Estado
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        (isRecibido
                                                ? Colors.green
                                                : Colors.orange)
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isRecibido
                                        ? Icons.check_circle
                                        : Icons.hourglass_empty,
                                    color: isRecibido
                                        ? Colors.green
                                        : Colors.orange,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Detalles de la compra
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              c.proveedor?.name ??
                                                  'Proveedor Desconocido',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFF1A1C1E),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            f.format(total),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 18,
                                              color: Color(0xFF1A1C1E),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Colors.blue.shade100,
                                              ),
                                            ),
                                            child: Text(
                                              'ID: #${c.id} • ${c.tipoCompra}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.blue.shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            c.fecha.split('T')[0],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          Text(
                                            'Subtotal: ${f.format(subtotal)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          Text(
                                            '• ITBIS: ${f.format(itbis)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          if (c.comprobante != null &&
                                              c.comprobante!.isNotEmpty)
                                            Text(
                                              '• NCF: ${c.comprobante}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade900,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Botones de Acciones (Información e Imprimir)
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.print_outlined),
                                      color: Colors.red.shade600,
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.red.shade50,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      tooltip: 'Imprimir Factura / PDF',
                                      onPressed: () async {
                                        final url = Uri.parse(
                                          '$host/compras/${c.id}/print',
                                        );
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url);
                                        } else {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'No se pudo abrir el recibo',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    IconButton(
                                      icon: const Icon(Icons.visibility),
                                      color: Colors.blue.shade700,
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.blue.shade50,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      tooltip: 'Ver Detalles Completos',
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) =>
                                              _CompraDetailModal(
                                                compraId: c.id,
                                              ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget de Resumen Mejorado
  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
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

class _CompraDetailModal extends StatefulWidget {
  final int compraId;
  const _CompraDetailModal({required this.compraId});

  @override
  State<_CompraDetailModal> createState() => _CompraDetailModalState();
}

class _CompraDetailModalState extends State<_CompraDetailModal> {
  final PurchaseService _purchaseService = PurchaseService();
  bool _isLoading = true;
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
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
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 300,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_detail == null) {
      return Container(
        height: 300,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: Text('No se pudo cargar el detalle')),
      );
    }

    final detail = _detail!;
    final f = NumberFormat.currency(symbol: '\$');
    final detalles = detail['detalles'] as List? ?? [];
    final estado = detail['estado'] ?? 'N/A';
    final estadoColor = estado == 'Pendiente' ? Colors.orange : Colors.green;

    final subtotal =
        double.tryParse(detail['subtotal']?.toString() ?? '0') ?? 0;
    final itbis = double.tryParse(detail['itbis']?.toString() ?? '0') ?? 0;
    final total = double.tryParse(detail['total']?.toString() ?? '0') ?? 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Factura #${detail['id']}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.print, color: Colors.black54),
                    onPressed: () async {
                      final url = Uri.parse(
                        '$host/compras/${detail['id']}/print',
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                fontSize: 11,
              ),
            ),
          ),
          const Divider(height: 32, color: Color(0xFFEEEEEE)),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info
                  _buildInfoItem(
                    'Proveedor',
                    detail['proveedor']?['nombre'] ?? 'N/A',
                    Icons.store,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    'Proyecto',
                    detail['proyecto']?['nombre'] ?? 'N/A',
                    Icons.business,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Fecha',
                          detail['fecha']?.toString().split('T')[0] ?? 'N/A',
                          Icons.calendar_today,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          'Tipo',
                          detail['tipo_compra'] ?? 'N/A',
                          Icons.payment,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Comprobante',
                          detail['comprobante'] ?? 'N/A',
                          Icons.confirmation_number,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          'Orden #',
                          detail['orden'] ?? 'N/A',
                          Icons.receipt_long,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Código Ref.',
                          detail['codigo'] ?? 'N/A',
                          Icons.qr_code,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          'Vencimiento',
                          detail['fecha_vencimiento']?.toString().split(
                                'T',
                              )[0] ??
                              'N/A',
                          Icons.event_note,
                        ),
                      ),
                    ],
                  ),
                  if (detail['nota'] != null &&
                      detail['nota'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      'Notas / Observaciones',
                      detail['nota'],
                      Icons.info_outline,
                    ),
                  ],

                  // Artículos
                  const Divider(height: 32, color: Color(0xFFEEEEEE)),
                  const Text(
                    'Artículos / Materiales',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...detalles.map((d) {
                    final mat = d['material'];
                    final cantidad =
                        double.tryParse(d['cantidad']?.toString() ?? '0') ?? 0;
                    final precio =
                        double.tryParse(
                          d['precio_unitario']?.toString() ?? '0',
                        ) ??
                        0;
                    final subtotalVal =
                        double.tryParse(d['subtotal']?.toString() ?? '0') ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 12,
                      ),
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${cantidad.toStringAsFixed(2)} x ${f.format(precio)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            f.format(subtotalVal),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // Totals Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
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
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.black87,
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
}
