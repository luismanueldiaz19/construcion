import 'package:flutter/material.dart';
import '../models/drawer_menu_item.dart';
import 'drawer_menu_tile.dart';

/// Sección o módulo desplegable con animación suave de apertura/cierre.
class DrawerExpansionSection extends StatelessWidget {
  final DrawerSection section;
  final bool isExpanded;
  final int selectedIndex;
  final ValueChanged<bool> onExpansionChanged;
  final ValueChanged<int> onItemSelected;

  const DrawerExpansionSection({
    super.key,
    required this.section,
    required this.isExpanded,
    required this.selectedIndex,
    required this.onExpansionChanged,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Si algún hijo está seleccionado, la sección resalta sutilmente
    final hasActiveChild = section.items.any((item) => item.index == selectedIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cabecera del módulo desplegable
        InkWell(
          onTap: () => onExpansionChanged(!isExpanded),
          splashColor: Colors.white.withValues(alpha: 0.04),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
            child: Row(
              children: [
                Icon(
                  section.icon,
                  size: 17,
                  color: hasActiveChild
                      ? const Color(0xFFE31E24)
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    section.title,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      color: hasActiveChild
                          ? Colors.white
                          : const Color(0xFF94A3B8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0.0, // Rota 90 grados hacia abajo
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Subitems animados
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: section.items.map((item) {
                return DrawerMenuTile(
                  item: item,
                  isSelected: item.index == selectedIndex,
                  onTap: () => onItemSelected(item.index),
                );
              }).toList(),
            ),
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
      ],
    );
  }
}
