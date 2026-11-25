import 'package:flutter/material.dart';
import '../../../../core/app_theme.dart';

/// Definición de cada pestaña de navegación del detalle de proyecto.
class ProjectDetailTabItem {
  final String label;
  final IconData icon;

  const ProjectDetailTabItem({required this.label, required this.icon});
}

/// Barra horizontal compacta con scroll para navegar entre las secciones del proyecto.
class ProjectDetailTabBar extends StatelessWidget {
  final int activeIndex;
  final List<ProjectDetailTabItem> tabs;
  final ValueChanged<int> onTabSelected;

  const ProjectDetailTabBar({
    super.key,
    required this.activeIndex,
    required this.tabs,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final tab = tabs[index];
            final isSelected = index == activeIndex;

            return Padding(
              padding: EdgeInsets.only(right: index < tabs.length - 1 ? 6 : 0),
              child: InkWell(
                onTap: () => onTabSelected(index),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentColor
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accentColor
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: 14,
                        color:
                            isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
