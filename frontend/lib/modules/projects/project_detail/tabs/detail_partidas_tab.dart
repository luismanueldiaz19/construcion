import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/constants.dart';
import '../../../../models/partida.dart';
import '../../../../models/subpartida.dart';
import '../../../../widgets/app_alert.dart';
import '../../../../widgets/app_empty_state.dart';
import '../dialogs/partida_materiales_sheet.dart';
import '../dialogs/registrar_avance_dialog.dart';
import '../providers/project_detail_provider.dart';
import '../widgets/detail_partida_item.dart';

/// Pestaña 2 (Partidas): KPIs compactos, filtro por estado y lista expandible integrada.
class DetailPartidasTab extends StatefulWidget {
  const DetailPartidasTab({super.key});

  @override
  State<DetailPartidasTab> createState() => _DetailPartidasTabState();
}

class _DetailPartidasTabState extends State<DetailPartidasTab> {
  String _filter = 'Todas';

  String _estadoPartida(Partida p) {
    final subs = p.subpartidas;
    if (subs.isEmpty) return 'Pendientes';
    if (subs.every((s) => s.avanceActual >= 100)) return 'Completadas';
    if (subs.every((s) => s.avanceActual == 0)) return 'Pendientes';
    return 'En Proceso';
  }

  Future<void> _openPdf(BuildContext context, Partida partida) async {
    if (partida.id == null) return;
    final url = Uri.parse('$host/reports/partida/${partida.id}/pdf');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else if (context.mounted) {
      AppAlert.showToast(
        context,
        'No se pudo abrir el PDF de la partida.',
        type: AppAlertType.error,
      );
    }
  }

  Future<void> _handleRegisterAvance(
    BuildContext context,
    ProjectDetailProvider provider,
    Subpartida sub,
  ) async {
    final nuevoAvance = await RegistrarAvanceDialog.show(context, sub);
    if (nuevoAvance == null) return;

    try {
      await provider.registrarAvance(sub, nuevoAvance);
      if (context.mounted) {
        AppAlert.showToast(
          context,
          'Avance actualizado a ${nuevoAvance.toInt()}%.',
          type: AppAlertType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppAlert.showToast(
          context,
          'Error al registrar avance: $e',
          type: AppAlertType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectDetailProvider>();
    final proyecto = provider.proyecto!;
    final partidas = proyecto.partidas;
    final currencyFmt = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);

    int completadas = 0;
    int enProceso = 0;
    int pendientes = 0;
    for (final p in partidas) {
      final st = _estadoPartida(p);
      if (st == 'Completadas') {
        completadas++;
      } else if (st == 'En Proceso') {
        enProceso++;
      } else {
        pendientes++;
      }
    }

    final filtered = _filter == 'Todas'
        ? partidas
        : partidas.where((p) => _estadoPartida(p) == _filter).toList();

    final canRegisterAvance = proyecto.estado == 'Activo';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPIs compactos superiores
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                label: 'Total',
                value: '${partidas.length}',
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _MiniStat(
                label: 'Completadas',
                value: '$completadas',
                color: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _MiniStat(
                label: 'En Proceso',
                value: '$enProceso',
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _MiniStat(
                label: 'Pendientes',
                value: '$pendientes',
                color: const Color(0xFFD97706),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Filtros rápidos horizontales
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Todas', 'En Proceso', 'Pendientes', 'Completadas']
                .map((f) {
              final selected = _filter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => setState(() => _filter = f),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primaryColor
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primaryColor
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.w500,
                        color:
                            selected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 18, color: Color(0xFFE2E8F0)),

        // Encabezado de lista
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Estructura de Costos y Avance',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              currencyFmt.format(provider.presupuestoTotal),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF16A34A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        if (filtered.isEmpty)
          AppEmptyState(
            icon: Icons.construction_outlined,
            title: _filter == 'Todas'
                ? 'No hay partidas registradas'
                : 'Sin partidas en "$_filter"',
            description: _filter == 'Todas'
                ? 'Este proyecto aún no tiene partidas cargadas.'
                : 'Prueba cambiando el filtro para ver las demás partidas.',
          )
        else
          ...filtered.asMap().entries.map((entry) {
            final p = entry.value;
            final originalIndex = partidas.indexOf(p);
            return DetailPartidaItem(
              index: originalIndex >= 0 ? originalIndex : entry.key,
              partida: p,
              costoReal: provider.costoRealDePartida(p),
              canRegisterAvance: canRegisterAvance,
              formatter: currencyFmt,
              onOpenMateriales: () => PartidaMaterialesSheet.show(
                context,
                partida: p,
                provider: provider,
              ),
              onPrintPdf: () => _openPdf(context, p),
              onRegisterAvance: (sub) =>
                  _handleRegisterAvance(context, provider, sub),
            );
          }),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
