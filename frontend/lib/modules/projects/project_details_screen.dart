import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/proyecto.dart';
import '../../../services/project_service.dart';
import 'providers/project_details_provider.dart';

import 'widgets/tabs/project_summary_tab.dart';
import 'widgets/tabs/project_partidas_tab.dart';
import 'widgets/tabs/project_gastos_tab.dart';
import 'widgets/tabs/project_pagos_tab.dart';
import 'widgets/tabs/project_reportes_tab.dart';
import 'widgets/dialogs/add_partida_dialog.dart';
import 'widgets/dialogs/add_subpartida_dialog.dart';

import 'project_documents_screen.dart';
import 'widgets/tabs/project_profit_loss_tab.dart';
import 'widgets/tabs/project_purchases_tab.dart';
import '../../../core/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Proyecto?
  proyecto; // If null, means creating new (though this screen is usually for details)
  final int? proyectoId; // Accept ID to fetch fresh data
  final bool embedded; // whether this screen is inside a larger layout
  final VoidCallback? onRefresh; // Callback to notify parent of changes

  const ProjectDetailsScreen({
    super.key,
    this.proyecto,
    this.proyectoId,
    this.embedded = false,
    this.onRefresh,
  });

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  late ProjectDetailsProvider _provider;
  int _activeTabIndex = 0;
  bool _isInitializing = true;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _provider = ProjectDetailsProvider();
    _initProject();
  }

  Future<void> _initProject() async {
    try {
      Proyecto? initialProj = widget.proyecto;

      if (initialProj == null && widget.proyectoId != null) {
        final projectService = ProjectService();
        initialProj = await projectService.getProyecto(widget.proyectoId!);
      }

      if (initialProj != null) {
        _provider.init(initialProj, onRefresh: widget.onRefresh);
      } else {
        setState(() {
          _initError = "No se pudo cargar el proyecto.";
        });
      }
    } catch (e) {
      setState(() {
        _initError = "Error de inicialización: $e";
      });
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  void _showAddPartidaDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: _provider,
        child: const AddPartidaDialog(),
      ),
    );
    if (result == true) {
      _provider.refresh();
    }
  }

  void _showAddSubpartidaDialog(int partidaId) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: _provider,
        child: AddSubpartidaDialog(partidaId: partidaId),
      ),
    );
    if (result == true) {
      _provider.refresh();
    }
  }

  void _confirmarProvision() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Provisionar todo al 100%?'),
        content: const Text(
          'Esta acción marcará todas las sub-partidas como completadas al 100% para fines de prueba y reporte. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _provider
                  .provisionarTodo100()
                  .then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Provisionado correctamente'),
                      ),
                    );
                  })
                  .catchError((e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('SÍ, PROVISIONAR TODO'),
          ),
        ],
      ),
    );
  }

  bool get _isReadonly {
    if (_provider.proyecto == null) return true;
    return _provider.proyecto!.estado == 'Terminado' ||
        _provider.proyecto!.estado == 'Cancelado';
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(_initError!)),
      );
    }

    return ChangeNotifierProvider<ProjectDetailsProvider>.value(
      value: _provider,
      child: Consumer<ProjectDetailsProvider>(
        builder: (context, provider, child) {
          if (provider.proyecto == null) {
            return const Scaffold(
              body: Center(child: Text('Proyecto no encontrado.')),
            );
          }

          final proyecto = provider.proyecto!;

          return Scaffold(
            appBar: AppBar(
              title: Text(proyecto.nombre),
              automaticallyImplyLeading: !widget.embedded,
              actions: [
                IconButton(
                  onPressed: () async {
                    final url = Uri.parse(
                      '$host/reports/proyecto/${proyecto.id}/pdf',
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
            body: provider.isLoading && provider.proyecto == null
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
                              child: Stack(
                                children: [
                                  _buildActiveTabContent(provider),
                                  if (provider.isLoading &&
                                      provider.proyecto != null)
                                    const Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      child: LinearProgressIndicator(),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsSidebar(bool isNarrow) {
    final accentColor = const Color(0xFFE31E24);
    final primaryColor = const Color(0xFF1A1C1E);
    final secondaryColor = const Color(0xFF2C2F33);

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
                ? Colors.white.withValues(alpha: 0.15)
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
                          color: accentColor.withValues(alpha: 0.5),
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

  Widget _buildActiveTabContent(ProjectDetailsProvider provider) {
    switch (_activeTabIndex) {
      case 0:
        return const ProjectSummaryTab();
      case 1:
        return ProjectPartidasTab(
          onAddPartida: _showAddPartidaDialog,
          onAddSubpartida: _showAddSubpartidaDialog,
        );
      case 2:
        return const ProjectGastosTab();
      case 3:
        return ProjectPagosTab(
          onAddPago: () {
            // Logica para añadir cobro, si es necesaria. Por defecto no estaba implementada en la UI pero el botón sí.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Función de registrar cobro no implementada aquí.',
                ),
              ),
            );
          },
        );
      case 4:
        return const ProjectReportesTab();
      case 5:
        return ProjectDocumentsScreen(
          proyectoId: provider.proyecto!.id!,
          proyectoNombre: provider.proyecto!.nombre,
          logoPath: provider.proyecto!.logoPath,
          embedded: true,
        );
      case 6:
        return ProjectProfitLossTab(
          proyecto: provider.proyecto!,
          gastos: provider.gastos,
          consumos: provider.consumos,
        );
      case 7:
        return ProjectPurchasesTab(proyecto: provider.proyecto!);
      default:
        return const Center(child: Text('Pestaña no encontrada'));
    }
  }
}
