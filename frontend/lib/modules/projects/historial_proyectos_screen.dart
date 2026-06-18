import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../services/project_service.dart';
import '../../models/proyecto.dart';
import 'project_details_screen.dart';

class HistorialProyectosScreen extends StatefulWidget {
  const HistorialProyectosScreen({super.key});

  @override
  State<HistorialProyectosScreen> createState() =>
      _HistorialProyectosScreenState();
}

class _HistorialProyectosScreenState extends State<HistorialProyectosScreen> {
  final ProjectService _projectService = ProjectService();
  bool _isLoading = false;
  String? _error;
  List<Proyecto> _proyectos = [];

  // Filtros
  late int _selectedYear;
  String _selectedEstado = 'Todos';
  final TextEditingController _searchController = TextEditingController();

  List<int> _years = [];
  final List<String> _estados = [
    'Todos',
    'Activo',
    'Cotización',
    'Terminado',
    'Cancelado',
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _years = List.generate(16, (index) => DateTime.now().year - index);
    _fetchHistorial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistorial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final proyectos = await _projectService.getProyectos(
        estado: _selectedEstado == 'Todos' ? null : _selectedEstado,
        year: _selectedYear,
        search: _searchController.text.trim(),
      );
      setState(() {
        _proyectos = proyectos;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        title: const Text('Historial de Proyectos'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: Column(
        children: [
          // Sección de Filtros
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Dropdown Año
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<int>(
                      value: _selectedYear,
                      decoration: const InputDecoration(
                        labelText: 'Año',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: _years.map((year) {
                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedYear = val);
                          _fetchHistorial();
                        }
                      },
                    ),
                  ),
                  // Dropdown Estado
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      value: _selectedEstado,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: _estados.map((estado) {
                        return DropdownMenuItem<String>(
                          value: estado,
                          child: Text(estado),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedEstado = val);
                          _fetchHistorial();
                        }
                      },
                    ),
                  ),
                  // Búsqueda
                  SizedBox(
                    width: 250,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Buscar proyecto o cliente',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _fetchHistorial,
                        ),
                      ),
                      onSubmitted: (_) => _fetchHistorial(),
                    ),
                  ),
                  // Botón Refrescar
                  ElevatedButton.icon(
                    onPressed: _fetchHistorial,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Filtrar'),
                  ),
                ],
              ),
            ),
          ),
          // Resultados
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text('Error: $_error'))
                : _proyectos.isEmpty
                ? const Center(child: Text('No se encontraron proyectos.'))
                : SizedBox(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.grey.shade300),
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(
                              Colors.grey.shade100,
                            ),
                            dataRowMaxHeight: 60,
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'Proyecto',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Cliente',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Presupuesto',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Estado',
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
                                  'Acciones',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rows: _proyectos.map((proyecto) {
                              final monto =
                                  proyecto.totalPresupuestoConGlobales ?? 0;
                              final fecha =
                                  proyecto.id !=
                                      null // Simulación de fecha si no hay created_at en el modelo directo
                                  ? DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(DateTime.now())
                                  : 'N/A';

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      proyecto.nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(proyecto.cliente)),
                                  DataCell(Text(f.format(monto))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          proyecto.estado,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getStatusColor(
                                            proyecto.estado,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        proyecto.estado,
                                        style: TextStyle(
                                          color: _getStatusColor(
                                            proyecto.estado,
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(fecha)),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.visibility,
                                            color: Colors.blueGrey,
                                          ),
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProjectDetailsScreen(
                                                    proyecto: proyecto,
                                                  ),
                                            ),
                                          ),
                                          tooltip: 'Ver Detalles',
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text(
                                                  'Eliminar Proyecto',
                                                ),
                                                content: Text(
                                                  '¿Estás seguro de eliminar "${proyecto.nombre}"?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          false,
                                                        ),
                                                    child: const Text(
                                                      'CANCELAR',
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          true,
                                                        ),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.red,
                                                    ),
                                                    child: const Text(
                                                      'ELIMINAR',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true) {
                                              try {
                                                await _projectService
                                                    .deleteProyecto(
                                                      proyecto.id!,
                                                    );
                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Proyecto eliminado',
                                                      ),
                                                    ),
                                                  );
                                                  _fetchHistorial(); // Refresh list
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Error: $e',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                          tooltip: 'Eliminar Proyecto',
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
      case 'Terminado':
        return Colors.blue;
      case 'Cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
