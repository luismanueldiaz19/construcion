import 'package:construccion_erp/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import 'project_documents_screen.dart';
import 'projects_provider.dart';
import 'package:intl/intl.dart';
import 'project_form_screen.dart';
import 'project_details_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
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
      body: Consumer<ProjectsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          if (provider.proyectos.isEmpty) {
            return const Center(child: Text('No hay proyectos registrados.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 350,
              mainAxisSpacing: 24,
              crossAxisSpacing: 24,
              mainAxisExtent: 240,
            ),
            itemCount: provider.proyectos.length,
            itemBuilder: (context, index) {
              final proyecto = provider.proyectos[index];
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  proyecto['estado'],
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getStatusColor(proyecto['estado']),
                                ),
                              ),
                              child: Text(
                                proyecto['estado'] ?? 'Pendiente',
                                style: TextStyle(
                                  color: _getStatusColor(proyecto['estado']),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          proyecto['nombre'] ?? 'Sin nombre',
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
                                proyecto['ubicacion'] ?? 'No especificada',
                                style: const TextStyle(color: Colors.grey),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                    double.tryParse(
                                          proyecto['presupuesto_estimado']
                                                  ?.toString() ??
                                              '0',
                                        ) ??
                                        0,
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
                                              proyectoId: proyecto['id'],
                                              proyectoNombre:
                                                  proyecto['nombre'],
                                              logoPath: proyecto['logo_path'],
                                            ),
                                      ),
                                    );
                                    break;
                                  case 'Pdf':
                                    final url = Uri.parse(
                                      '$host/reports/proyecto/${proyecto['id']}/pdf',
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
          );
        },
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
}
