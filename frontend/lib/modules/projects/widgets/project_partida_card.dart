import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../widgets/app_status_badge.dart';
import '../providers/project_form_provider.dart';

/// Fila expandible limpia (solo lectura) para mostrar una Partida y sus Sub-partidas.
class ProjectPartidaCard extends StatefulWidget {
  final int pIndex;
  final Map<String, dynamic> partida;
  final NumberFormat formatter;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProjectPartidaCard({
    super.key,
    required this.pIndex,
    required this.partida,
    required this.formatter,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ProjectPartidaCard> createState() => _ProjectPartidaCardState();
}

class _ProjectPartidaCardState extends State<ProjectPartidaCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectFormProvider>();
    final subpartidas = (widget.partida['subpartidas'] as List?) ?? [];
    final partidaTotal = provider.partidaSubtotal(widget.pIndex);
    final rawName = widget.partida['descripcion']?.toString().trim() ?? '';
    final nombre = rawName.isEmpty ? 'Partida sin nombre' : rawName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              children: [
                // Número de partida
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${widget.pIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Nombre y conteo de ítems
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontStyle:
                              rawName.isEmpty ? FontStyle.italic : FontStyle.normal,
                          color: rawName.isEmpty
                              ? AppTheme.textSecondary
                              : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${subpartidas.length} ${subpartidas.length == 1 ? 'ítem' : 'ítems'}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 15,
                            color: const Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Total de la partida
                AppStatusBadge(
                  label: widget.formatter.format(partidaTotal),
                  type: AppStatusType.info,
                ),
                const SizedBox(width: 4),

                // Acciones rápidas: Editar y Eliminar
                IconButton(
                  tooltip: 'Editar partida',
                  onPressed: widget.onEdit,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppTheme.ledhouseBlue,
                  ),
                ),
                IconButton(
                  tooltip: 'Eliminar partida',
                  onPressed: widget.onDelete,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppTheme.dangerColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Lista limpia de sub-partidas al expandir
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 36, right: 8, bottom: 10),
            child: subpartidas.isEmpty
                ? const Text(
                    'Sin sub-partidas registradas.',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textSecondary,
                    ),
                  )
                : Column(
                    children: subpartidas.asMap().entries.map((entry) {
                      final s = entry.value as Map<String, dynamic>;
                      final desc = (s['descripcion']?.toString().trim() ?? '');
                      final ud = s['unidad']?.toString().trim() ?? 'GL';
                      final cant = (s['cantidad'] as num?)?.toDouble() ?? 0.0;
                      final costo =
                          (s['costo_unitario'] as num?)?.toDouble() ?? 0.0;
                      final subTotal = cant * costo;
                      final cantText = cant == cant.roundToDouble()
                          ? cant.toInt().toString()
                          : cant.toStringAsFixed(2);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    desc.isEmpty ? 'Ítem sin descripción' : desc,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '$cantText $ud × ${widget.formatter.format(costo)}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.formatter.format(subTotal),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),

        const Divider(height: 1, color: Color(0xFFE2E8F0)),
      ],
    );
  }
}
