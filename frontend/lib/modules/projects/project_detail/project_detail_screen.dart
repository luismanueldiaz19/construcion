import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../../models/proyecto.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_header_bar.dart';
import '../project_documents_screen.dart';
import 'providers/project_detail_provider.dart';
import 'tabs/detail_compras_tab.dart';
import 'tabs/detail_gastos_tab.dart';
import 'tabs/detail_pagos_tab.dart';
import 'tabs/detail_partidas_tab.dart';
import 'tabs/detail_reportes_tab.dart';
import 'tabs/detail_resultados_tab.dart';
import 'tabs/detail_resumen_tab.dart';
import 'widgets/project_detail_tab_bar.dart';

/// Nueva pantalla moderna y compacta de Detalle de Proyecto.
class ProjectDetailScreen extends StatefulWidget {
  final Proyecto? proyecto;
  final int? proyectoId;
  final VoidCallback? onRefresh;

  const ProjectDetailScreen({
    super.key,
    this.proyecto,
    this.proyectoId,
    this.onRefresh,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late final ProjectDetailProvider _provider;
  int _activeTab = 0;

  static const List<ProjectDetailTabItem> _tabs = [
    ProjectDetailTabItem(label: 'Resumen', icon: Icons.dashboard_outlined),
    ProjectDetailTabItem(label: 'Partidas', icon: Icons.construction_outlined),
    ProjectDetailTabItem(label: 'Gastos', icon: Icons.shopping_bag_outlined),
    ProjectDetailTabItem(label: 'Pagos', icon: Icons.payments_outlined),
    ProjectDetailTabItem(label: 'Compras', icon: Icons.shopping_cart_outlined),
    ProjectDetailTabItem(
      label: 'Documentos',
      icon: Icons.folder_shared_outlined,
    ),
    ProjectDetailTabItem(label: 'Resultados', icon: Icons.analytics_outlined),
    ProjectDetailTabItem(label: 'Reportes', icon: Icons.assessment_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _provider = ProjectDetailProvider();
    if (widget.proyecto != null) {
      _provider.init(widget.proyecto!, onRefreshParent: widget.onRefresh);
    } else if (widget.proyectoId != null) {
      _provider.initById(widget.proyectoId!, onRefreshParent: widget.onRefresh);
    }
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  Future<void> _openPdfReport(BuildContext context, int proyectoId) async {
    final url = Uri.parse('$host/reports/proyecto/$proyectoId/pdf');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else if (context.mounted) {
      AppAlert.showToast(
        context,
        'No se pudo abrir el reporte PDF del proyecto.',
        type: AppAlertType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProjectDetailProvider>.value(
      value: _provider,
      child: Consumer<ProjectDetailProvider>(
        builder: (context, provider, _) {
          final proyecto = provider.proyecto;

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppHeaderBar(
              title: proyecto?.nombre ?? 'DETALLE DE PROYECTO',
              subtitle: proyecto != null
                  ? (proyecto.cliente.isNotEmpty
                        ? proyecto.cliente
                        : proyecto.estado)
                  : 'Cargando...',
              badgeLetter: 'P',
              showMenuButton: false,
              onBack: () => Navigator.of(context).pop(),
              actions: [
                if (proyecto?.id != null)
                  IconButton(
                    tooltip: 'Imprimir reporte PDF',
                    icon: const Icon(
                      Icons.print_outlined,
                      size: 19,
                      color: Colors.white,
                    ),
                    onPressed: () => _openPdfReport(context, proyecto!.id!),
                  ),
                IconButton(
                  tooltip: 'Actualizar',
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 19,
                    color: Colors.white,
                  ),
                  onPressed: provider.isLoading ? null : provider.refresh,
                ),
              ],
            ),
            body: _buildBody(context, provider),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProjectDetailProvider provider) {
    if (provider.proyecto == null) {
      if (provider.isLoading) {
        return const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppTheme.accentColor,
          ),
        );
      }
      return AppEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'No se pudo cargar el proyecto',
        description: provider.error ?? 'Intenta actualizar nuevamente.',
        actionText: 'Reintentar',
        onAction: provider.refresh,
      );
    }

    return Column(
      children: [
        ProjectDetailTabBar(
          activeIndex: _activeTab,
          tabs: _tabs,
          onTabSelected: (index) => setState(() => _activeTab = index),
        ),
        if (provider.isLoading)
          const LinearProgressIndicator(
            minHeight: 2,
            color: AppTheme.accentColor,
            backgroundColor: Color(0xFFF1F5F9),
          ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: _buildTabContent(provider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(ProjectDetailProvider provider) {
    final proyecto = provider.proyecto!;

    switch (_activeTab) {
      case 0:
        return RefreshIndicator(
          onRefresh: provider.refresh,
          color: AppTheme.accentColor,
          child: const SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: DetailResumenTab(),
          ),
        );
      case 1:
        return RefreshIndicator(
          onRefresh: provider.refresh,
          color: AppTheme.accentColor,
          child: const SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: DetailPartidasTab(),
          ),
        );
      case 2:
        return RefreshIndicator(
          onRefresh: provider.refresh,
          color: AppTheme.accentColor,
          child: const SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: DetailGastosTab(),
          ),
        );
      case 3:
        return RefreshIndicator(
          onRefresh: provider.refresh,
          color: AppTheme.accentColor,
          child: const SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: DetailPagosTab(),
          ),
        );
      case 4:
        return DetailComprasTab(proyecto: proyecto);
      case 5:
        return ProjectDocumentsScreen(
          proyectoId: proyecto.id!,
          proyectoNombre: proyecto.nombre,
          logoPath: proyecto.logoPath,
          embedded: true,
        );
      case 6:
        return const DetailResultadosTab();
      case 7:
        return const SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: DetailReportesTab(),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
