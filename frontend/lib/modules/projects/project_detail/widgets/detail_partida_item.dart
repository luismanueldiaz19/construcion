import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_theme.dart';
import '../../../../models/partida.dart';
import '../../../../models/subpartida.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_status_badge.dart';

/// Fila expandible compacta para una Partida y sus Sub-partidas en el Detalle del Proyecto.
class DetailPartidaItem extends StatefulWidget {
  final int index;
  final Partida partida;
  final double costoReal;
  final bool canRegisterAvance;
  final NumberFormat formatter;
  final VoidCallback onOpenMateriales;
  final VoidCallback onPrintPdf;
  final ValueChanged<Subpartida> onRegisterAvance;

  const DetailPartidaItem({
    super.key,
    required this.index,
    required this.partida,
    required this.costoReal,
    required this.canRegisterAvance,
    required this.formatter,
    required this.onOpenMateriales,
    required this.onPrintPdf,
    required this.onRegisterAvance,
  });

  @override
  State<DetailPartidaItem> createState() => _DetailPartidaItemState();
}

class _DetailPartidaItemState extends State<DetailPartidaItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final subpartidas = widget.partida.subpartidas;
    final totalPresupuestado = widget.partida.totalPresupuestado;
    final costoReal = widget.costoReal;
    final diferencia = totalPresupuestado - costoReal;

    final allCompleted = subpartidas.isNotEmpty &&
        subpartidas.every((s) => s.avanceActual >= 100);
    final avanceFisico = subpartidas.isEmpty
        ? 0.0
        : subpartidas.fold<double>(0.0, (sum, s) => sum + s.avanceActual) /
            subpartidas.length;
    final pctFinanciero =
        totalPresupuestado > 0 ? (costoReal / totalPresupuestado * 100) : 0.0;
    final overBudget = pctFinanciero > 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Fila superior: Número/check + Nombre + Acciones rápidas
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: allCompleted
                            ? const Color(0xFF16A34A)
                            : AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      alignment: Alignment.center,
                      child: allCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 15,
                            )
                          : Text(
                              '${widget.index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.partida.descripcion,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: allCompleted
                                  ? const Color(0xFF15803D)
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              AppStatusBadge(
                                label:
                                    'Físico: ${avanceFisico.toStringAsFixed(0)}%',
                                type: allCompleted
                                    ? AppStatusType.active
                                    : AppStatusType.info,
                              ),
                              if (totalPresupuestado > 0)
                                AppStatusBadge(
                                  label:
                                      'Fin: ${pctFinanciero.toStringAsFixed(0)}%',
                                  type: overBudget
                                      ? AppStatusType.pending
                                      : AppStatusType.active,
                                ),
                              Text(
                                '${subpartidas.length} ${subpartidas.length == 1 ? 'ítem' : 'ítems'}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ver materiales',
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onOpenMateriales,
                      icon: const Icon(
                        Icons.inventory_2_outlined,
                        size: 18,
                        color: AppTheme.accentColor,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Imprimir partida (PDF)',
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onPrintPdf,
                      icon: const Icon(
                        Icons.print_outlined,
                        size: 18,
                        color: Color(0xFF475569),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Fila financiera compacta (Presupuesto / Real / Diferencia)
                Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _MoneyLabel(
                        label: 'Presup:',
                        value: widget.formatter.format(totalPresupuestado),
                        color: const Color(0xFF16A34A),
                      ),
                      if (costoReal > 0) ...[
                        _MoneyLabel(
                          label: 'Real:',
                          value: widget.formatter.format(costoReal),
                          color: AppTheme.dangerColor,
                        ),
                        _MoneyLabel(
                          label: 'Dif:',
                          value: widget.formatter.format(diferencia),
                          color: diferencia >= 0
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFD97706),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Sub-partidas expandidas
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 36, right: 4, bottom: 10),
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
                    children: subpartidas
                        .map(
                          (sub) => _SubpartidaProgressRow(
                            subpartida: sub,
                            formatter: widget.formatter,
                            canRegisterAvance: widget.canRegisterAvance,
                            onRegisterAvance: () =>
                                widget.onRegisterAvance(sub),
                          ),
                        )
                        .toList(),
                  ),
          ),

        const Divider(height: 1, color: Color(0xFFE2E8F0)),
      ],
    );
  }
}

class _MoneyLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MoneyLabel({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SubpartidaProgressRow extends StatelessWidget {
  final Subpartida subpartida;
  final NumberFormat formatter;
  final bool canRegisterAvance;
  final VoidCallback onRegisterAvance;

  const _SubpartidaProgressRow({
    required this.subpartida,
    required this.formatter,
    required this.canRegisterAvance,
    required this.onRegisterAvance,
  });

  @override
  Widget build(BuildContext context) {
    final avance = subpartida.avanceActual.clamp(0.0, 100.0);
    final isDone = avance >= 100;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subpartida.descripcion,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatter.format(subpartida.totalPresupuestado)} (${subpartida.unidad})',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isDone)
                const AppStatusBadge(
                  label: '100%',
                  type: AppStatusType.active,
                  icon: Icons.check_circle_outline_rounded,
                )
              else if (canRegisterAvance)
                AppButton(
                  text: 'Avance',
                  icon: Icons.trending_up_rounded,
                  size: AppButtonSize.compact,
                  variant: AppButtonVariant.outlined,
                  borderRadius: 8,
                  onPressed: onRegisterAvance,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: avance / 100.0,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDone
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${avance.toInt()}%',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isDone
                      ? const Color(0xFF16A34A)
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
