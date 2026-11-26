import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/inventory_service.dart';
import '../../services/project_service.dart';
import '../../core/constants.dart';
import '../../models/proyecto.dart';
import '../../models/local_inventory.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/app_header_bar.dart';

class ProjectInventoryDetailsScreen extends StatefulWidget {
  final int proyectoId;
  final String proyectoNombre;

  const ProjectInventoryDetailsScreen({
    super.key,
    required this.proyectoId,
    required this.proyectoNombre,
  });

  @override
  State<ProjectInventoryDetailsScreen> createState() =>
      _ProjectInventoryDetailsScreenState();
}

class _ProjectInventoryDetailsScreenState
    extends State<ProjectInventoryDetailsScreen> {
  final InventoryService _inventoryService = InventoryService();
  final ProjectService _projectService = ProjectService();
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _movSearchController = TextEditingController();
  String _searchQuery = '';
  String _stockFilter = 'TODOS';
  String _movSearchQuery = '';
  String _movTypeFilter = 'TODOS';
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _movSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _inventoryService.getInventarioDetalleProyecto(
        widget.proyectoId,
      );
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _formatUnidad(dynamic u) {
    if (u == null) return 'UND';
    final str = u.toString().trim();
    if (str.isEmpty || int.tryParse(str) != null) return 'UND';
    return str.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final balance = _data?['balance'] as List? ?? [];
    final movimientos = _data?['movimientos'] as List? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppHeaderBar(
        title: 'Inventario: ${widget.proyectoNombre}',
        subtitle: 'Control de Stock e Historial de Movimientos',
        badgeLetter: 'I',
        showMenuButton: false,
        onBack: () => Navigator.of(context).pop(),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final url = Uri.parse(
                '$host/api/v1/inventario-proyectos/${widget.proyectoId}/pdf?tipo=$value',
              );
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('No se pudo abrir el PDF')),
                );
              }
            },
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
              color: Colors.white,
              size: 20,
            ),
            tooltip: 'Exportar Reporte PDF',
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'balance',
                child: Text('PDF: Balance de Stock'),
              ),
              const PopupMenuItem(
                value: 'movimientos',
                child: Text('PDF: Movimientos'),
              ),
              const PopupMenuItem(
                value: 'completo',
                child: Text('PDF: Reporte Completo'),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            onPressed: _isLoading ? null : _fetchData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
              ),
            )
          : Column(
              children: [
                // Selector de pestañas moderno y compacto (Pill Toggle)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedTab = 0),
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0
                                  ? const Color(0xFFE31E24)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 15,
                                  color: _selectedTab == 0
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Balance de Stock (${balance.length})',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedTab == 0
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedTab = 1),
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1
                                  ? const Color(0xFFE31E24)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.swap_vert_rounded,
                                  size: 16,
                                  color: _selectedTab == 1
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Movimientos (${movimientos.length})',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedTab == 1
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenido según la pestaña activa
                Expanded(
                  child: _selectedTab == 0
                      ? _buildBalanceTab()
                      : _buildMovementsTab(),
                ),
              ],
            ),
    );
  }

  Widget _buildBalanceTab() {
    final balance = _data?['balance'] as List? ?? [];
    final f = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);

    if (balance.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No hay materiales registrados en este proyecto.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filteredBalance = balance.where((item) {
      final stock = double.tryParse(item['stock'].toString()) ?? 0;
      if (_stockFilter == 'CON_STOCK' && stock <= 0) return false;
      if (_stockFilter == 'AGOTADOS' && stock > 0) return false;

      if (_searchQuery.isNotEmpty) {
        final name = (item['material'] ?? '').toString().toLowerCase();
        final unidad = (item['unidad'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery) || unidad.contains(_searchQuery);
      }
      return true;
    }).toList();

    return Column(
      children: [
        _buildSummaryRow(balance, f),
        _buildSearchBar(balance),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 750) {
                return _buildCardView(filteredBalance, f);
              } else {
                return _buildTableView(filteredBalance, f);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(List balance, NumberFormat f) {
    final totalMateriales = balance.length;
    double totalInversion = 0;
    for (final item in balance) {
      final stock = double.tryParse(item['stock'].toString()) ?? 0;
      final costo = double.tryParse(item['ultimo_costo'].toString()) ?? 0;
      totalInversion += (stock * costo);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: _buildKPICard(
              title: 'TOTAL MATERIALES',
              value: '$totalMateriales',
              icon: Icons.category_rounded,
              color: const Color(0xFF2563EB),
              backgroundColor: const Color(0xFFEFF6FF),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildKPICard(
              title: 'INVERSIÓN EN STOCK',
              value: f.format(totalInversion),
              icon: Icons.monetization_on_rounded,
              color: const Color(0xFF059669),
              backgroundColor: const Color(0xFFECFDF5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(List balance) {
    final withStockCount = balance.where((item) {
      final stock = double.tryParse(item['stock'].toString()) ?? 0;
      return stock > 0;
    }).length;
    final outOfStockCount = balance.length - withStockCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Column(
        children: [
          SizedBox(
            height: 38,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Buscar material por nombre...',
                hintStyle:
                    const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                prefixIcon:
                    const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFFE31E24), width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFilterChip(
                label: 'Todos (${balance.length})',
                isSelected: _stockFilter == 'TODOS',
                onTap: () => setState(() => _stockFilter = 'TODOS'),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'En Stock ($withStockCount)',
                isSelected: _stockFilter == 'CON_STOCK',
                activeColor: const Color(0xFF059669),
                onTap: () => setState(() => _stockFilter = 'CON_STOCK'),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Agotados ($outOfStockCount)',
                isSelected: _stockFilter == 'AGOTADOS',
                activeColor: const Color(0xFFDC2626),
                onTap: () => setState(() => _stockFilter = 'AGOTADOS'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color activeColor = const Color(0xFF0F172A),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.1)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFCBD5E1),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? activeColor : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildCardView(List filteredBalance, NumberFormat f) {
    if (filteredBalance.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No se encontraron materiales.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: filteredBalance.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = filteredBalance[index];
        final stock = double.tryParse(item['stock'].toString()) ?? 0;
        final costo = double.tryParse(item['ultimo_costo'].toString()) ?? 0;
        final entradas = double.tryParse(item['entradas'].toString()) ?? 0;
        final salidas = double.tryParse(item['salidas'].toString()) ?? 0;
        final inversion = stock * costo;
        final hasStock = stock > 0;
        final unidad = _formatUnidad(item['unidad']);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasStock
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFFF1F5F9),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila Superior: Icono de Categoría, Nombre y Badge de Unidad/Estado
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: hasStock
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.layers_rounded,
                      size: 20,
                      color: hasStock
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['material'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Unidad: $unidad · Últ. Costo: ${f.format(costo)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Badge Stock Actual
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasStock
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: hasStock
                            ? const Color(0xFFA7F3D0)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasStock
                                ? const Color(0xFF059669)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          hasStock ? '$stock $unidad' : 'Agotado',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: hasStock
                                ? const Color(0xFF065F46)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Barra de Flujo y Métricas
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Entradas',
                            style:
                                TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '+$entradas',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 24, width: 1, color: const Color(0xFFE2E8F0)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Salidas',
                            style:
                                TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '-$salidas',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 24, width: 1, color: const Color(0xFFE2E8F0)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Inversión Stock',
                            style:
                                TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            f.format(inversion),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: hasStock
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Botones de acción sólo si hay stock
              if (hasStock) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () => _showConsumoDialog(item),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.remove_circle_outline,
                              size: 14,
                              color: Color(0xFFDC2626),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Retirar (Consumo)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showTransferDialog(item),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.swap_horiz,
                                size: 15, color: Color(0xFFD97706)),
                            SizedBox(width: 5),
                            Text(
                              'Transferir',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableView(List filteredBalance, NumberFormat f) {
    if (filteredBalance.isEmpty) {
      return const Center(
        child: Text('No se encontraron materiales con ese nombre.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.blueGrey.shade50),
            columns: const [
              DataColumn(
                label: Text(
                  'Material',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Unidad',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Entradas',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Salidas',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Balance',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Últ. Costo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Inversión',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Acciones',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: [
              ...filteredBalance.map((item) {
                final stock = double.tryParse(item['stock'].toString()) ?? 0;
                final costo =
                    double.tryParse(item['ultimo_costo'].toString()) ?? 0;
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        item['material'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatUnidad(item['unidad']),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade700,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(item['entradas'].toString())),
                    DataCell(Text(item['salidas'].toString())),
                    DataCell(
                      Text(
                        stock.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    DataCell(Text(f.format(costo))),
                    DataCell(
                      Text(
                        f.format(stock * costo),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(
                      stock > 0
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _showConsumoDialog(item),
                                  tooltip: 'Registrar Salida (Consumo)',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.swap_horiz,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () => _showTransferDialog(item),
                                  tooltip: 'Transferir Material',
                                ),
                              ],
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: Colors.grey.shade400,
                              ),
                              onPressed: null,
                              tooltip: 'Sin Stock',
                            ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showConsumoDialog(dynamic material) async {
    final cantidadController = TextEditingController();
    int? selectedSubpartidaId;
    List<dynamic> subpartidas = [];
    bool loading = true;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (loading) {
            _projectService
                .getPartidas(widget.proyectoId)
                .then((partidasData) {
                  // Aplanamos subpartidas para el dropdown
                  List<dynamic> allSub = [];
                  final List<dynamic> partidas = partidasData
                      .map((p) => p.toJson())
                      .toList();
                  for (var p in partidas) {
                    if (p['subpartidas'] != null) {
                      for (var s in p['subpartidas']) {
                        allSub.add({
                          'id': s['id'],
                          'nombre':
                              "${p['descripcion']} -> ${s['descripcion']}",
                        });
                      }
                    }
                  }
                  if (context.mounted) {
                    setDialogState(() {
                      subpartidas = allSub;
                      loading = false;
                    });
                  }
                })
                .catchError((e) {
                  if (context.mounted) {
                    setDialogState(() {
                      loading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al cargar partidas: $e')),
                    );
                  }
                });
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cabecera Premium
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFF003366),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Registrar Salida',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Salida de Material: ${material['material']}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Disponibilidad Info Box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Disponible: ${material['stock']} ${material['unidad']}',
                                    style: TextStyle(
                                      color: Colors.blue.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            'DETALLES DE LA SALIDA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                              fontSize: 11,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Dropdown para partidas/subpartidas
                          loading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : DropdownButtonFormField<int>(
                                  initialValue: selectedSubpartidaId,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Destino (Sub-partida) *',
                                    prefixIcon: const Icon(
                                      Icons.account_tree_outlined,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: subpartidas
                                      .map(
                                        (s) => DropdownMenuItem<int>(
                                          value: s['id'],
                                          child: Text(
                                            s['nombre'],
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: saving
                                      ? null
                                      : (v) => setDialogState(
                                          () => selectedSubpartidaId = v,
                                        ),
                                ),
                          const SizedBox(height: 16),

                          // Input Cantidad
                          TextField(
                            controller: cantidadController,
                            enabled: !saving,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText:
                                  'Cantidad a retirar (${material['unidad']}) *',
                              prefixIcon: const Icon(Icons.numbers),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Botón de Confirmación
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed:
                                  loading ||
                                      selectedSubpartidaId == null ||
                                      saving
                                  ? null
                                  : () async {
                                      final cant =
                                          double.tryParse(
                                            cantidadController.text,
                                          ) ??
                                          0;
                                      if (cant <= 0 ||
                                          cant >
                                              double.parse(
                                                material['stock'].toString(),
                                              )) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Cantidad no válida o insuficiente',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      setDialogState(() => saving = true);

                                      try {
                                        await _inventoryService
                                            .registrarConsumo({
                                              'proyecto_id': widget.proyectoId,
                                              'material_id':
                                                  material['material_id'],
                                              'subpartida_id':
                                                  selectedSubpartidaId,
                                              'cantidad': cant,
                                              'fecha': DateFormat(
                                                'yyyy-MM-dd',
                                              ).format(DateTime.now()),
                                            });
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          _fetchData();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Salida registrada con éxito',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          setDialogState(() => saving = false);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFA000),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: saving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'CONFIRMAR SALIDA',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
        },
      ),
    );
  }

  void _showTransferDialog(dynamic material) async {
    final cantidadController = TextEditingController();
    final observacionesController = TextEditingController();
    dynamic selectedDestino; // Can be Proyecto or LocalInventory
    List<dynamic> destinos = [];
    bool loadingDestinos = true;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (loadingDestinos) {
            Future.wait([
              _projectService.getProyectos(),
              _inventoryService.getLocalInventories(),
            ]).then((results) {
              final projects = results[0] as List<Proyecto>;
              final localInventories = results[1] as List<LocalInventory>;

              final list = [];
              list.addAll(projects.where((p) => p.id != widget.proyectoId));
              list.addAll(localInventories);

              if (context.mounted) {
                setDialogState(() {
                  destinos = list;
                  loadingDestinos = false;
                });
              }
            }).catchError((e) {
              if (context.mounted) {
                setDialogState(() => loadingDestinos = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al cargar destinos: $e')),
                );
              }
            });
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFF003366),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.swap_horiz,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Transferir Material',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Material: ${material['material']}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Disponible en este proyecto: ${material['stock']} ${material['unidad']}',
                                    style: TextStyle(
                                      color: Colors.blue.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'DETALLES DE LA TRANSFERENCIA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                              fontSize: 11,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          loadingDestinos
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : DropdownButtonFormField<dynamic>(
                                  initialValue: selectedDestino,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Proyecto o Almacén Destino *',
                                    prefixIcon: const Icon(Icons.domain),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: destinos
                                      .map(
                                        (dest) {
                                          final bool isProject = dest is Proyecto;
                                          final String label = isProject
                                              ? "🚧 Proyecto: ${dest.nombre}"
                                              : "🏢 Almacén: ${dest.nameInventario}";

                                          return DropdownMenuItem<dynamic>(
                                            value: dest,
                                            child: Text(
                                              label,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                      .toList(),
                                  onChanged: saving
                                      ? null
                                      : (v) => setDialogState(
                                          () => selectedDestino = v,
                                        ),
                                ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: cantidadController,
                            enabled: !saving,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText:
                                  'Cantidad a transferir (${material['unidad']}) *',
                              prefixIcon: const Icon(Icons.numbers),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: observacionesController,
                            enabled: !saving,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Observaciones / Motivo',
                              prefixIcon: const Icon(Icons.comment_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed:
                                  loadingDestinos ||
                                      selectedDestino == null ||
                                      saving
                                  ? null
                                  : () async {
                                      final cant =
                                          double.tryParse(
                                            cantidadController.text,
                                          ) ??
                                          0;
                                      if (cant <= 0 ||
                                          cant >
                                              double.parse(
                                                material['stock'].toString(),
                                              )) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Cantidad no válida o insuficiente',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      setDialogState(() => saving = true);

                                      final isProject = selectedDestino is Proyecto;

                                      try {
                                        await _inventoryService
                                            .registrarTransferencia({
                                              'material_id':
                                                  material['material_id'],
                                              'proyecto_origen_id':
                                                  widget.proyectoId,
                                              'proyecto_destino_id':
                                                  isProject ? selectedDestino.id : null,
                                              'inventario_local_destino_id':
                                                  !isProject ? selectedDestino.id : null,
                                              'cantidad': cant,
                                              'fecha': DateFormat(
                                                'yyyy-MM-dd',
                                              ).format(DateTime.now()),
                                              'observaciones':
                                                  observacionesController.text,
                                            });

                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          _fetchData();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Transferencia realizada con éxito',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          setDialogState(() => saving = false);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFA000),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: saving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'CONFIRMAR TRANSFERENCIA',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
        },
      ),
    );
  }

  Widget _buildMovementsTab() {
    final movimientos = _data?['movimientos'] as List? ?? [];
    final f = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);

    if (movimientos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No hay movimientos registrados en este proyecto.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filteredMovimientos = movimientos.where((mov) {
      if (_movTypeFilter != 'TODOS' && mov['tipo'] != _movTypeFilter) {
        return false;
      }
      if (_movSearchQuery.isNotEmpty) {
        final mat = (mov['material'] ?? '').toString().toLowerCase();
        final ref = (mov['referencia'] ?? '').toString().toLowerCase();
        final fecha = (mov['fecha'] ?? '').toString().toLowerCase();
        return mat.contains(_movSearchQuery) ||
            ref.contains(_movSearchQuery) ||
            fecha.contains(_movSearchQuery);
      }
      return true;
    }).toList();

    return Column(
      children: [
        _buildMovementsFilterBar(movimientos),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 750) {
                return _buildMovementsCardList(filteredMovimientos, f);
              } else {
                return _buildMovementsTableView(filteredMovimientos, f);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMovementsFilterBar(List allMovimientos) {
    final entradasCount =
        allMovimientos.where((m) => m['tipo'] == 'Entrada').length;
    final salidasCount =
        allMovimientos.where((m) => m['tipo'] == 'Salida').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        children: [
          // Buscador
          SizedBox(
            height: 38,
            child: TextField(
              controller: _movSearchController,
              style: const TextStyle(fontSize: 13),
              onChanged: (val) {
                setState(() => _movSearchQuery = val.trim().toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Buscar movimiento por material o referencia...',
                hintStyle:
                    const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                prefixIcon:
                    const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                suffixIcon: _movSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _movSearchController.clear();
                          setState(() => _movSearchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFFE31E24), width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Píldoras de filtro rápido
          Row(
            children: [
              _buildFilterChip(
                label: 'Todos (${allMovimientos.length})',
                isSelected: _movTypeFilter == 'TODOS',
                onTap: () => setState(() => _movTypeFilter = 'TODOS'),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Entradas ($entradasCount)',
                isSelected: _movTypeFilter == 'Entrada',
                activeColor: const Color(0xFF059669),
                onTap: () => setState(() => _movTypeFilter = 'Entrada'),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Salidas ($salidasCount)',
                isSelected: _movTypeFilter == 'Salida',
                activeColor: const Color(0xFFDC2626),
                onTap: () => setState(() => _movTypeFilter = 'Salida'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMovementsCardList(List filteredMovimientos, NumberFormat f) {
    if (filteredMovimientos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No se encontraron movimientos con los filtros aplicados.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: filteredMovimientos.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final mov = filteredMovimientos[index];
        final isEntrada = mov['tipo'] == 'Entrada';
        final cantidad = double.tryParse(mov['cantidad'].toString()) ?? 0;
        final costo = double.tryParse(mov['costo'].toString()) ?? 0;
        final total = cantidad * costo;
        final fecha = mov['fecha']?.toString() ?? '';
        final material =
            mov['material']?.toString() ?? 'Material no especificado';
        final referencia = mov['referencia']?.toString() ?? '';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila 1: Badge Tipo + Fecha + Cantidad destacada
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: isEntrada
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isEntrada
                                ? const Color(0xFFA7F3D0)
                                : const Color(0xFFFECACA),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isEntrada
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              size: 13,
                              color: isEntrada
                                  ? const Color(0xFF047857)
                                  : const Color(0xFFB91C1C),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isEntrada ? 'Entrada' : 'Salida',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isEntrada
                                    ? const Color(0xFF047857)
                                    : const Color(0xFFB91C1C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        fecha,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${isEntrada ? '+' : '-'}$cantidad',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isEntrada
                          ? const Color(0xFF047857)
                          : const Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Fila 2: Material
              Text(
                material,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),

              if (referencia.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        referencia,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 6),

              // Fila 3: Costo Unitario & Importe Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Costo Unit: ${f.format(costo)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        'Total: ',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        f.format(total),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
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
    );
  }

  Widget _buildMovementsTableView(List filteredMovimientos, NumberFormat f) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            columns: const [
              DataColumn(
                label: Text(
                  'Tipo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
              DataColumn(
                label: Text(
                  'Fecha',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
              DataColumn(
                label: Text(
                  'Referencia',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
              DataColumn(
                label: Text(
                  'Material',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
              DataColumn(
                label: Text(
                  'Cant.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
              DataColumn(
                label: Text(
                  'Costo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
              DataColumn(
                label: Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
            ],
            rows: [
              ...filteredMovimientos.map((mov) {
                final isEntrada = mov['tipo'] == 'Entrada';
                final cantidad =
                    double.tryParse(mov['cantidad'].toString()) ?? 0;
                final costo = double.tryParse(mov['costo'].toString()) ?? 0;
                final total = cantidad * costo;

                return DataRow(
                  cells: [
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isEntrada
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isEntrada
                                ? const Color(0xFFA7F3D0)
                                : const Color(0xFFFECACA),
                          ),
                        ),
                        child: Text(
                          mov['tipo'],
                          style: TextStyle(
                            color: isEntrada
                                ? const Color(0xFF047857)
                                : const Color(0xFFB91C1C),
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(mov['fecha']?.toString() ?? '')),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Text(
                          mov['referencia']?.toString() ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        mov['material']?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(
                      Text(
                        "${isEntrada ? '+' : '-'}$cantidad",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isEntrada
                              ? const Color(0xFF047857)
                              : const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                    DataCell(Text(f.format(costo))),
                    DataCell(
                      Text(
                        f.format(total),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              }),
              // Fila de Total para Movimientos
              DataRow(
                color: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                cells: [
                  const DataCell(
                    Text(
                      'TOTAL FILTRADO',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const DataCell(Text('')),
                  const DataCell(Text('')),
                  const DataCell(Text('')),
                  const DataCell(Text('')),
                  const DataCell(Text('')),
                  DataCell(
                    Text(
                      f.format(
                        filteredMovimientos.fold(0.0, (sum, mov) {
                          final cant =
                              double.tryParse(mov['cantidad'].toString()) ?? 0;
                          final cost =
                              double.tryParse(mov['costo'].toString()) ?? 0;
                          return sum + (cant * cost);
                        }),
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
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
}
