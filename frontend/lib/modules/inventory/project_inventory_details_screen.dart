import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/inventory_service.dart';
import '../../services/project_service.dart';
import '../../core/constants.dart';
import '../../models/proyecto.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Inventario: ${widget.proyectoNombre}'),
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
              icon: const Icon(Icons.picture_as_pdf),
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
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Balance de Stock'),
              Tab(text: 'Movimientos'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(children: [_buildBalanceTab(), _buildMovementsTab()]),
      ),
    );
  }

  Widget _buildBalanceTab() {
    final balance = _data?['balance'] as List? ?? [];
    final f = NumberFormat.currency(symbol: '\$');

    if (balance.isEmpty) {
      return const Center(child: Text('No hay materiales en este proyecto.'));
    }

    final filteredBalance = balance.where((item) {
      final name = item['material']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery);
    }).toList();

    return Column(
      children: [
        _buildSummaryRow(balance, f),
        _buildSearchBar(),
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
    final totalInversion = balance.fold(
      0.0,
      (sum, item) =>
          sum +
          ((double.tryParse(item['stock'].toString()) ?? 0) *
              (double.tryParse(item['ultimo_costo'].toString()) ?? 0)),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildKPICard(
              title: 'Total Materiales',
              value: '$totalMateriales',
              icon: Icons.category_outlined,
              color: Colors.blue.shade700,
              backgroundColor: Colors.blue.shade50,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildKPICard(
              title: 'Inversión Total',
              value: f.format(totalInversion),
              icon: Icons.monetization_on_outlined,
              color: Colors.green.shade700,
              backgroundColor: Colors.green.shade50,
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.1)),
      ),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Buscar material...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF003366)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildCardView(List filteredBalance, NumberFormat f) {
    if (filteredBalance.isEmpty) {
      return const Center(
        child: Text('No se encontraron materiales con ese nombre.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: filteredBalance.length,
      itemBuilder: (context, index) {
        final item = filteredBalance[index];
        final stock = double.tryParse(item['stock'].toString()) ?? 0;
        final costo = double.tryParse(item['ultimo_costo'].toString()) ?? 0;
        final inversion = stock * costo;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['material'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blueGrey.shade100),
                      ),
                      child: Text(
                        item['unidad'] ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildCardDetail(
                        'Entradas',
                        item['entradas'].toString(),
                      ),
                    ),
                    Expanded(
                      child: _buildCardDetail(
                        'Salidas',
                        item['salidas'].toString(),
                      ),
                    ),
                    Expanded(
                      child: _buildCardDetail(
                        'Balance',
                        stock.toString(),
                        valueColor: Colors.blue.shade700,
                        isBold: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildCardDetail('Últ. Costo', f.format(costo)),
                    ),
                    Expanded(
                      child: _buildCardDetail(
                        'Inversión',
                        f.format(inversion),
                        valueColor: Colors.green.shade700,
                        isBold: true,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Acciones',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: stock > 0
                                ? Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      InkWell(
                                        onTap: () => _showConsumoDialog(item),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.red.shade200,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.remove_circle_outline,
                                                size: 14,
                                                color: Colors.red.shade700,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Retirar',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _showTransferDialog(item),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.orange.shade200,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.swap_horiz,
                                                size: 14,
                                                color: Colors.orange.shade700,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Transferir',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.remove_circle_outline,
                                          size: 14,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Vacío',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
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
        );
      },
    );
  }

  Widget _buildCardDetail(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
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
                          item['unidad'] ?? '',
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
    int? selectedProyectoDestinoId;
    List<Proyecto> proyectosDestino = [];
    bool loading = true;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (loading) {
            _projectService
                .getProyectos()
                .then((proyectosList) {
                  final list = proyectosList
                      .where((p) => p.id != widget.proyectoId)
                      .toList();
                  if (context.mounted) {
                    setDialogState(() {
                      proyectosDestino = list;
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
                      SnackBar(content: Text('Error al cargar proyectos: $e')),
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
                                  initialValue: selectedProyectoDestinoId,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Proyecto o Almacén Destino *',
                                    prefixIcon: const Icon(Icons.domain),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: proyectosDestino
                                      .map(
                                        (p) => DropdownMenuItem<int>(
                                          value: p.id,
                                          child: Text(
                                            p.esAlmacen
                                                ? "🏢 ${p.nombre} (ALMACÉN)"
                                                : "🚧 ${p.nombre}",
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
                                          () => selectedProyectoDestinoId = v,
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
                                  loading ||
                                      selectedProyectoDestinoId == null ||
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
                                            .registrarTransferencia({
                                              'material_id':
                                                  material['material_id'],
                                              'proyecto_origen_id':
                                                  widget.proyectoId,
                                              'proyecto_destino_id':
                                                  selectedProyectoDestinoId,
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
    final f = NumberFormat.currency(symbol: '\$');

    if (movimientos.isEmpty) {
      return const Center(child: Text('No hay movimientos registrados.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.blueGrey.shade50),
            columns: const [
              DataColumn(
                label: Text(
                  'Tipo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Fecha',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Referencia',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Material',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Cant.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Costo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: [
              ...movimientos.map((mov) {
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
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          mov['tipo'],
                          style: TextStyle(
                            color: isEntrada
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(mov['fecha'])),
                    DataCell(Text(mov['referencia'])),
                    DataCell(Text(mov['material'])),
                    DataCell(
                      Text(
                        "${isEntrada ? '+' : '-'}$cantidad",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isEntrada ? Colors.green : Colors.red,
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
                color: WidgetStateProperty.all(Colors.blueGrey.shade50),
                cells: [
                  const DataCell(
                    Text(
                      'TOTAL ACUMULADO',
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
                        movimientos.fold(0.0, (sum, mov) {
                          final cant =
                              double.tryParse(mov['cantidad'].toString()) ?? 0;
                          final cost =
                              double.tryParse(mov['costo'].toString()) ?? 0;
                          return sum + (cant * cost);
                        }),
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
