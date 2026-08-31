import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/app_theme.dart';
import '../providers/cxc_provider.dart';
import '../services/cxc_service.dart';
import '../widgets/cxc_form_dialog.dart';

class CxcClienteDetailScreen extends StatefulWidget {
  final Map<String, dynamic> clienteAgrupado;

  const CxcClienteDetailScreen({super.key, required this.clienteAgrupado});

  @override
  State<CxcClienteDetailScreen> createState() => _CxcClienteDetailScreenState();
}

class _CxcClienteDetailScreenState extends State<CxcClienteDetailScreen> {
  final currencyFormatter = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );
  bool _isImporting = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _clienteId => widget.clienteAgrupado['id'];

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Emerald
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEC4899), // Pink
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.length % colors.length];
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length > 1 ? 2 : 1).toUpperCase();
  }

  Widget _buildPremiumChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importExcel() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        elevation: 24,
        shadowColor: Colors.black26,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 350),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.table_chart_outlined,
                      color: Colors.grey.shade800,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Importar CXC',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 20),
                Text(
                  'El archivo Excel/CSV debe seguir estrictamente este orden de columnas. La primera fila se ignorará (encabezados).',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildFormatRow(
                        'Columna A',
                        'Documento (Factura)',
                        isRequired: true,
                      ),
                      _buildFormatRow(
                        'Columna B',
                        'Monto Deuda Actual',
                        isRequired: true,
                      ),
                      _buildFormatRow(
                        'Columna C',
                        'Fecha Venc. (YYYY-MM-DD)',
                        isRequired: true,
                      ),
                      _buildFormatRow(
                        'Columna D',
                        'Monto Factura Original',
                        isRequired: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        foregroundColor: Colors.grey.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF1A1A1A,
                        ), // Classic premium black
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Importar',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
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

    if (confirm != true) return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes == null) throw Exception("No se pudo leer el archivo.");

        if (!mounted) return;
        setState(() => _isImporting = true);

        final cxcService = CxcService();
        final response = await cxcService.importarExcel(
          _clienteId,
          file.bytes!,
          file.name,
        );

        if (!mounted) return;
        setState(() => _isImporting = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Importación exitosa'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Refresh provider data
        Provider.of<CxcProvider>(context, listen: false).fetchCxcs();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al importar: $e'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  Widget _buildFormatRow(String col, String desc, {required bool isRequired}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 75,
            child: Text(
              col,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(
                color: isRequired
                    ? AppTheme.dangerColor.withOpacity(0.4)
                    : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(4),
              color: isRequired
                  ? AppTheme.dangerColor.withOpacity(0.04)
                  : Colors.transparent,
            ),
            child: Text(
              isRequired ? 'Obligatorio' : 'Opcional',
              style: TextStyle(
                fontSize: 9,
                color: isRequired ? AppTheme.dangerColor : Colors.grey.shade600,
                fontWeight: isRequired ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isPastDue(String dateStr, String status) {
    if (status.toLowerCase() != 'pendiente') return false;
    try {
      final date = DateTime.parse(dateStr);
      final todayDate = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      return date.isBefore(todayDate);
    } catch (e) {
      return false;
    }
  }

  int _diasVencidos(String dateStr, String status) {
    if (status.toLowerCase() != 'pendiente') return 0;
    try {
      final date = DateTime.parse(dateStr);
      final todayDate = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final diff = todayDate.difference(date).inDays;
      return diff > 0 ? diff : 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cliente = widget.clienteAgrupado;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(cliente['nombre'] ?? 'Detalle Cliente'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Consumer<CxcProvider>(
        builder: (context, provider, _) {
          // Filtrar CXC de este cliente específico
          var clienteCxcs = provider.cxcs
              .where((c) => c.clienteId == _clienteId)
              .toList();

          if (_searchQuery.isNotEmpty) {
            clienteCxcs = clienteCxcs
                .where(
                  (c) => c.documento.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
                )
                .toList();
          }

          final headerWidget = Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _avatarColor(cliente['nombre'] ?? ''),
                              _avatarColor(
                                cliente['nombre'] ?? '',
                              ).withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _avatarColor(
                                cliente['nombre'] ?? '',
                              ).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _initials(cliente['nombre'] ?? ''),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cliente['nombre'] ?? 'Sin Nombre',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildPremiumChip(
                                  Icons.phone_rounded,
                                  cliente['whatsapp'] ?? 'N/A',
                                  Colors.grey.shade700,
                                ),
                                _buildPremiumChip(
                                  Icons.calendar_today_rounded,
                                  '${cliente['dias_credito'] ?? 0} días crédito',
                                  AppTheme.ledhouseBlue,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Límite de Crédito',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currencyFormatter.format(
                                      double.tryParse(
                                            cliente['limite_credito']
                                                    ?.toString() ??
                                                '0',
                                          ) ??
                                          0,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade100),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isImporting ? null : _importExcel,
                          icon: _isImporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.upload_file_rounded),
                          label: const Text(
                            'Importación Masiva de CXC (Excel/CSV)',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF1A1A1A,
                            ), // Premium Black
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          // Classic Table for Documents
          final tableWidget = Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por número de documento...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                if (clienteCxcs.isEmpty)
                  const Expanded(
                    child: Center(child: Text('No se encontraron documentos.')),
                  )
                else
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(
                              Colors.grey.shade50,
                            ),
                            dataRowMinHeight: 65,
                            dataRowMaxHeight: 65,
                            headingTextStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                              fontSize: 13,
                            ),
                            columns: const [
                              DataColumn(label: Text('Documento')),
                              DataColumn(label: Text('Factura')),
                              DataColumn(label: Text('Deuda Pendiente')),
                              DataColumn(label: Text('Vencimiento')),
                              DataColumn(label: Text('Estado')),
                              DataColumn(label: Text('Acciones')),
                            ],
                            rows: clienteCxcs.map((cxc) {
                              final pastDue = _isPastDue(
                                cxc.fechaVencimiento,
                                cxc.estado,
                              );
                              final dias = _diasVencidos(
                                cxc.fechaVencimiento,
                                cxc.estado,
                              );
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: pastDue
                                                ? AppTheme.dangerColor
                                                      .withOpacity(0.1)
                                                : AppTheme.ledhouseBlue
                                                      .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.receipt_long_rounded,
                                            size: 16,
                                            color: pastDue
                                                ? AppTheme.dangerColor
                                                : AppTheme.ledhouseBlue,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          cxc.documento,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      currencyFormatter.format(
                                        cxc.montoFactura,
                                      ),
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      currencyFormatter.format(
                                        cxc.montoPendiente,
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: pastDue
                                            ? AppTheme.dangerColor
                                            : const Color(0xFF1F2937),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      cxc.fechaVencimiento,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    dias > 0
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.dangerColor
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: AppTheme.dangerColor
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            child: Text(
                                              '$dias días vencidos',
                                              style: const TextStyle(
                                                color: AppTheme.dangerColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        : Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.successColor
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: AppTheme.successColor
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            child: Text(
                                              cxc.estado.toUpperCase(),
                                              style: const TextStyle(
                                                color: AppTheme.successColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_rounded,
                                            color: AppTheme.ledhouseBlue,
                                            size: 20,
                                          ),
                                          tooltip: 'Editar',
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) =>
                                                  CxcFormDialog(cxc: cxc),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_rounded,
                                            color: AppTheme.dangerColor,
                                            size: 20,
                                          ),
                                          tooltip: 'Eliminar',
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                backgroundColor: Colors.white,
                                                title: const Text(
                                                  'Eliminar Documento',
                                                ),
                                                content: const Text(
                                                  '¿Está seguro de que desea eliminar este documento? Esta acción no se puede deshacer.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          ctx,
                                                          false,
                                                        ),
                                                    child: const Text(
                                                      'Cancelar',
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          ctx,
                                                          true,
                                                        ),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          AppTheme.dangerColor,
                                                    ),
                                                    child: const Text(
                                                      'Eliminar',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true &&
                                                cxc.id != null) {
                                              await provider.deleteCxc(cxc.id!);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(child: headerWidget),
                    ),
                    Expanded(flex: 6, child: tableWidget),
                  ],
                );
              }

              return Column(
                children: [
                  headerWidget,
                  Expanded(child: tableWidget),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
