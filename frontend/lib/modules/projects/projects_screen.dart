import 'package:construccion_erp/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import 'package:intl/intl.dart';
import '../../models/proyecto.dart';
import 'project_documents_screen.dart';
import 'projects_provider.dart';
import 'project_form_screen.dart';
import 'project_details_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  Proyecto? _selectedProyecto;
  String _selectedFilter = 'Todos';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectsProvider>().fetchProyectos(
        estado: 'Activo,Cotización',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: '\$');
    final screenWidth = MediaQuery.of(context).size.width;
    final isThreePane = screenWidth > 1150;

    return Consumer<ProjectsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.proyectos.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.error != null) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: Text('Error: ${provider.error}')),
          );
        }

        final projects = provider.proyectos;

        // Filtro y Búsqueda local
        final filtered = projects.where((p) {
          final matchesSearch =
              p.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.cliente.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (p.ubicacion != null &&
                  p.ubicacion!.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ));

          if (_selectedFilter == 'Todos') {
            return matchesSearch;
          } else if (_selectedFilter == 'Activos') {
            return p.estado == 'Activo' && matchesSearch;
          } else if (_selectedFilter == 'Cotizaciones') {
            return p.estado == 'Cotización' && matchesSearch;
          }
          return matchesSearch;
        }).toList();

        // Resolver proyecto activo para 3 paneles
        Proyecto? activeProyecto;
        if (filtered.isNotEmpty) {
          if (_selectedProyecto == null ||
              !filtered.any((p) => p.id == _selectedProyecto!.id)) {
            activeProyecto = filtered.first;
          } else {
            activeProyecto = filtered.firstWhere(
              (p) => p.id == _selectedProyecto!.id,
            );
          }
        }

        if (isThreePane) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Row(
              children: [
                // Panel 2: Lista Compacta de Proyectos (Ancho: 360)
                SizedBox(
                  width: 360,
                  child: Column(
                    children: [
                      // Header con Título y Botón de Añadir
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Proyectos',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ProjectFormScreen(),
                                  ),
                                );
                                if (result == true) _refresh();
                              },
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: AppTheme.accentColor,
                                size: 28,
                              ),
                              tooltip: 'Nuevo Proyecto',
                            ),
                          ],
                        ),
                      ),
                      // Buscador
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Buscar proyecto...',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Filtros Rápidos (Pills)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('Todos'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Activos'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Cotizaciones'),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      // Listado
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  'Sin proyectos coincidentes',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final p = filtered[index];
                                  final isSelected =
                                      activeProyecto != null &&
                                      p.id == activeProyecto.id;
                                  return _buildCompactProjectTile(
                                    p,
                                    isSelected,
                                    f,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.black12,
                ),
                // Panel 3: Detalle del Proyecto seleccionado Embebido
                Expanded(
                  child: activeProyecto == null
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.business_outlined,
                                size: 80,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Selecciona un proyecto para ver los detalles',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ProjectDetailsScreen(
                          key: ValueKey(activeProyecto.id),
                          proyecto: activeProyecto,
                          embedded: true,
                          onRefresh: _refresh,
                        ),
                ),
              ],
            ),
          );
        }

        // Móvil / Pantallas pequeñas (rejilla original)
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: AppTheme.textPrimary,
            title: const Text('Gestión de Proyectos'),
            actions: [
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProjectFormScreen(),
                    ),
                  );
                  if (result == true) _refresh();
                },
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Proyecto'),
              ),
              const SizedBox(width: 24),
            ],
          ),
          body: filtered.isEmpty
              ? const Center(child: Text('No hay proyectos registrados.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 350,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    mainAxisExtent: 240,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final proyecto = filtered[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProjectDetailsScreen(proyecto: proyecto),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Color(0xFF003366),
                                    child: Icon(
                                      Icons.construction,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        proyecto.estado,
                                      ).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getStatusColor(proyecto.estado),
                                      ),
                                    ),
                                    child: Text(
                                      proyecto.estado,
                                      style: TextStyle(
                                        color: _getStatusColor(proyecto.estado),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                proyecto.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      proyecto.ubicacion ?? 'No especificada',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Presupuesto',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        f.format(
                                          _getPresupuestoTotal(proyecto),
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    onSelected: (value) async {
                                      switch (value) {
                                        case 'detalles':
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProjectDetailsScreen(
                                                    proyecto: proyecto,
                                                  ),
                                            ),
                                          );
                                          break;
                                        case 'documentos':
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProjectDocumentsScreen(
                                                    proyectoId: proyecto.id!,
                                                    proyectoNombre:
                                                        proyecto.nombre,
                                                    logoPath: proyecto.logoPath,
                                                  ),
                                            ),
                                          );
                                          break;
                                        case 'Pdf':
                                          final url = Uri.parse(
                                            '$host/reports/proyecto/${proyecto.id}/pdf',
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
                                                    'No se pudo abrir el reporte completo del proyecto',
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                          break;
                                        case 'eliminar':
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                'Eliminar Proyecto',
                                              ),
                                              content: Text(
                                                '¿Estás seguro de eliminar "${proyecto.nombre}"? Esta acción no se puede deshacer.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('CANCELAR'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                  ),
                                                  child: const Text('ELIMINAR'),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            try {
                                              await context
                                                  .read<ProjectsProvider>()
                                                  .deleteProyecto(proyecto.id!);
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Proyecto eliminado correctamente',
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Error al eliminar: $e',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      _buildPopupMenuItem(
                                        'detalles',
                                        Icons.analytics_outlined,
                                        'Ver Detalles',
                                        Colors.blue,
                                      ),
                                      _buildPopupMenuItem(
                                        'documentos',
                                        Icons.folder_shared_outlined,
                                        'Documentos',
                                        Colors.orange,
                                      ),
                                      _buildPopupMenuItem(
                                        'Pdf',
                                        Icons.picture_as_pdf_outlined,
                                        'Reporte General (PDF)',
                                        Colors.red.shade700,
                                      ),
                                      const PopupMenuDivider(),
                                      _buildPopupMenuItem(
                                        'eliminar',
                                        Icons.delete_outline,
                                        'Eliminar Proyecto',
                                        Colors.red,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected =
        _selectedFilter == label ||
        (_selectedFilter == 'Cotizaciones' && label == 'Cotizaciones');
    final accentColor = const Color(0xFFE31E24);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = label;
          });
        }
      },
      selectedColor: accentColor.withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected ? accentColor : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? accentColor.withOpacity(0.5) : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildCompactProjectTile(
    Proyecto proyecto,
    bool isSelected,
    NumberFormat f,
  ) {
    final accentColor = const Color(0xFFE31E24);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? accentColor.withOpacity(0.5) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 5 : 0,
                color: accentColor,
              ),
              Expanded(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  onTap: () {
                    setState(() {
                      _selectedProyecto = proyecto;
                    });
                  },
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          proyecto.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            proyecto.estado,
                          ).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          proyecto.estado,
                          style: TextStyle(
                            color: _getStatusColor(proyecto.estado),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              proyecto.ubicacion ?? 'No especificada',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Cliente: ${proyecto.cliente}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            f.format(_getPresupuestoTotal(proyecto)),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    IconData icon,
    String text,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? estado) {
    switch (estado) {
      case 'Activo':
        return Colors.green;
      case 'Cotización':
        return Colors.orange;
      case 'Finalizado':
        return Colors.blue;
      case 'Pausado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  double _getPresupuestoTotal(Proyecto proyecto) {
    return proyecto.presupuestoEstimado +
        proyecto.itbis +
        proyecto.transporte +
        proyecto.supervisionTecnica +
        proyecto.otrosCostos;
  }
}
