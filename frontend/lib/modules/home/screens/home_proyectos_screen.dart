import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/proyecto.dart';
import '../../projects/projects_provider.dart';
import '../../projects/project_details_screen.dart';
import '../../projects/project_form_screen.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_status_badge.dart';

/// Pantalla moderna para visualizar y gestionar los proyectos activos dentro del Home ERP.
class HomeProyectosScreen extends StatefulWidget {
  const HomeProyectosScreen({super.key});

  @override
  State<HomeProyectosScreen> createState() => _HomeProyectosScreenState();
}

class _HomeProyectosScreenState extends State<HomeProyectosScreen> {
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: 'RD\$ ',
    decimalDigits: 2,
  );
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  String _searchQuery = '';
  String _selectedStatusFilter = 'Activo'; // Por defecto muestra activos

  @override
  void initState() {
    super.initState();
    _loadProyectos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadProyectos() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProjectsProvider>().fetchProyectos(
        estado: _selectedStatusFilter == 'Todos' ? null : _selectedStatusFilter,
      );
    });
  }

  void _onStatusFilterChanged(String filter) {
    if (_selectedStatusFilter == filter) return;
    setState(() {
      _selectedStatusFilter = filter;
    });
    _loadProyectos();
  }

  Future<void> _openCreateProject() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProjectFormScreen(),
      ),
    );
    if (created == true) {
      _loadProyectos();
    }
  }

  double _getPresupuestoTotal(Proyecto proyecto) {
    if (proyecto.totalPresupuestoConGlobales != null &&
        proyecto.totalPresupuestoConGlobales! > 0) {
      return proyecto.totalPresupuestoConGlobales!;
    }
    return proyecto.presupuestoEstimado +
        proyecto.itbis +
        proyecto.transporte +
        proyecto.supervisionTecnica +
        proyecto.otrosCostos;
  }

  AppStatusType _getStatusType(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return AppStatusType.active;
      case 'cotización':
      case 'cotizacion':
      case 'pendiente':
        return AppStatusType.pending;
      case 'finalizado':
        return AppStatusType.info;
      case 'pausado':
      case 'cancelado':
        return AppStatusType.inactive;
      default:
        return AppStatusType.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsProvider>(
      builder: (context, provider, _) {
        final allProyectos = provider.proyectos;

        // Filtrado por texto de búsqueda
        final filteredList = allProyectos.where((p) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          final matchesNombre = p.nombre.toLowerCase().contains(q);
          final matchesCliente = p.cliente.toLowerCase().contains(q);
          final matchesUbicacion =
              p.ubicacion != null && p.ubicacion!.toLowerCase().contains(q);
          return matchesNombre || matchesCliente || matchesUbicacion;
        }).toList();

        // Cálculo de KPIs rápidos de las obras activas
        final int totalObras = filteredList.length;
        final double totalPresupuesto = filteredList.fold(
          0.0,
          (sum, p) => sum + _getPresupuestoTotal(p),
        );
        final double promedioAvance = filteredList.isEmpty
            ? 0.0
            : (filteredList.fold(
                    0.0,
                    (sum, p) => sum + (p.porcentajeAvanceTotal ?? 0.0),
                  ) /
                  filteredList.length);

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton(
            heroTag: 'fab_nueva_obra',
            onPressed: _openCreateProject,
            tooltip: 'Nueva Obra',
            backgroundColor: const Color(0xFFE31E24),
            foregroundColor: Colors.white,
            child: const Icon(Icons.add_rounded),
          ),
          body: RefreshIndicator(
            onRefresh: () async => _loadProyectos(),
            color: const Color(0xFFE31E24),
            child: Column(
              children: [
                // Barra superior de filtros y búsqueda
                _buildControlBar(totalObras),

                // Métricas rápidas (KPIs)
                _buildKpiSummaryBar(
                  totalObras: totalObras,
                  totalPresupuesto: totalPresupuesto,
                  promedioAvance: promedioAvance,
                ),

                // Contenido principal: Grid de Cards o Estados
                Expanded(
                  child: _buildMainContent(
                    provider: provider,
                    proyectos: filteredList,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlBar(int totalObras) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo de Búsqueda moderno
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Buscar obra, cliente o ubicación...',
                hintStyle: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 9,
                  horizontal: 8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Píldoras de Filtro de Estado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusFilterChip(
                  label: 'Activos',
                  filterValue: 'Activo',
                  icon: Icons.check_circle_outline_rounded,
                  activeColor: const Color(0xFF16A34A),
                ),
                const SizedBox(width: 8),
                _buildStatusFilterChip(
                  label: 'Cotizaciones',
                  filterValue: 'Cotización',
                  icon: Icons.pending_actions_rounded,
                  activeColor: const Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                _buildStatusFilterChip(
                  label: 'Finalizados',
                  filterValue: 'Finalizado',
                  icon: Icons.task_alt_rounded,
                  activeColor: const Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                _buildStatusFilterChip(
                  label: 'Todos',
                  filterValue: 'Todos',
                  icon: Icons.list_alt_rounded,
                  activeColor: const Color(0xFF475569),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip({
    required String label,
    required String filterValue,
    required IconData icon,
    required Color activeColor,
  }) {
    final bool isSelected = _selectedStatusFilter == filterValue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onStatusFilterChanged(filterValue),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.12)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.6)
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? activeColor : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? activeColor : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiSummaryBar({
    required int totalObras,
    required double totalPresupuesto,
    required double promedioAvance,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 680;

        final cards = [
          _buildKpiMiniCard(
            label: 'Presupuesto Total\n$totalObras obras ',
            value: _currencyFormat.format(totalPresupuesto),
            icon: Icons.payments_outlined,
            color: const Color(0xFF16A34A),
            minWidth: isNarrow ? 190.0 : null,
          ),
          const SizedBox(width: 10),
          _buildKpiMiniCard(
            label: 'Avance Promedio\n',
            value: '${promedioAvance.toStringAsFixed(1)}%',
            icon: Icons.trending_up_rounded,
            color: const Color(0xFFD97706),
            minWidth: isNarrow ? 160.0 : null,
          ),
        ];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          child: isNarrow
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: cards),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: cards.map((c) {
                      if (c is SizedBox) return c;
                      return Expanded(child: c);
                    }).toList(),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildKpiMiniCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    double? minWidth,
  }) {
    return Container(
      constraints: minWidth != null ? BoxConstraints(minWidth: minWidth) : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 13, color: color),
              ),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent({
    required ProjectsProvider provider,
    required List<Proyecto> proyectos,
  }) {
    if (provider.isLoading && proyectos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
              strokeWidth: 2.5,
            ),
            SizedBox(height: 14),
            Text(
              'Cargando proyectos activos...',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (provider.error != null && proyectos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: Color(0xFFDC2626),
              ),
              const SizedBox(height: 12),
              const Text(
                'No se pudieron cargar los proyectos',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'Reintentar',
                icon: Icons.refresh_rounded,
                size: AppButtonSize.compact,
                variant: AppButtonVariant.primary,
                onPressed: _loadProyectos,
              ),
            ],
          ),
        ),
      );
    }

    if (proyectos.isEmpty) {
      return AppEmptyState(
        icon: Icons.domain_disabled_rounded,
        title: _searchQuery.isNotEmpty
            ? 'Sin resultados para "$_searchQuery"'
            : 'No hay proyectos en estado "$_selectedStatusFilter"',
        description:
            'Intenta cambiar los filtros de búsqueda o crea una nueva obra para comenzar su seguimiento.',
        actionText: 'Crear Nueva Obra',
        onAction: _openCreateProject,
      );
    }

    // Grid adaptativo moderno
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 460,
            mainAxisExtent: 220,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: proyectos.length,
          itemBuilder: (context, index) {
            final proyecto = proyectos[index];
            return _buildModernProjectCard(proyecto);
          },
        );
      },
    );
  }

  Widget _buildModernProjectCard(Proyecto proyecto) {
    final double presupuestoTotal = _getPresupuestoTotal(proyecto);
    final double avancePorcentaje = (proyecto.porcentajeAvanceTotal ?? 0.0)
        .clamp(0.0, 100.0);
    final double montoEjecutado = proyecto.montoEjecutadoTotal ?? 0.0;

    // Colores según avance
    final Color progressColor = avancePorcentaje >= 75
        ? const Color(0xFF16A34A) // Verde éxito
        : avancePorcentaje >= 25
        ? const Color(0xFF2563EB) // Azul institucional
        : const Color(0xFFD97706); // Ámbar inicial

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailsScreen(
                proyecto: proyecto,
                onRefresh: _loadProyectos,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Fila 1: Avatar de la obra + Título + Status Pill + Menú rápido
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono o inicial estilizada
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Nombre de Obra y Cliente
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          proyecto.nombre,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.business_center_outlined,
                              size: 12,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                proyecto.cliente.isNotEmpty
                                    ? proyecto.cliente
                                    : 'Cliente sin asignar',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Badge de Estado
                  AppStatusBadge(
                    label: proyecto.estado.toUpperCase(),
                    type: _getStatusType(proyecto.estado),
                  ),
                ],
              ),

              // Fila 2: Ubicación y Fecha de la obra
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      proyecto.ubicacion ?? 'Ubicación no especificada',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (proyecto.fechaInicio != null) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 11,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _dateFormat.format(proyecto.fechaInicio!),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),

              // Fila 3: Barra de Avance Físico
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Avance de Obra',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                      Text(
                        '${avancePorcentaje.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: avancePorcentaje / 100.0,
                      minHeight: 6.5,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                ],
              ),

              // Fila 4: Footer Financiero (Presupuesto vs Ejecutado) y Botón Ver
              Container(
                padding: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFF1F5F9), width: 1.0),
                  ),
                ),
                child: Row(
                  children: [
                    // Presupuesto
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PRESUPUESTO',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 1),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _currencyFormat.format(presupuestoTotal),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Ejecutado
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EJECUTADO',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 1),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _currencyFormat.format(montoEjecutado),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color:
                                    montoEjecutado > presupuestoTotal &&
                                        presupuestoTotal > 0
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Flecha de navegación a detalles
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Color(0xFF475569),
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
}
