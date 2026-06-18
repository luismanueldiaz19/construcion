import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants.dart';
import '../../../../models/partida.dart';
import '../../../../models/subpartida.dart';
import '../../../../models/avance_proyecto.dart';
import '../../providers/project_details_provider.dart';
import '../cards/detail_stat_card.dart';

class ProjectPartidasTab extends StatelessWidget {
  final VoidCallback onAddPartida;
  final Function(int) onAddSubpartida;

  const ProjectPartidasTab({
    super.key,
    required this.onAddPartida,
    required this.onAddSubpartida,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectDetailsProvider>(context);
    final f = NumberFormat.currency(symbol: '\$');
    final proyecto = provider.proyecto!;
    final partidas = proyecto.partidas;

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

    final totalConImpuestos = double.tryParse(proyecto.totalPresupuestoConGlobales?.toString() ?? '0') ?? 0;

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
                    Expanded(child: DetailStatCard(title: 'Total de Partidas', value: total.toString(), color: Colors.blueGrey)),
                    const SizedBox(width: 16),
                    Expanded(child: DetailStatCard(title: 'Completadas', value: completadas.toString(), color: Colors.green, subtitle: '${total > 0 ? (completadas / total * 100).toStringAsFixed(1) : 0}%')),
                    const SizedBox(width: 16),
                    Expanded(child: DetailStatCard(title: 'En Proceso', value: enProceso.toString(), color: Colors.blue, subtitle: '${total > 0 ? (enProceso / total * 100).toStringAsFixed(1) : 0}%')),
                    const SizedBox(width: 16),
                    Expanded(child: DetailStatCard(title: 'Pendientes', value: pendientes.toString(), color: Colors.orange, subtitle: '${total > 0 ? (pendientes / total * 100).toStringAsFixed(1) : 0}%')),
                    const SizedBox(width: 16),
                    Expanded(child: DetailStatCard(title: 'Presupuesto Total', value: f.format(totalConImpuestos), color: const Color(0xFF003366))),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: DetailStatCard(title: 'Total Partidas', value: total.toString(), color: Colors.blueGrey)),
                        const SizedBox(width: 12),
                        Expanded(child: DetailStatCard(title: 'Completadas', value: completadas.toString(), color: Colors.green)),
                        const SizedBox(width: 12),
                        Expanded(child: DetailStatCard(title: 'En Proceso', value: enProceso.toString(), color: Colors.blue)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: DetailStatCard(title: 'Pendientes', value: pendientes.toString(), color: Colors.orange)),
                        const SizedBox(width: 12),
                        Expanded(child: DetailStatCard(title: 'Presupuesto Total', value: f.format(totalConImpuestos), color: const Color(0xFF003366))),
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
              ),
              if (proyecto.estado == 'Activo')
                ElevatedButton.icon(
                  onPressed: onAddPartida,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Añadir Partida'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA000),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            ...partidas.map((p) => _buildPartidaCard(context, provider, p, f)).toList(),
        ],
      ),
    );
  }

  Widget _buildPartidaCard(BuildContext context, ProjectDetailsProvider provider, Partida partida, NumberFormat f) {
    final subpartidas = partida.subpartidas;
    final subpartidasIds = subpartidas.map((s) => s.id).toList();

    final double totalPartida = partida.totalPresupuestado;
    final double gastosPartida = provider.gastos
        .where((g) => g.subpartidaId != null && subpartidasIds.contains(g.subpartidaId))
        .fold(0.0, (sum, g) => sum + g.monto);

    final double consumosPartida = provider.consumos
        .where((c) => c.subpartidaId != null && subpartidasIds.contains(c.subpartidaId))
        .fold(0.0, (sum, c) => sum + c.total);

    final double costoRealPartida = gastosPartida + consumosPartida;
    final bool allCompleted = subpartidas.isNotEmpty && subpartidas.every((s) => s.avanceActual >= 100);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: allCompleted ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: allCompleted ? Colors.green.shade300 : Colors.transparent,
          width: 2,
        ),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: allCompleted ? Colors.green : const Color(0xFF003366),
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
                      color: allCompleted ? Colors.green.shade700 : const Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (totalPartida > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (costoRealPartida / totalPartida) > 1 ? const Color(0xFFFFF3E0) : const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: (costoRealPartida / totalPartida) > 1 ? const Color(0xFFFFB74D) : const Color(0xFF4DB6AC),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${(costoRealPartida / totalPartida * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: (costoRealPartida / totalPartida) > 1 ? const Color(0xFFE65100) : const Color(0xFF00695C),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2E7D32)),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.print_outlined, size: 20, color: Color(0xFF003366)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          final url = Uri.parse('$host/reports/partida/${partida.id}/pdf');
                          if (await canLaunchUrl(url)) await launchUrl(url);
                        },
                      ),
                    ],
                  ),
                  if (costoRealPartida > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      f.format(costoRealPartida),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFC62828)),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (totalPartida - costoRealPartida) >= 0 ? const Color(0xFFE3F2FD) : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Dif: ${f.format(totalPartida - costoRealPartida)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: (totalPartida - costoRealPartida) >= 0 ? const Color(0xFF1565C0) : const Color(0xFFE65100),
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
                  Text('PARTIDA COMPLETADA AL 100%', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              )
            : Text('Partida con ${subpartidas.length} Sub-Partidas'),
        children: [
          ...subpartidas.map((s) => _buildSubpartidaTile(context, provider, s, f)).toList(),
          if (provider.proyecto!.estado == 'Activo')
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
              title: const Text('Añadir Sub-partida', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
              onTap: () => onAddSubpartida(partida.id!),
            ),
        ],
      ),
    );
  }

  Widget _buildSubpartidaTile(BuildContext context, ProjectDetailsProvider provider, Subpartida sub, NumberFormat f) {
    final avance = sub.avanceActual;
    return ListTile(
      title: Text(sub.descripcion),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Presupuesto: ${f.format(sub.totalPresupuestado)} (${sub.unidad})'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: avance / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(avance == 100 ? Colors.green : Colors.blue),
                ),
              ),
              const SizedBox(width: 8),
              Text('${avance.toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
      trailing: avance >= 100
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(20)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  Text('COMPLETADO', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                ],
              ),
            )
          : (provider.proyecto!.estado == 'Activo'
              ? ElevatedButton(
                  onPressed: () => _showAvanceDialog(context, provider, sub),
                  child: const Text('Registrar Avance'),
                )
              : const SizedBox.shrink()),
    );
  }

  void _showAvanceDialog(BuildContext context, ProjectDetailsProvider provider, Subpartida sub) {
    final initialValue = (sub.avanceActual + 5.0 <= 100) ? sub.avanceActual + 5.0 : 100.0;
    final controller = TextEditingController(text: initialValue.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Registrar Avance: ${sub.descripcion}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa el nuevo porcentaje de avance físico (%):'),
            DropdownButtonFormField<double>(
              value: initialValue,
              decoration: const InputDecoration(labelText: 'Nuevo Porcentaje Total (%)', border: OutlineInputBorder()),
              items: [
                ...[for (double v = sub.avanceActual + 5.0; v < 100; v += 5.0) v],
                100.0,
              ].toSet().map((val) => DropdownMenuItem(value: val, child: Text('${val.toInt()}%'))).toList(),
              onChanged: (v) => controller.text = (v ?? 0).toString(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                final porc = double.tryParse(controller.text) ?? 0;
                final total = sub.totalPresupuestado;
                await provider.projectService.createAvance(
                  AvanceProyecto(
                    partidaId: sub.partidaId,
                    subpartidaId: sub.id!,
                    fecha: DateTime.now(),
                    porcentaje: porc,
                    valorEjecutado: (porc / 100) * total,
                  ),
                );
                Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Avance registrado correctamente')),
                  );
                }
                provider.refresh();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
