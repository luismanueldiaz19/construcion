import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../models/partida.dart';
import '../../models/proyecto.dart';
import '../../models/subpartida.dart';
import '../../services/project_service.dart';
import '../../services/inventory_service.dart';
import '../../services/accounting_service.dart';
import 'gasto_proyecto_dialog.dart';
import 'widgets/gasto_card.dart';
import '../../models/avance_proyecto.dart';
import '../../models/gasto_proyecto.dart';
import '../../models/consumo_proyecto.dart';
import '../../models/compra.dart';
import '../../services/purchase_service.dart';
import 'project_documents_screen.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Proyecto proyecto;
  final bool embedded;
  final VoidCallback? onRefresh;

  const ProjectDetailsScreen({
    super.key,
    required this.proyecto,
    this.embedded = false,
    this.onRefresh,
  });

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  final ProjectService _projectService = ProjectService();
  final InventoryService _inventoryService = InventoryService();
  final AccountingService _accountingService = AccountingService();
  final ImagePicker _picker = ImagePicker();
  late Proyecto _proyecto;
  List<GastoProyecto> _gastos = [];
  List<ConsumoProyecto> _consumos = [];
  List<dynamic> _pagos = [];
  int _activeTabIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _proyecto = widget.proyecto;
    _refresh();
  }

  @override
  void didUpdateWidget(covariant ProjectDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.proyecto != oldWidget.proyecto) {
      setState(() {
        _proyecto = widget.proyecto;
      });
    }
  }

  Future<void> _refresh({bool notifyParent = false}) async {
    try {
      final updatedProyecto = await _projectService.getProyecto(_proyecto.id!);
      final gastos = await _projectService.getGastosProyecto(_proyecto.id!);
      final consumos = await _inventoryService.getConsumosProyecto(
        _proyecto.id!,
      );
      List<dynamic> projectPagos = [];
      try {
        final allPagos = await _accountingService.getAllPagosHistorial();
        projectPagos = allPagos
            .where(
              (item) =>
                  item['proyecto'] == updatedProyecto.nombre &&
                  item['tipo'] == 'Cobro',
            )
            .toList();
      } catch (e) {
        print("Error fetching pagos: $e");
      }

      if (mounted) {
        setState(() {
          _proyecto = updatedProyecto;
          _gastos = gastos;
          _consumos = consumos;
          _pagos = projectPagos;
          _isLoading = false;
        });
      }

      if (notifyParent && widget.onRefresh != null) {
        widget.onRefresh!();
      }
    } catch (e) {
      print("Error refreshing project: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar detalles: $e')));
      }
    }
  }

  Future<void> _provisionarTodo100() async {
    setState(() => _isLoading = true);
    try {
      await _projectService.provisionarTodo100(_proyecto.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('┬íProyecto provisionado al 100%!')),
      );
      await _refresh(notifyParent: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      try {
        setState(() => _isLoading = true);
        print(
          ">>> Iniciando subida de logo para el proyecto ${_proyecto.id}...",
        );
        final url = await _projectService.uploadLogo(_proyecto.id!, image);
        print(">>> Logo subido con ├⌐xito. URL devuelta: $url");
        await _refresh(notifyParent: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logo actualizado correctamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al subir logo: $e')));
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeLogo() async {
    try {
      setState(() => _isLoading = true);
      await _projectService.removeLogo(_proyecto.id!);
      await _refresh(notifyParent: true);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Logo eliminado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar logo: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cambiarEstado() async {
    List<String> opciones = [];
    String estadoActual = _proyecto.estado;

    if (estadoActual == 'Cotizaci├│n') {
      opciones = ['Activo', 'Cancelado'];
    } else if (estadoActual == 'Activo') {
      opciones = ['Terminado'];
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este proyecto ya est├í finalizado o cancelado.'),
        ),
      );
      return;
    }

    final nuevoEstado = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Estado del Proyecto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: opciones
              .map(
                (e) => ListTile(
                  title: Text(e),
                  onTap: () => Navigator.pop(context, e),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (nuevoEstado != null) {
      try {
        setState(() => _isLoading = true);
        await _projectService.updateProyectoEstado(_proyecto.id!, nuevoEstado);
        await _refresh(notifyParent: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Proyecto actualizado a: $nuevoEstado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cambiar estado: $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editNotas() async {
    final controller = TextEditingController(text: _proyecto.notas);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Notas / Observaciones'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Ingrese notas que aparecer├ín en el PDF...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        setState(() => _isLoading = true);
        await _projectService.updateProyecto(
          _proyecto.id!,
          Proyecto(
            id: _proyecto.id,
            nombre: _proyecto.nombre,
            cliente: _proyecto.cliente,
            ubicacion: _proyecto.ubicacion,
            presupuestoEstimado: _proyecto.presupuestoEstimado,
            estado: _proyecto.estado,
            notas: controller.text,
          ),
        );
        await _refresh(notifyParent: true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al guardar notas: $e')));
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmarProvision() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('┬┐Provisionar todo al 100%?'),
        content: const Text(
          'Esta acci├│n marcar├í todas las sub-partidas como completadas al 100% para fines de prueba y reporte. ┬┐Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _provisionarTodo100();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('S├ì, PROVISIONAR TODO'),
          ),
        ],
      ),
    );
  }

  bool get _isReadonly {
    return _proyecto.estado == 'Terminado' || _proyecto.estado == 'Cancelado';
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: Text(_proyecto.nombre),
        automaticallyImplyLeading: !widget.embedded,
        actions: [
          IconButton(
            onPressed: () async {
              final url = Uri.parse(
                '$host/reports/proyecto/${_proyecto.id}/pdf',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No se pudo abrir el reporte completo del proyecto',
                      ),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.picture_as_pdf, color: Colors.black54),
            tooltip: 'Imprimir Reporte Completo',
          ),

          if (!_isReadonly)
            IconButton(
              onPressed: _confirmarProvision,
              icon: const Icon(Icons.bolt, color: Colors.orangeAccent),
              tooltip: 'Provisionar Todo al 100% (Prueba)',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final bool isNarrow = width < 750;

                return Row(
                  children: [
                    _buildDetailsSidebar(isNarrow),
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Colors.black12,
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.grey.shade50,
                        child: _buildActiveTabContent(f),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildDetailsSidebar(bool isNarrow) {
    final accentColor = const Color(0xFFE31E24);
    final primaryColor = const Color(0xFF1A1C1E); // Dark Grey
    final secondaryColor = const Color(0xFF2C2F33); // Lighter Grey

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isNarrow ? 70 : 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primaryColor, secondaryColor],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSidebarItem(
                  0,
                  Icons.dashboard_outlined,
                  Icons.dashboard,
                  'Resumen',
                  isNarrow,
                  accentColor,
                ),
                _buildSidebarItem(
                  1,
                  Icons.construction_outlined,
                  Icons.construction,
                  'Partidas',
                  isNarrow,
                  accentColor,
                ),
                _buildSidebarItem(
                  2,
                  Icons.shopping_bag_outlined,
                  Icons.shopping_bag,
                  'Gastos',
                  isNarrow,
                  accentColor,
                ),
                _buildSidebarItem(
                  3,
                  Icons.payments_outlined,
                  Icons.payments,
                  'Pagos',
                  isNarrow,
                  accentColor,
                ),
                _buildSidebarItem(
                  4,
                  Icons.assessment_outlined,
                  Icons.assessment,
                  'Reportes',
                  isNarrow,
                  accentColor,
                ),
                _buildSidebarItem(
                  5,
                  Icons.folder_shared_outlined,
                  Icons.folder_shared,
                  'Documentos',
                  isNarrow,
                  accentColor,
                ),
                _buildSidebarItem(
                  6,
                  Icons.analytics_outlined,
                  Icons.analytics,
                  'Estado de Resultados',
                  isNarrow,
                  accentColor,
                ),
                _buildSidebarItem(
                  7,
                  Icons.shopping_cart_outlined,
                  Icons.shopping_cart,
                  'Compras',
                  isNarrow,
                  accentColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
    bool isNarrow,
    Color accentColor,
  ) {
    final isSelected = _activeTabIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            _activeTabIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: isNarrow ? 0 : 12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: isNarrow
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? Colors.white : Colors.white70,
                size: 20,
              ),
              if (!isNarrow) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 14,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(NumberFormat f) {
    switch (_activeTabIndex) {
      case 0:
        return _buildTabResumen(f);
      case 1:
        return _buildTabPartidas(f);
      case 2:
        return _buildTabGastos(f);
      case 3:
        return _buildTabPagos(f);
      case 4:
        return _buildTabReportes(f);
      case 5:
        return _buildTabDocumentos();
      case 6:
        return ProjectProfitLossView(
          proyecto: _proyecto,
          gastos: _gastos,
          consumos: _consumos,
        );
      case 7:
        return ProjectPurchasesView(proyecto: _proyecto);
      default:
        return const Center(child: Text('Pesta├▒a no encontrada'));
    }
  }

  Widget _buildTabResumen(NumberFormat f) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(f),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildProfitabilityCard(f)),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _buildCashFlowCard(f),
                          const SizedBox(height: 24),
                          _buildIndirectsBreakdown(f),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildProfitabilityCard(f),
                    const SizedBox(height: 24),
                    _buildCashFlowCard(f),
                    const SizedBox(height: 24),
                    _buildIndirectsBreakdown(f),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabPartidas(NumberFormat f) {
    final partidas = _proyecto.partidas;
    int total = partidas.length;
    int completadas = 0;
    int enProceso = 0;
    int pendientes = 0;

    for (var p in partidas) {
      final sub = p.subpartidas;
      if (sub.isEmpty) {
        pendientes++;
      } else if (sub.every((s) => s.avanceActual >= 100)) {
        completadas++;
      } else if (sub.every((s) => s.avanceActual == 0)) {
        pendientes++;
      } else {
        enProceso++;
      }
    }

    final totalConImpuestos =
        double.tryParse(
          _proyecto.totalPresupuestoConGlobales?.toString() ?? '0',
        ) ??
        0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final bool useGrid = constraints.maxWidth > 800;

              if (useGrid) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildDetailStatCard(
                        'Total de Partidas',
                        total.toString(),
                        Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailStatCard(
                        'Completadas',
                        completadas.toString(),
                        Colors.green,
                        subtitle:
                            '${total > 0 ? (completadas / total * 100).toStringAsFixed(1) : 0}%',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailStatCard(
                        'En Proceso',
                        enProceso.toString(),
                        Colors.blue,
                        subtitle:
                            '${total > 0 ? (enProceso / total * 100).toStringAsFixed(1) : 0}%',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailStatCard(
                        'Pendientes',
                        pendientes.toString(),
                        Colors.orange,
                        subtitle:
                            '${total > 0 ? (pendientes / total * 100).toStringAsFixed(1) : 0}%',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailStatCard(
                        'Presupuesto Total',
                        f.format(totalConImpuestos),
                        const Color(0xFF003366),
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailStatCard(
                            'Total Partidas',
                            total.toString(),
                            Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailStatCard(
                            'Completadas',
                            completadas.toString(),
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailStatCard(
                            'En Proceso',
                            enProceso.toString(),
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailStatCard(
                            'Pendientes',
                            pendientes.toString(),
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailStatCard(
                            'Presupuesto Total',
                            f.format(totalConImpuestos),
                            const Color(0xFF003366),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estructura de Costos y Avance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              if (_proyecto.estado == 'Activo')
                ElevatedButton.icon(
                  onPressed: _showAddPartidaDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('A├▒adir Partida'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA000),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (partidas.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Text('No hay partidas registradas en este proyecto.'),
              ),
            )
          else
            ...partidas.map((p) => _buildPartidaCard(p, f)).toList(),
        ],
      ),
    );
  }

  Widget _buildDetailStatCard(
    String title,
    String value,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Funci├│n para abrir el PDF del gasto
  Future<void> _openGastoPdf(int id) async {
    final url = Uri.parse('$host/api/v1/gastos-proyecto/$id/pdf');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el recibo PDF')),
        );
      }
    }
  }

  Widget _buildTabGastos(NumberFormat f) {
    final double totalGastado = _gastos.fold(0.0, (sum, g) => sum + g.monto);
    final double moGastado = _gastos
        .where((g) => g.tipoGasto.contains('Mano de Obra'))
        .fold(0.0, (sum, g) => sum + g.monto);
    final double alquilerGastado = _gastos
        .where((g) => g.tipoGasto.contains('Alquiler'))
        .fold(0.0, (sum, g) => sum + g.monto);
    final double otrosGastado = totalGastado - moGastado - alquilerGastado;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final bool useGrid = constraints.maxWidth > 700;
              if (useGrid) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildDetailStatCard(
                        'Total Gastado',
                        f.format(totalGastado),
                        Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailStatCard(
                        'Mano de Obra',
                        f.format(moGastado),
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailStatCard(
                        'Alquiler de Equipos',
                        f.format(alquilerGastado),
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailStatCard(
                        'Otros Egresos',
                        f.format(otrosGastado),
                        Colors.cyan,
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailStatCard(
                            'Total Gastado',
                            f.format(totalGastado),
                            Colors.redAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailStatCard(
                            'Mano de Obra',
                            f.format(moGastado),
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailStatCard(
                            'Alquiler',
                            f.format(alquilerGastado),
                            Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailStatCard(
                            'Otros',
                            f.format(otrosGastado),
                            Colors.cyan,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Historial de Gastos (MO / Alquiler / Otros)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (_proyecto.estado == 'Activo')
                ElevatedButton.icon(
                  onPressed: () => _showGastoDialog(context),
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('Registrar Gasto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (_gastos.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Text('No hay gastos registrados en este proyecto.'),
              ),
            )
          else
            ..._gastos.map((g) {
              return GastoCard(gasto: g, onPrint: () => _openGastoPdf(g.id!));
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildTabPagos(NumberFormat f) {
    final totalConImpuestos =
        double.tryParse(
          _proyecto.totalPresupuestoConGlobales?.toString() ?? '0',
        ) ??
        0;
    final totalCobrado = _proyecto.totalCobrado ?? 0;
    final saldoPendiente = totalConImpuestos - totalCobrado;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDetailStatCard(
                  'Monto Total Presupuestado',
                  f.format(totalConImpuestos),
                  const Color(0xFF003366),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailStatCard(
                  'Total Cobrado al Cliente',
                  f.format(totalCobrado),
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailStatCard(
                  'Saldo Pendiente de Cobro',
                  f.format(saldoPendiente),
                  saldoPendiente > 0.01 ? Colors.orange : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Historial de Cobros a Clientes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_pagos.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Text('No hay cobros registrados para este proyecto.'),
              ),
            )
          else
            ..._pagos.map((item) {
              final monto = double.tryParse(item['monto'].toString()) ?? 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade100),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['entidad'] ?? 'Cliente General',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        f.format(monto),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(item['concepto'] ?? 'Abono de Proyecto'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item['fecha'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.payment,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item['metodo_pago'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    onPressed: () => _openPagoPdf(item['id']),
                    tooltip: 'Imprimir Recibo',
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  void _openPagoPdf(int id) async {
    final url = Uri.parse('$host/api/v1/pagos-historial/Cobro/$id/pdf');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el PDF del recibo')),
        );
      }
    }
  }

  Widget _buildTabReportes(NumberFormat f) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informes y Reportes del Proyecto',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Descarga y consulta la informaci├│n financiera y operativa del proyecto.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),

          _buildReportItem(
            'Reporte General del Proyecto (PDF)',
            'Incluye avance f├¡sico consolidado, desglose de presupuestos por partida, gastos acumulados y balance de fondos.',
            Icons.picture_as_pdf,
            Colors.redAccent,
            () async {
              final url = Uri.parse(
                '$host/reports/proyecto/${_proyecto.id}/pdf',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo abrir el reporte PDF'),
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 16),

          _buildReportItem(
            'Estado de Resultados del Proyecto',
            'Informe anal├¡tico de ingresos netos devengados, egresos reales de caja y materiales, y c├ílculo de utilidad/ganancia real.',
            Icons.assessment,
            Colors.green,
            () async {
              try {
                final data = await _accountingService.getEstadoResultados(
                  proyectoId: _proyecto.id,
                );
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Estado de Resultados del Proyecto'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ingresos Totales: ${f.format(double.tryParse(data['ingresos']?.toString() ?? '0') ?? 0)}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Costos Totales: ${f.format(double.tryParse(data['costos']?.toString() ?? '0') ?? 0)}',
                          ),
                          const Divider(height: 24),
                          Text(
                            'Utilidad: ${f.format(double.tryParse(data['utilidad']?.toString() ?? '0') ?? 0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al cargar estado de resultados: $e'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(description),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildTabDocumentos() {
    return ProjectDocumentsScreen(
      proyectoId: _proyecto.id!,
      proyectoNombre: _proyecto.nombre,
      logoPath: _proyecto.logoPath,
      embedded: true,
    );
  }

  Widget _buildGastosSection(NumberFormat f) {
    if (_gastos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historial de Gastos (MO / Alquiler / Otros)',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._gastos.map((g) {
          IconData icon = Icons.payments;
          Color color = Colors.blue;
          if (g.tipoGasto.contains('Mano de Obra')) {
            icon = Icons.engineering;
            color = Colors.orange;
          } else if (g.tipoGasto.contains('Alquiler')) {
            icon = Icons.construction;
            color = Colors.purple;
          } else if (g.tipoGasto.contains('Transporte')) {
            icon = Icons.local_shipping;
            color = Colors.cyan;
          }

          final fechaStr = g.fecha.toIso8601String().split('T')[0];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color),
              ),
              title: Text(
                g.descripcion ?? 'Gasto sin descripci├│n',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "${g.proveedor?.name ?? 'Sin proveedor'} ΓÇó $fechaStr",
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    f.format(g.monto),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.redAccent,
                    ),
                  ),
                  Text(
                    g.metodoPago,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildHeader(NumberFormat f) {
    return Card(
      color: const Color(0xFF003366),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _proyecto.logoPath == null
                        ? const Icon(Icons.add_a_photo, color: Colors.white54)
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  '$host/storage/${_proyecto.logoPath}',
                                  fit: BoxFit.contain,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        );
                                      },
                                  errorBuilder: (context, error, stackTrace) {
                                    print(
                                      ">>> Error al cargar la imagen: $host/storage/${_proyecto.logoPath}",
                                    );
                                    print(">>> Detalle: $error");
                                    return const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.redAccent,
                                      ),
                                    );
                                  },
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: _removeLogo,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _proyecto.nombre ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_note,
                              color: Colors.white70,
                            ),
                            onPressed: _editNotas,
                            tooltip: 'Editar Notas',
                          ),
                        ],
                      ),
                      if (_proyecto.notas != null &&
                          _proyecto.notas.toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _proyecto.notas!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildInfoColumn(
                    'Cliente',
                    _proyecto.cliente ?? 'N/A',
                    Colors.white,
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Ubicaci├│n',
                    _proyecto.ubicacion ?? 'N/A',
                    Colors.white,
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: _cambiarEstado,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Estado',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.sync_alt,
                              size: 12,
                              color: Colors.white54,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getEstadoColor(
                              _proyecto.estado,
                            ).withValues(alpha: 0.2),
                            border: Border.all(
                              color: _getEstadoColor(_proyecto.estado),
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _proyecto.estado ?? '',
                            style: TextStyle(
                              color: _getEstadoColor(_proyecto.estado),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            /* Bot├│n antiguo eliminado para usar _cambiarEstado */
            const SizedBox(height: 8),

            const Divider(color: Colors.white24, height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildInfoColumn(
                    'Presupuesto Total',
                    f.format(
                      double.tryParse(
                            _proyecto.totalPresupuestoConGlobales?.toString() ??
                                '0',
                          ) ??
                          0,
                    ),
                    Colors.greenAccent,
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Avance F├¡sico',
                    '${_proyecto.porcentajeAvanceTotal ?? 0}%',
                    Colors.blueAccent,
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Ejecutado',
                    f.format(
                      double.tryParse(
                            _proyecto.montoEjecutadoTotal?.toString() ?? '0',
                          ) ??
                          0,
                    ),
                    Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndirectsBreakdown(NumberFormat f) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF003366),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DESGLOSE DE COSTOS INDIRECTOS',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildIndirectRow(
            'Supervisi├│n T├⌐cnica',
            _proyecto.supervisionTecnica,
            f,
          ),
          _buildIndirectRow('ITBIS', _proyecto.itbis, f),
          _buildIndirectRow('Transporte', _proyecto.transporte, f),
          _buildIndirectRow('Otros Gastos', _proyecto.otrosCostos, f),
        ],
      ),
    );
  }

  Widget _buildIndirectRow(String label, dynamic value, NumberFormat f) {
    final val = double.tryParse(value?.toString() ?? '0') ?? 0;
    if (val == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            f.format(val),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitabilityCard(NumberFormat f) {
    final ingresoNeto = _proyecto.ingresoNetoReal ?? 0;

    final double gastosEfectivo = _gastos.fold(0, (sum, g) => sum + g.monto);
    final double costosMateriales = _consumos.fold(
      0,
      (sum, c) => sum + c.total,
    );
    final costoReal = gastosEfectivo + costosMateriales;

    final ganancia = ingresoNeto - costoReal;
    final margen = ingresoNeto > 0 ? (ganancia / ingresoNeto) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF003366),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'AN├üLISIS DE RENTABILIDAD (GANANCIA REAL)',
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSimpleStat(
                'Ingreso Neto (Sin ITBIS)',
                f.format(ingresoNeto),
              ),
              const Text('-', style: TextStyle(color: Colors.white38)),
              _buildSimpleStat(
                'Costos Reales (Gastos + Mat.)',
                f.format(costoReal),
                valueColor: Colors.redAccent,
              ),
            ],
          ),
          const Divider(height: 32, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Utilidad Neta:',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    'Margen: ${margen.toStringAsFixed(1)}%',
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
              Text(
                f.format(ganancia),
                style: TextStyle(
                  color: ganancia >= 0 ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowCard(NumberFormat f) {
    final cobrado = _proyecto.totalCobrado ?? 0;
    final ejecutado = _proyecto.montoEjecutadoTotal ?? 0;
    final balance = cobrado - ejecutado;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF003366),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'BALANCE DE FONDOS VS EJECUCI├ôN',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFlowItem('Cobrado al Cliente', cobrado, Colors.greenAccent),
              const Icon(Icons.compare_arrows, color: Colors.white24),
              _buildFlowItem('Valor Construido', ejecutado, Colors.blueAccent),
            ],
          ),
          const Divider(color: Colors.white12, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Balance en Manos:',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                f.format(balance),
                style: TextStyle(
                  color: balance >= 0 ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          if (balance < 0)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'ΓÜá∩╕Å Est├ís ejecutando m├ís de lo cobrado',
                style: TextStyle(color: Colors.redAccent, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(
    String label,
    String value, {
    Color valueColor = Colors.white,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFlowItem(String label, double value, Color color) {
    final f = NumberFormat.currency(symbol: '\$');
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60, fontSize: 10),
          ),
          Text(
            f.format(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getEstadoColor(String? estado) {
    switch (estado) {
      case 'Cotizaci├│n':
        return Colors.orange;
      case 'Activo':
        return Colors.greenAccent;
      case 'Terminado':
        return Colors.blueAccent;
      case 'Cancelado':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoColumn(
    String label,
    String value,
    Color valueColor, {
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 12, color: Colors.white54),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPartidaCard(Partida partida, NumberFormat f) {
    final subpartidas = partida.subpartidas;
    final subpartidasIds = subpartidas.map((s) => s.id).toList();

    // Calcular el total de la partida sumando sus subpartidas
    final double totalPartida = partida.totalPresupuestado;

    // Calcular el costo real para esta partida (Gastos directos + Consumo de materiales)
    final double gastosPartida = _gastos
        .where(
          (g) =>
              g.subpartidaId != null && subpartidasIds.contains(g.subpartidaId),
        )
        .fold(0.0, (sum, g) => sum + g.monto);

    final double consumosPartida = _consumos
        .where(
          (c) =>
              c.subpartidaId != null && subpartidasIds.contains(c.subpartidaId),
        )
        .fold(0.0, (sum, c) => sum + c.total);

    final double costoRealPartida = gastosPartida + consumosPartida;

    // Verificar si todas las subpartidas est├ín al 100%
    final bool allCompleted =
        subpartidas.isNotEmpty &&
        subpartidas.every((s) => s.avanceActual >= 100);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: allCompleted ? 4 : 1, // M├ís sombra si est├í completado
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: allCompleted ? Colors.green.shade300 : Colors.transparent,
          width: 2,
        ),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: allCompleted
              ? Colors.green
              : const Color(0xFF003366),
          child: Icon(
            allCompleted ? Icons.check : Icons.construction,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    partida.descripcion,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: allCompleted
                          ? Colors.green.shade700
                          : const Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (totalPartida > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (costoRealPartida / totalPartida) > 1
                            ? const Color(0xFFFFF3E0) // Orange 50
                            : const Color(0xFFE0F2F1), // Teal 50
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: (costoRealPartida / totalPartida) > 1
                              ? const Color(0xFFFFB74D) // Orange 300
                              : const Color(0xFF4DB6AC), // Teal 300
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${(costoRealPartida / totalPartida * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: (costoRealPartida / totalPartida) > 1
                              ? const Color(0xFFE65100) // Orange 900
                              : const Color(0xFF00695C), // Teal 800
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        f.format(totalPartida),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF2E7D32), // Green darken-3
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(
                          Icons.print_outlined,
                          size: 20,
                          color: Color(0xFF003366),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          final url = Uri.parse(
                            '$host/reports/partida/${partida.id}/pdf',
                          );
                          if (await canLaunchUrl(url)) await launchUrl(url);
                        },
                      ),
                    ],
                  ),
                  if (costoRealPartida > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      f.format(costoRealPartida),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFFC62828), // Red darken-3
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (totalPartida - costoRealPartida) >= 0
                            ? const Color(0xFFE3F2FD) // Light blue background
                            : const Color(
                                0xFFFFF3E0,
                              ), // Light orange background
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Dif: ${f.format(totalPartida - costoRealPartida)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: (totalPartida - costoRealPartida) >= 0
                              ? const Color(0xFF1565C0) // Blue darken-3
                              : const Color(0xFFE65100), // Orange darken-4
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        subtitle: allCompleted
            ? Row(
                children: [
                  const Icon(Icons.stars, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'PARTIDA COMPLETADA AL 100%',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : Text('Partida con ${subpartidas.length} Sub-Partidas'),
        children: [
          ...subpartidas.map((s) => _buildSubpartidaTile(s, f)).toList(),
          if (_proyecto.estado == 'Activo')
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
              title: const Text(
                'A├▒adir Sub-partida',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => _showAddSubpartidaDialog(partida.id!),
            ),
        ],
      ),
    );
  }

  Widget _buildSubpartidaTile(Subpartida sub, NumberFormat f) {
    final avance = sub.avanceActual;
    return ListTile(
      title: Text(sub.descripcion),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Presupuesto: ${f.format(sub.totalPresupuestado)} (${sub.unidad})',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: avance / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    avance == 100 ? Colors.green : Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${avance.toInt()}%',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: avance >= 100
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'COMPLETADO',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            )
          : (_proyecto.estado == 'Activo'
                ? ElevatedButton(
                    onPressed: () => _showAvanceDialog(sub),
                    child: const Text('Registrar Avance'),
                  )
                : const SizedBox.shrink()),
    );
  }

  void _showAvanceDialog(Subpartida sub) {
    final initialValue = (sub.avanceActual + 5.0 <= 100)
        ? sub.avanceActual + 5.0
        : 100.0;
    final controller = TextEditingController(text: initialValue.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Registrar Avance: ${sub.descripcion}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa el nuevo porcentaje de avance f├¡sico (%):'),
            DropdownButtonFormField<double>(
              value: initialValue,
              decoration: const InputDecoration(
                labelText: 'Nuevo Porcentaje Total (%)',
                border: OutlineInputBorder(),
              ),
              items:
                  [
                        ...[
                          for (
                            double v = sub.avanceActual + 5.0;
                            v < 100;
                            v += 5.0
                          )
                            v,
                        ],
                        100.0,
                      ]
                      .toSet() // Eliminar duplicados si 100 ya estaba
                      .map(
                        (val) => DropdownMenuItem(
                          value: val,
                          child: Text('${val.toInt()}%'),
                        ),
                      )
                      .toList(),
              onChanged: (v) => controller.text = (v ?? 0).toString(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final porc = double.tryParse(controller.text) ?? 0;
                final total = sub.totalPresupuestado;
                await _projectService.createAvance(
                  AvanceProyecto(
                    partidaId: sub.partidaId,
                    subpartidaId: sub.id!,
                    fecha: DateTime.now(),
                    porcentaje: porc,
                    valorEjecutado: (porc / 100) * total,
                  ),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Avance registrado correctamente'),
                  ),
                );
                _refresh(notifyParent: true);
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showGastoDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => GastoProyectoDialog(proyecto: _proyecto),
    );
    if (result == true) {
      _refresh(notifyParent: true);
    }
  }

  void _showPagoDialog() {
    final totalConImpuestos = _proyecto.totalPresupuestoConGlobales ?? 0;
    final cobrado = _proyecto.totalCobrado ?? 0;
    final saldoPendiente = totalConImpuestos - cobrado;

    final controller = TextEditingController(
      text: saldoPendiente.toStringAsFixed(2),
    );
    final f = NumberFormat.currency(symbol: '\$');
    String metodoPago = 'Transferencia';
    int? bancoId;
    List<dynamic> bancos = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (bancos.isEmpty) {
            _accountingService.getBancos().then((value) {
              setDialogState(() {
                bancos = value;
                if (bancos.isNotEmpty) {
                  // Buscar el primer banco real para que sea el default
                  final primerBanco = bancos.firstWhere(
                    (b) => b['nombre'].toString().contains('Banco'),
                    orElse: () => bancos[0],
                  );
                  bancoId = primerBanco['id'];
                }
              });
            });
          }

          return AlertDialog(
            title: const Text('Registrar Pago del Cliente'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Proyecto: ${f.format(totalConImpuestos)}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Ya Cobrado: ${f.format(cobrado)}',
                  style: const TextStyle(fontSize: 12),
                ),
                const Divider(),
                Text(
                  'SALDO PENDIENTE: ${f.format(saldoPendiente)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Monto a Cobrar',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: metodoPago,
                  decoration: const InputDecoration(
                    labelText: 'M├⌐todo de Pago',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Transferencia', 'Cheque']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) {
                    setDialogState(() {
                      metodoPago = v!;
                      // Siempre buscar una cuenta que sea Banco
                      final banco = bancos.firstWhere(
                        (b) => b['nombre'].toString().contains('Banco'),
                        orElse: () => null,
                      );
                      if (banco != null) bancoId = banco['id'];
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (bancos.isNotEmpty)
                  DropdownButtonFormField<int>(
                    value: bancoId,
                    decoration: const InputDecoration(
                      labelText: 'Cuenta de Destino (Banco)',
                      border: OutlineInputBorder(),
                    ),
                    items: bancos
                        .where((b) => b['nombre'].toString().contains('Banco'))
                        .map(
                          (b) => DropdownMenuItem<int>(
                            value: b['id'],
                            child: Text(b['nombre']),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialogState(() => bancoId = v),
                  )
                else
                  const Center(child: LinearProgressIndicator()),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final monto = double.tryParse(controller.text) ?? 0;
                    if (monto <= 0) throw 'Monto inv├ílido';
                    if (monto > (saldoPendiente + 0.01)) {
                      throw 'El monto no puede exceder el saldo pendiente (${f.format(saldoPendiente)})';
                    }

                    await _accountingService.createPago({
                      'proyecto_id': _proyecto.id,
                      'monto': monto,
                      'metodo_pago': metodoPago,
                      'banco_id': bancoId,
                      'fecha': DateTime.now().toIso8601String(),
                      'glosa':
                          'Pago de cliente - Proyecto: ${_proyecto.nombre}',
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('┬íPago registrado con ├⌐xito!'),
                      ),
                    );
                    _refresh(notifyParent: true);
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Guardar Pago'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddPartidaDialog() {
    final descripcionController = TextEditingController();
    final subDescripcionController = TextEditingController();
    final subCantidadController = TextEditingController(text: '1');
    final subCostoController = TextEditingController(text: '0');
    final subUnidadController = TextEditingController(text: 'GL');
    bool isSaving = false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('A├▒adir Partida (Adendum)'),
            content: SizedBox(
              width: 500,
              child: isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Datos de la Partida',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: descripcionController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre de Partida',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Primera Sub-partida',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: subDescripcionController,
                              decoration: const InputDecoration(
                                labelText: 'Descripci├│n Sub-partida',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: subUnidadController,
                                    decoration: const InputDecoration(
                                      labelText: 'Unidad',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (v) =>
                                        v!.isEmpty ? 'Req.' : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: subCantidadController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,2}'),
                                      ),
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Cant.',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: subCostoController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,2}'),
                                      ),
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Costo Unit.',
                                      border: OutlineInputBorder(),
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
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSaving = true);
                        try {
                          await _projectService.addPartida(_proyecto.id!, {
                            'descripcion': descripcionController.text,
                            'subpartidas': [
                              {
                                'descripcion': subDescripcionController.text,
                                'unidad': subUnidadController.text,
                                'cantidad':
                                    double.tryParse(
                                      subCantidadController.text,
                                    ) ??
                                    1,
                                'costo_unitario':
                                    double.tryParse(subCostoController.text) ??
                                    0,
                              },
                            ],
                          });
                          Navigator.pop(context);
                          _refresh(notifyParent: true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Partida a├▒adida exitosamente'),
                            ),
                          );
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                child: const Text('A├▒adir Partida'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddSubpartidaDialog(int partidaId) {
    final subDescripcionController = TextEditingController();
    final subCantidadController = TextEditingController(text: '1');
    final subCostoController = TextEditingController(text: '0');
    final subUnidadController = TextEditingController(text: 'GL');
    bool isSaving = false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('A├▒adir Sub-partida'),
            content: SizedBox(
              width: 500,
              child: isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: subDescripcionController,
                              decoration: const InputDecoration(
                                labelText: 'Descripci├│n Sub-partida',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: subUnidadController,
                                    decoration: const InputDecoration(
                                      labelText: 'Unidad',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (v) =>
                                        v!.isEmpty ? 'Req.' : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: subCantidadController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,2}'),
                                      ),
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Cant.',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: subCostoController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,2}'),
                                      ),
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Costo Unit.',
                                      border: OutlineInputBorder(),
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
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSaving = true);
                        try {
                          await _projectService.addSubpartida(partidaId, {
                            'descripcion': subDescripcionController.text,
                            'unidad': subUnidadController.text,
                            'cantidad':
                                double.tryParse(subCantidadController.text) ??
                                1,
                            'costo_unitario':
                                double.tryParse(subCostoController.text) ?? 0,
                          });
                          Navigator.pop(context);
                          _refresh(notifyParent: true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sub-partida a├▒adida exitosamente'),
                            ),
                          );
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                child: const Text('A├▒adir Sub-partida'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ProjectProfitLossView extends StatefulWidget {
  final Proyecto proyecto;
  final List<GastoProyecto> gastos;
  final List<ConsumoProyecto> consumos;

  const ProjectProfitLossView({
    super.key,
    required this.proyecto,
    required this.gastos,
    required this.consumos,
  });

  @override
  State<ProjectProfitLossView> createState() => _ProjectProfitLossViewState();
}

class _ProjectProfitLossViewState extends State<ProjectProfitLossView> {
  final AccountingService _accountingService = AccountingService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant ProjectProfitLossView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.proyecto.id != oldWidget.proyecto.id ||
        widget.gastos != oldWidget.gastos ||
        widget.consumos != oldWidget.consumos) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _accountingService.getEstadoResultados(
        proyectoId: widget.proyecto.id,
      );
      if (mounted) {
        setState(() {
          _data = data;
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

  String _formatCurrency(dynamic value, {bool isNegative = false}) {
    final val = double.tryParse(value?.toString() ?? '0') ?? 0;
    final f = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);
    final isZero = val.abs() < 0.005;

    if (isZero) {
      return f.format(0.0);
    } else if (isNegative && val > 0) {
      return "(${f.format(val)})";
    } else if (val < 0) {
      return "(${f.format(val.abs())})";
    } else {
      return f.format(val);
    }
  }

  String _formatPeriod(Proyecto p) {
    if (p.fechaInicio != null && p.fechaFin != null) {
      final f = DateFormat('dd/MM/yyyy');
      return "${f.format(p.fechaInicio!)} - ${f.format(p.fechaFin!)}";
    }
    final now = DateTime.now();
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return "${months[now.month - 1]} ${now.year}";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error al cargar el estado de resultados:\n$_errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 950;
        return Column(
          children: [
            if (_isLoading) const LinearProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Row with title, period and refresh button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ESTADO DE RESULTADOS',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1C1E),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Per├¡odo: ${_formatPeriod(widget.proyecto)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.blueGrey,
                          ),
                          onPressed: _loadData,
                          tooltip: 'Actualizar Estado de Resultados',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 1. Tarjetas Resumen en la Parte Superior
                    _buildSummaryCards(),
                    const SizedBox(height: 16),

                    // Main layout body (Responsive two-column or single column)
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              children: [
                                _buildContractInfoCard(),
                                const SizedBox(height: 16),
                                _buildPresupuestoVsRealCard(),
                                const SizedBox(height: 16),
                                _buildManagementIndicatorsCard(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                _buildReportCard(),
                                const SizedBox(height: 16),
                                _buildExecutiveChartCard(),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildContractInfoCard(),
                          const SizedBox(height: 16),
                          _buildPresupuestoVsRealCard(),
                          const SizedBox(height: 16),
                          _buildManagementIndicatorsCard(),
                          const SizedBox(height: 16),
                          _buildReportCard(),
                          const SizedBox(height: 16),
                          _buildExecutiveChartCard(),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 1. summary metrics cards
  Widget _buildSummaryCards() {
    if (_data == null) return const SizedBox.shrink();

    final ingresos =
        double.tryParse(_data!['ingresos']?.toString() ?? '0') ?? 0;
    final costos = double.tryParse(_data!['costos']?.toString() ?? '0') ?? 0;
    final utilidadBruta =
        double.tryParse(_data!['utilidad_bruta']?.toString() ?? '0') ?? 0;
    final utilidadNeta =
        double.tryParse(_data!['utilidad_neta']?.toString() ?? '0') ?? 0;
    final margen = ingresos > 0 ? (utilidadNeta / ingresos * 100) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        // Adjust column count based on available space
        final int crossAxisCount = width > 800 ? 5 : (width > 500 ? 3 : 2);
        final double childAspectRatio = width > 800 ? 1.4 : 1.6;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: childAspectRatio,
          children: [
            _buildMetricCard(
              'Ingresos Totales',
              _formatCurrency(ingresos),
              Colors.green[700]!,
              Icons.trending_up,
            ),
            _buildMetricCard(
              'Costos Totales',
              _formatCurrency(costos),
              Colors.red[700]!,
              Icons.trending_down,
            ),
            _buildMetricCard(
              'Utilidad Bruta',
              _formatCurrency(utilidadBruta),
              Colors.blue[700]!,
              Icons.account_balance_wallet,
            ),
            _buildMetricCard(
              'Utilidad Neta',
              _formatCurrency(utilidadNeta),
              utilidadNeta >= 0 ? Colors.green[800]! : Colors.red[800]!,
              Icons.monetization_on,
              subtitle: 'Margen: ${margen.toStringAsFixed(2)}%',
            ),
            _buildMetricCard(
              'Margen Neto',
              '${margen.toStringAsFixed(2)}%',
              Colors.teal[700]!,
              Icons.percent,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    Color color,
    IconData icon, {
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(icon, color: color.withOpacity(0.8), size: 16),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else
              const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  // 3. Contract Information and Financial Progress
  Widget _buildContractInfoCard() {
    final contrato =
        widget.proyecto.totalPresupuestoConGlobales ??
        widget.proyecto.presupuestoEstimado;
    final facturado =
        double.tryParse(_data?['ingresos']?.toString() ?? '0') ?? 0;
    final cobrado = widget.proyecto.totalCobrado ?? 0;
    final pendiente = facturado - cobrado;
    final avanceFinanciero = contrato > 0 ? (facturado / contrato * 100) : 0.0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informaci├│n del Contrato y Cobros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2F33),
              ),
            ),
            const Divider(height: 24),
            _buildContractRow(
              'Monto del Contrato',
              _formatCurrency(contrato),
              Colors.black87,
            ),
            _buildContractRow(
              'Monto Facturado (Ingresos)',
              _formatCurrency(facturado),
              Colors.blue[800]!,
            ),
            _buildContractRow(
              'Monto Cobrado (Efectivo)',
              _formatCurrency(cobrado),
              Colors.green[700]!,
            ),
            _buildContractRow(
              'Balance Pendiente de Cobro',
              _formatCurrency(pendiente),
              pendiente >= 0 ? Colors.orange[800]! : Colors.red,
              isBold: true,
            ),
            const SizedBox(height: 20),
            // 4. Financial Progress indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Avance Financiero (Facturado / Contrato)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${avanceFinanciero.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (avanceFinanciero / 100).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractRow(
    String label,
    String value,
    Color valueColor, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey[800],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // 5. Comparaci├│n Presupuesto vs Real
  Widget _buildPresupuestoVsRealCard() {
    double moPresupuesto = 0.0;
    double equiposPresupuesto = 0.0;
    double materialesPresupuesto = 0.0;

    for (var partida in widget.proyecto.partidas) {
      for (var sub in partida.subpartidas) {
        final desc = sub.descripcion.toLowerCase();
        if (desc.contains('mano de obra') ||
            desc.contains('mo ') ||
            desc.contains(' mo') ||
            desc.contains('jornal') ||
            desc.contains('alba├▒il') ||
            desc.contains('pintor') ||
            desc.contains('personal') ||
            desc.contains('labor')) {
          moPresupuesto += sub.totalPresupuestado;
        } else if (desc.contains('alquiler') ||
            desc.contains('equipo') ||
            desc.contains('herramienta') ||
            desc.contains('maquinaria') ||
            desc.contains('mezcladora') ||
            desc.contains('andamio')) {
          equiposPresupuesto += sub.totalPresupuestado;
        } else {
          materialesPresupuesto += sub.totalPresupuestado;
        }
      }
    }

    final double moReal = widget.gastos
        .where((g) => g.tipoGasto.toLowerCase().contains('mano de obra'))
        .fold(0.0, (sum, g) => sum + g.monto);
    final double equiposReal = widget.gastos
        .where(
          (g) =>
              g.tipoGasto.toLowerCase().contains('alquiler') ||
              g.tipoGasto.toLowerCase().contains('equipo'),
        )
        .fold(0.0, (sum, g) => sum + g.monto);
    final double materialesReal = widget.consumos.fold(
      0.0,
      (sum, c) => sum + c.total,
    );

    final double totalPresupuesto =
        moPresupuesto + equiposPresupuesto + materialesPresupuesto;
    final double totalReal = moReal + equiposReal + materialesReal;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparativa Presupuesto vs Real (Costo Directo)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2F33),
              ),
            ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(2),
              },
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              children: [
                TableRow(
                  children: [
                    _buildTableHeaderCell('Concepto'),
                    _buildTableHeaderCell('Presupuesto'),
                    _buildTableHeaderCell('Real'),
                    _buildTableHeaderCell('Diferencia'),
                  ],
                ),
                _buildTableRow(
                  'Materiales',
                  materialesPresupuesto,
                  materialesReal,
                ),
                _buildTableRow('Mano de Obra', moPresupuesto, moReal),
                _buildTableRow(
                  'Equipos y Herramientas',
                  equiposPresupuesto,
                  equiposReal,
                ),
                _buildTableRow(
                  'Total Directo',
                  totalPresupuesto,
                  totalReal,
                  isTotal: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  TableRow _buildTableRow(
    String concepto,
    double presupuesto,
    double real, {
    bool isTotal = false,
  }) {
    final dif = presupuesto - real;
    final isOverrun = dif < 0; // Negative means overrun (Real > Presupuesto)
    final textStyle = TextStyle(
      fontSize: 12,
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      color: isTotal ? const Color(0xFF1A1C1E) : Colors.black87,
    );

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(concepto, style: textStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(_formatCurrency(presupuesto), style: textStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(_formatCurrency(real), style: textStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            _formatCurrency(dif, isNegative: isOverrun),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isZero(dif)
                  ? Colors.black87
                  : (isOverrun ? Colors.red[700] : Colors.green[700]),
            ),
          ),
        ),
      ],
    );
  }

  bool isZero(double value) {
    return value.abs() < 0.005;
  }

  // 9. Agregar Indicadores de Gesti├│n
  Widget _buildManagementIndicatorsCard() {
    if (_data == null) return const SizedBox.shrink();

    final ingresos =
        double.tryParse(_data!['ingresos']?.toString() ?? '0') ?? 0;
    final utilidadBruta =
        double.tryParse(_data!['utilidad_bruta']?.toString() ?? '0') ?? 0;
    final utilidadNeta =
        double.tryParse(_data!['utilidad_neta']?.toString() ?? '0') ?? 0;
    final contrato =
        widget.proyecto.totalPresupuestoConGlobales ??
        widget.proyecto.presupuestoEstimado;

    final double moReal = widget.gastos
        .where((g) => g.tipoGasto.toLowerCase().contains('mano de obra'))
        .fold(0.0, (sum, g) => sum + g.monto);
    final double equiposReal = widget.gastos
        .where(
          (g) =>
              g.tipoGasto.toLowerCase().contains('alquiler') ||
              g.tipoGasto.toLowerCase().contains('equipo'),
        )
        .fold(0.0, (sum, g) => sum + g.monto);
    final double materialesReal = widget.consumos.fold(
      0.0,
      (sum, c) => sum + c.total,
    );
    final totalReal = moReal + equiposReal + materialesReal;

    final margenBruto = ingresos > 0 ? (utilidadBruta / ingresos * 100) : 0.0;
    final margenNeto = ingresos > 0 ? (utilidadNeta / ingresos * 100) : 0.0;
    final cobrado = widget.proyecto.totalCobrado ?? 0;
    final cuentasPorCobrar = ingresos - cobrado;
    final costoRealVsPresupuesto = contrato > 0
        ? (totalReal / contrato * 100)
        : 0.0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Indicadores Financieros y Gesti├│n',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2F33),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildIndicatorBadge(
                  'Margen Bruto',
                  '${margenBruto.toStringAsFixed(1)}%',
                  Colors.blue,
                ),
                _buildIndicatorBadge(
                  'Margen Neto',
                  '${margenNeto.toStringAsFixed(1)}%',
                  margenNeto >= 0 ? Colors.green : Colors.red,
                ),
                _buildIndicatorBadge(
                  'Cuentas por Cobrar',
                  _formatCurrency(cuentasPorCobrar),
                  Colors.orange,
                ),
                _buildIndicatorBadge(
                  'Costo Real vs Presupuesto',
                  '${costoRealVsPresupuesto.toStringAsFixed(1)}%',
                  costoRealVsPresupuesto <= 100 ? Colors.teal : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // 8. Gr├ífico Ejecutivo
  Widget _buildExecutiveChartCard() {
    if (_data == null) return const SizedBox.shrink();

    final ingresos =
        double.tryParse(_data!['ingresos']?.toString() ?? '0') ?? 0;
    final costos = double.tryParse(_data!['costos']?.toString() ?? '0') ?? 0;
    final utilidadNeta =
        double.tryParse(_data!['utilidad_neta']?.toString() ?? '0') ?? 0;

    final maxVal = [
      ingresos,
      costos,
      utilidadNeta.abs(),
    ].reduce((curr, next) => curr > next ? curr : next);
    final double maxBarHeight = 110.0;

    double hIngresos = maxVal > 0 ? (ingresos / maxVal * maxBarHeight) : 0.0;
    double hCostos = maxVal > 0 ? (costos / maxVal * maxBarHeight) : 0.0;
    double hUtilidad = maxVal > 0
        ? (utilidadNeta.abs() / maxVal * maxBarHeight)
        : 0.0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gr├ífico Ejecutivo de Flujo (Ingresos vs Costos vs Utilidad)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2F33),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBarCol(
                  'Ingresos',
                  hIngresos,
                  _formatCurrency(ingresos),
                  Colors.green,
                ),
                _buildBarCol(
                  'Costos',
                  hCostos,
                  _formatCurrency(costos),
                  Colors.red,
                ),
                _buildBarCol(
                  utilidadNeta >= 0 ? 'Utilidad Neta' : 'P├⌐rdida Neta',
                  hUtilidad,
                  _formatCurrency(utilidadNeta),
                  utilidadNeta >= 0 ? Colors.blue : Colors.red[900]!,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildBarCol(
    String label,
    double height,
    String valueText,
    Color color,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          valueText,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 32,
          height: height.clamp(4.0, 110.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard() {
    if (_data == null)
      return const Center(child: Text('No hay datos disponibles'));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Text(
                    'ESTADO DE RESULTADOS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PROYECTO ESPEC├ìFICO',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fecha del reporte: ${_data!['fecha_reporte']}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const Divider(height: 30, thickness: 1.5),
                ],
              ),
            ),
            _buildSectionTitle('INGRESOS OPERACIONALES'),
            _buildLine(
              'Ingresos por Proyectos / Construcci├│n',
              _data!['ingresos'],
              isSub: true,
            ),
            const SizedBox(height: 12),
            _buildTotalLine('TOTAL INGRESOS', _data!['ingresos']),

            const SizedBox(height: 24),
            _buildSectionTitle('COSTOS DE VENTAS'),
            _buildLine(
              'Costos de Construcci├│n (Materiales y MO)',
              _data!['costos'],
              isSub: true,
            ),
            const SizedBox(height: 12),
            _buildTotalLine('TOTAL COSTOS', _data!['costos'], isNegative: true),

            const Divider(height: 30, thickness: 1.5, color: Colors.black12),
            _buildTotalLine(
              'UTILIDAD BRUTA',
              _data!['utilidad_bruta'],
              isBold: true,
              color: Colors.blue[900],
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('GASTOS OPERATIVOS'),
            _buildLine(
              'Gastos Administrativos y Otros',
              _data!['gastos'],
              isSub: true,
            ),
            const SizedBox(height: 12),
            _buildTotalLine('TOTAL GASTOS', _data!['gastos'], isNegative: true),

            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'UTILIDAD NETA DEL PERIODO',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    _formatCurrency(_data!['utilidad_neta']),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _data!['utilidad_neta'] >= 0
                          ? Colors.green[700]
                          : Colors.red,
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildLine(String label, dynamic value, {bool isSub = false}) {
    final val = double.tryParse(value?.toString() ?? '0') ?? 0;
    return Padding(
      padding: EdgeInsets.only(left: isSub ? 16 : 0, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[800], fontSize: 12),
            ),
          ),
          Text(_formatCurrency(val), style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTotalLine(
    String label,
    dynamic value, {
    bool isNegative = false,
    bool isBold = false,
    Color? color,
  }) {
    final val = double.tryParse(value?.toString() ?? '0') ?? 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
        Text(
          _formatCurrency(val, isNegative: isNegative),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }
}

class ProjectPurchasesView extends StatefulWidget {
  final Proyecto proyecto;
  const ProjectPurchasesView({super.key, required this.proyecto});

  @override
  State<ProjectPurchasesView> createState() => _ProjectPurchasesViewState();
}

class _ProjectPurchasesViewState extends State<ProjectPurchasesView> {
  final PurchaseService _purchaseService = PurchaseService();
  bool _isLoading = true;
  List<Compra> _compras = [];
  String? _errorMessage;

  double _totalSubtotal = 0;
  double _totalItbis = 0;
  double _totalGeneral = 0;

  @override
  void initState() {
    super.initState();
    _loadCompras();
  }

  @override
  void didUpdateWidget(covariant ProjectPurchasesView oldWidget) {
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
        100, // Load up to 100 purchases
      );
      final List<dynamic> data = response['data'] ?? [];

      if (mounted) {
        setState(() {
          _compras = data.map((json) => Compra.fromJson(json)).toList();
          if (response['summary'] != null) {
            final summary = response['summary'];
            _totalSubtotal =
                double.tryParse(summary['subtotal']?.toString() ?? '0') ?? 0.0;
            _totalItbis =
                double.tryParse(summary['itbis']?.toString() ?? '0') ?? 0.0;
            _totalGeneral =
                double.tryParse(summary['total']?.toString() ?? '0') ?? 0.0;
          }
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary header cards
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Compras',
                  f.format(_totalGeneral),
                  Colors.blue[700]!,
                  Icons.shopping_bag,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Subtotal',
                  f.format(_totalSubtotal),
                  Colors.grey[700]!,
                  Icons.receipt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Total ITBIS',
                  f.format(_totalItbis),
                  Colors.orange[700]!,
                  Icons.percent,
                ),
              ),
            ],
          ),
        ),

        // List of purchases
        Expanded(
          child: _compras.isEmpty
              ? const Center(
                  child: Text(
                    'No hay compras registradas en este proyecto.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _compras.length,
                  itemBuilder: (context, index) {
                    final c = _compras[index];
                    final double total = c.total;
                    final double subtotal = c.subtotal;
                    final double itbis = total - subtotal;
                    final isRecibido = c.estado == 'Recibido';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade100),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              (isRecibido ? Colors.green : Colors.orange)
                                  .withOpacity(0.1),
                          child: Icon(
                            isRecibido
                                ? Icons.check_circle
                                : Icons.hourglass_empty,
                            color: isRecibido ? Colors.green : Colors.orange,
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              c.proveedor?.name ?? 'Proveedor Desconocido',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              f.format(total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF1A1C1E),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey[50],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'ID: #${c.id} ΓÇó ${c.tipoCompra}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blueGrey[750],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    c.fecha.split('T')[0],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Subtotal: ${f.format(subtotal)} ΓÇó ITBIS: ${f.format(itbis)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (c.comprobante != null &&
                                      c.comprobante!.isNotEmpty) ...[
                                    const Text(' ΓÇó '),
                                    Text(
                                      'NCF: ${c.comprobante}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            final url = Uri.parse(
                              '$host/compras/${c.id}/print',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No se pudo abrir el recibo de compra',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          tooltip: 'Imprimir Factura',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
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
