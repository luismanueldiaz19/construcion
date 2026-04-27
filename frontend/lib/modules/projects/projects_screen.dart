import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      context.read<ProjectsProvider>().fetchProyectos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
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

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: provider.proyectos.length,
            itemBuilder: (context, index) {
              final proyecto = provider.proyectos[index];
              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProjectDetailsScreen(proyecto: proyecto),
                  ),
                ),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF003366),
                      child: Icon(Icons.construction, color: Colors.white),
                    ),
                    title: Text(
                      proyecto['nombre'] ?? 'Sin nombre',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      'Ubicación: ${proyecto['ubicacion'] ?? 'No especificada'}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Presupuesto: ${f.format(double.tryParse(proyecto['presupuesto_estimado']?.toString() ?? '0') ?? 0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              proyecto['estado'],
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            proyecto['estado'] ?? 'Pendiente',
                            style: TextStyle(
                              color: _getStatusColor(proyecto['estado']),
                              fontSize: 12,
                            ),
                          ),
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
