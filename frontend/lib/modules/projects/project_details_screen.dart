import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../services/api_service.dart';

import 'project_documents_screen.dart';
import 'gasto_proyecto_dialog.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> proyecto;
  const ProjectDetailsScreen({super.key, required this.proyecto});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  late Map<String, dynamic> _proyecto = {};
  List<dynamic> _gastos = [];
  List<dynamic> _consumos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _proyecto = widget.proyecto;
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final proyectos = await _apiService.getProyectos();
      final gastos = await _apiService.getGastosProyecto(_proyecto['id']);
      final consumos = await _apiService.getConsumosProyecto(_proyecto['id']);
      setState(() {
        _proyecto = proyectos.firstWhere((p) => p['id'] == _proyecto['id']);
        _gastos = gastos;
        _consumos = consumos;
        _isLoading = false;
      });
    } catch (e) {
      print("Error refreshing project: $e");
    }
  }

  Future<void> _provisionarTodo100() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.provisionarTodo100(_proyecto['id']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Proyecto provisionado al 100%!')),
      );
      _refresh();
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
        await _apiService.uploadLogo(_proyecto['id'], image);
        await _refresh();
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
      await _apiService.removeLogo(_proyecto['id']);
      await _refresh();
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
    String estadoActual = _proyecto['estado'];

    if (estadoActual == 'Cotización') {
      opciones = ['Activo', 'Cancelado'];
    } else if (estadoActual == 'Activo') {
      opciones = ['Terminado'];
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este proyecto ya está finalizado o cancelado.'),
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
        await _apiService.updateProyectoEstado(_proyecto['id'], nuevoEstado);
        await _refresh();
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
    final controller = TextEditingController(text: _proyecto['notas']);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Notas / Observaciones'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Ingrese notas que aparecerán en el PDF...',
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
        await _apiService.updateProyecto(_proyecto['id'], {
          'notas': controller.text,
        });
        await _refresh();
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
              _provisionarTodo100();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('SÍ, PROVISIONAR TODO'),
          ),
        ],
      ),
    );
  }

  bool get _isReadonly {
    return _proyecto['estado'] == 'Terminado' ||
        _proyecto['estado'] == 'Cancelado';
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: '\$');
    final partidas = _proyecto['partidas'] as List? ?? [];

    final totalConImpuestos =
        double.tryParse(
          _proyecto['total_presupuesto_con_globales']?.toString() ?? '0',
        ) ??
        0;
    final cobrado =
        double.tryParse(_proyecto['total_cobrado']?.toString() ?? '0') ?? 0;
    final saldoPendiente = totalConImpuestos - cobrado;

    return Scaffold(
      appBar: AppBar(
        title: Text(_proyecto['nombre']),
        actions: [
          IconButton(
            onPressed: () async {
              final url = Uri.parse(
                '$host/reports/proyecto/${_proyecto['id']}/pdf',
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
                final isWide = constraints.maxWidth > 900;
                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(f),
                    const SizedBox(height: 32),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Estructura de Costos y Avance',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...partidas
                                    .map((p) => _buildPartidaCard(p, f))
                                    .toList(),
                                // if (!_isReadonly)
                                //   Padding(
                                //     padding: const EdgeInsets.symmetric(
                                //       vertical: 16.0,
                                //     ),
                                //     child: Center(
                                //       child: ElevatedButton.icon(
                                //         onPressed: _showAddPartidaDialog,
                                //         icon: const Icon(Icons.add),
                                //         label: const Text(
                                //           'Añadir Partida Extra',
                                //         ),
                                //       ),
                                //     ),
                                //   ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(flex: 4, child: _buildGastosSection(f)),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estructura de Costos y Avance',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...partidas
                              .map((p) => _buildPartidaCard(p, f))
                              .toList(),
                          // if (!_isReadonly)
                          //   Padding(
                          //     padding: const EdgeInsets.symmetric(
                          //       vertical: 16.0,
                          //     ),
                          //     child: Center(
                          //       child: ElevatedButton.icon(
                          //         onPressed: _showAddPartidaDialog,
                          //         icon: const Icon(Icons.add),
                          //         label: const Text('Añadir Partida Extra'),
                          //       ),
                          //     ),
                          //   ),
                          const SizedBox(height: 32),
                          _buildGastosSection(f),
                        ],
                      ),
                  ],
                );

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: content,
                    ),
                  ),
                );
              },
            ),
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
          if (g['tipo_gasto'].toString().contains('Mano de Obra')) {
            icon = Icons.engineering;
            color = Colors.orange;
          } else if (g['tipo_gasto'].toString().contains('Alquiler')) {
            icon = Icons.construction;
            color = Colors.purple;
          } else if (g['tipo_gasto'].toString().contains('Transporte')) {
            icon = Icons.local_shipping;
            color = Colors.cyan;
          }

          final fechaStr = g['fecha'].toString().split('T')[0];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              title: Text(
                g['descripcion'] ?? 'Gasto sin descripción',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "${g['proveedor']?['nombre'] ?? 'Sin proveedor'} • $fechaStr",
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    f.format(double.tryParse(g['monto'].toString()) ?? 0),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.redAccent,
                    ),
                  ),
                  Text(
                    g['metodo_pago'] ?? '',
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
                      image: _proyecto['logo_path'] != null
                          ? DecorationImage(
                              image: NetworkImage(
                                '$host/storage/${_proyecto['logo_path']}',
                              ),
                              fit: BoxFit.contain,
                            )
                          : null,
                    ),
                    child: _proyecto['logo_path'] == null
                        ? const Icon(Icons.add_a_photo, color: Colors.white54)
                        : Stack(
                            children: [
                              Positioned(
                                right: 0,
                                top: 0,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: _removeLogo,
                                ),
                              ),
                            ],
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
                              _proyecto['nombre'] ?? '',
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
                      if (_proyecto['notas'] != null &&
                          _proyecto['notas'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _proyecto['notas'],
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
                    _proyecto['cliente'] ?? 'N/A',
                    Colors.white,
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Ubicación',
                    _proyecto['ubicacion'] ?? 'N/A',
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
                              _proyecto['estado'],
                            ).withOpacity(0.2),
                            border: Border.all(
                              color: _getEstadoColor(_proyecto['estado']),
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _proyecto['estado'] ?? '',
                            style: TextStyle(
                              color: _getEstadoColor(_proyecto['estado']),
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
            /* Botón antiguo eliminado para usar _cambiarEstado */
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
                            _proyecto['total_presupuesto_con_globales']
                                    ?.toString() ??
                                '0',
                          ) ??
                          0,
                    ),
                    Colors.greenAccent,
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Avance Físico',
                    '${_proyecto['porcentaje_avance_total'] ?? 0}%',
                    Colors.blueAccent,
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Ejecutado',
                    f.format(
                      double.tryParse(
                            _proyecto['monto_ejecutado_total']?.toString() ??
                                '0',
                          ) ??
                          0,
                    ),
                    Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildIndirectsBreakdown(f),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, c) {
                if (c.maxWidth > 700) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildProfitabilityCard(f)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildCashFlowCard(f)),
                    ],
                  );
                }
                return Column(
                  children: [
                    _buildProfitabilityCard(f),
                    const SizedBox(height: 16),
                    _buildCashFlowCard(f),
                  ],
                );
              },
            ),

            Builder(
              builder: (context) {
                final totalConImpuestos =
                    double.tryParse(
                      _proyecto['total_presupuesto_con_globales']?.toString() ??
                          '0',
                    ) ??
                    0;
                final cobrado =
                    double.tryParse(
                      _proyecto['total_cobrado']?.toString() ?? '0',
                    ) ??
                    0;
                final saldoPendiente = totalConImpuestos - cobrado;

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      if (_proyecto['estado'] == 'Activo') ...[
                        ElevatedButton.icon(
                          onPressed: () => _showGastoDialog(context),
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Registrar Gasto'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: Colors.black87,
                          ),
                        ),
                        if (saldoPendiente > 0.01)
                          ElevatedButton.icon(
                            onPressed: () => _showPagoDialog(),
                            icon: const Icon(Icons.payments, size: 18),
                            label: const Text('Pago Cliente'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black87,
                            ),
                          ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndirectsBreakdown(NumberFormat f) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DESGLOSE DE COSTOS INDIRECTOS',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildIndirectRow(
            'Supervisión Técnica',
            _proyecto['supervision_tecnica'],
            f,
          ),
          _buildIndirectRow('ITBIS', _proyecto['itbis'], f),
          _buildIndirectRow('Transporte', _proyecto['transporte'], f),
          _buildIndirectRow('Otros Gastos', _proyecto['otros_costos'], f),
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
    final ingresoNeto =
        double.tryParse(_proyecto['ingreso_neto_real']?.toString() ?? '0') ?? 0;

    final double gastosEfectivo = _gastos.fold(
      0,
      (sum, g) => sum + (double.tryParse(g['monto'].toString()) ?? 0),
    );
    final double costosMateriales = _consumos.fold(
      0,
      (sum, c) => sum + (double.tryParse(c['total'].toString()) ?? 0),
    );
    final costoReal = gastosEfectivo + costosMateriales;

    final ganancia = ingresoNeto - costoReal;
    final margen = ingresoNeto > 0 ? (ganancia / ingresoNeto) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'ANÁLISIS DE RENTABILIDAD (GANANCIA REAL)',
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
    final cobrado =
        double.tryParse(_proyecto['total_cobrado']?.toString() ?? '0') ?? 0;
    final ejecutado =
        double.tryParse(
          _proyecto['monto_ejecutado_total']?.toString() ?? '0',
        ) ??
        0;
    final balance = cobrado - ejecutado;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          const Text(
            'BALANCE DE FONDOS VS EJECUCIÓN',
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
                '⚠️ Estás ejecutando más de lo cobrado',
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
      case 'Cotización':
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

  Widget _buildPartidaCard(Map<String, dynamic> partida, NumberFormat f) {
    final subpartidas = partida['subpartidas'] as List? ?? [];

    final subpartidasIds = subpartidas.map((s) => s['id']).toList();

    // Calcular el total de la partida sumando sus subpartidas
    final double totalPartida = subpartidas.fold(
      0,
      (sum, item) =>
          sum +
          (double.tryParse(item['total_presupuestado']?.toString() ?? '0') ??
              0),
    );

    // Calcular el costo real para esta partida (Gastos directos + Consumo de materiales)
    final double gastosPartida = _gastos
        .where(
          (g) =>
              g['subpartida_id'] != null &&
              subpartidasIds.contains(g['subpartida_id']),
        )
        .fold(
          0.0,
          (sum, g) =>
              sum + (double.tryParse(g['monto']?.toString() ?? '0') ?? 0),
        );

    final double consumosPartida = _consumos
        .where(
          (c) =>
              c['subpartida_id'] != null &&
              subpartidasIds.contains(c['subpartida_id']),
        )
        .fold(
          0.0,
          (sum, c) =>
              sum + (double.tryParse(c['total']?.toString() ?? '0') ?? 0),
        );

    final double costoRealPartida = gastosPartida + consumosPartida;

    // Verificar si todas las subpartidas están al 100%
    final bool allCompleted =
        subpartidas.isNotEmpty &&
        subpartidas.every(
          (s) =>
              (double.tryParse(s['avance_actual']?.toString() ?? '0') ?? 0) >=
              100,
        );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: allCompleted ? 4 : 1, // Más sombra si está completado
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
              child: Text(
                partida['descripcion'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: allCompleted
                      ? Colors.green.shade700
                      : const Color(0xFF003366),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      f.format(totalPartida),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.print_outlined,
                        size: 18,
                        color: Colors.blueGrey,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Imprimir Reporte de Partida',
                      onPressed: () async {
                        final url = Uri.parse(
                          '$host/reports/partida/${partida['id']}/pdf',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No se pudo abrir el reporte de partida',
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
                if (costoRealPartida > 0)
                  Text(
                    'Gasto Real: ${f.format(costoRealPartida)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.redAccent,
                    ),
                  ),
              ],
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
          // if (!_isReadonly)
          //   Padding(
          //     padding: const EdgeInsets.symmetric(vertical: 8.0),
          //     child: TextButton.icon(
          //       onPressed: () => _showAddSubpartidaDialog(partida['id']),
          //       icon: const Icon(Icons.add, size: 18),
          //       label: const Text('Añadir Sub-partida'),
          //     ),
          //   ),
        ],
      ),
    );
  }

  Widget _buildSubpartidaTile(Map<String, dynamic> sub, NumberFormat f) {
    final avance =
        double.tryParse(sub['avance_actual']?.toString() ?? '0') ?? 0;
    return ListTile(
      title: Text(sub['descripcion']),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Presupuesto: ${f.format(double.tryParse(sub['total_presupuestado']?.toString() ?? '0') ?? 0)} (${sub['unidad']})',
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
          : (_proyecto['estado'] == 'Activo'
                ? ElevatedButton(
                    onPressed: () => _showAvanceDialog(sub),
                    child: const Text('Registrar Avance'),
                  )
                : const SizedBox.shrink()),
    );
  }

  void _showAvanceDialog(Map<String, dynamic> sub) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Registrar Avance: ${sub['descripcion']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa el nuevo porcentaje de avance físico (%):'),
            DropdownButtonFormField<double>(
              value:
                  (double.tryParse(sub['avance_actual']?.toString() ?? '0') ??
                              0) +
                          5.0 <=
                      100
                  ? (double.tryParse(sub['avance_actual']?.toString() ?? '0') ??
                            0) +
                        5.0
                  : 100.0,
              decoration: const InputDecoration(
                labelText: 'Nuevo Porcentaje Total (%)',
                border: OutlineInputBorder(),
              ),
              items:
                  List.generate(
                        ((100 -
                                        (double.tryParse(
                                              sub['avance_actual']
                                                      ?.toString() ??
                                                  '0',
                                            ) ??
                                            0)) /
                                    5)
                                .floor() +
                            1,
                        (index) =>
                            (double.tryParse(
                                  sub['avance_actual']?.toString() ?? '0',
                                ) ??
                                0) +
                            (index) * 5.0,
                      )
                      .where(
                        (val) =>
                            val >
                            (double.tryParse(
                                  sub['avance_actual']?.toString() ?? '0',
                                ) ??
                                0),
                      )
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
                final total =
                    double.tryParse(sub['total_presupuestado'].toString()) ?? 0;
                await _apiService.createAvance({
                  'partida_id':
                      sub['partida_id'], // Corregido: el campo en BD es partida_id (referencia a subpartida en este contexto de UI)
                  'subpartida_id': sub['id'],
                  'fecha': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  'porcentaje': porc,
                  'valor_ejecutado': (porc / 100) * total,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Avance registrado correctamente'),
                  ),
                );
                _refresh();
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
      _refresh();
    }
  }

  void _showPagoDialog() {
    final totalConImpuestos =
        double.tryParse(
          _proyecto['total_presupuesto_con_globales']?.toString() ?? '0',
        ) ??
        0;
    final cobrado =
        double.tryParse(_proyecto['total_cobrado']?.toString() ?? '0') ?? 0;
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
            _apiService.getBancos().then((value) {
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
                  keyboardType: TextInputType.number,
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
                    labelText: 'Método de Pago',
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
                    if (monto <= 0) throw 'Monto inválido';
                    if (monto > (saldoPendiente + 0.01)) {
                      throw 'El monto no puede exceder el saldo pendiente (${f.format(saldoPendiente)})';
                    }

                    await _apiService.createPago({
                      'proyecto_id': _proyecto['id'],
                      'monto': monto,
                      'metodo_pago': metodoPago,
                      'banco_id': bancoId,
                      'fecha': DateTime.now().toIso8601String(),
                      'glosa':
                          'Pago de cliente - Proyecto: ${_proyecto['nombre']}',
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('¡Pago registrado con éxito!'),
                      ),
                    );
                    _refresh();
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
            title: const Text('Añadir Partida (Adendum)'),
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
                                labelText: 'Descripción Sub-partida',
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
                                    keyboardType: TextInputType.number,
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
                                    keyboardType: TextInputType.number,
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
                          await _apiService.addPartida(_proyecto['id'], {
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
                          _refresh();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Partida añadida exitosamente'),
                            ),
                          );
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                child: const Text('Añadir Partida'),
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
            title: const Text('Añadir Sub-partida'),
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
                                labelText: 'Descripción Sub-partida',
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
                                    keyboardType: TextInputType.number,
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
                                    keyboardType: TextInputType.number,
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
                          await _apiService.addSubpartida(partidaId, {
                            'descripcion': subDescripcionController.text,
                            'unidad': subUnidadController.text,
                            'cantidad':
                                double.tryParse(subCantidadController.text) ??
                                1,
                            'costo_unitario':
                                double.tryParse(subCostoController.text) ?? 0,
                          });
                          Navigator.pop(context);
                          _refresh();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sub-partida añadida exitosamente'),
                            ),
                          );
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                child: const Text('Añadir Sub-partida'),
              ),
            ],
          );
        },
      ),
    );
  }
}
