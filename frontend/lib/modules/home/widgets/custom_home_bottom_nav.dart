import 'package:flutter/material.dart';

/// Elemento de navegación para el CustomHomeBottomNav.
class HomeNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const HomeNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

/// Barra de navegación inferior ultra-compacta y estilizada con indicador superior rojo.
/// Diseñada con base en el mockup de UX Pilot (Inicio, Proyectos, Clientes, CXC, Más).
class CustomHomeBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<HomeNavItem> items;

  const CustomHomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x06000000),
            offset: Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = currentIndex == index;
              final iconData = (isSelected && item.activeIcon != null)
                  ? item.activeIcon!
                  : item.icon;

              const activeColor = Color(0xFFE31E24);
              const inactiveColor = Color(0xFF64748B);

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  splashColor: activeColor.withValues(alpha: 0.08),
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Indicador superior rojo en la pestaña activa
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSelected ? 32 : 0,
                        height: 3,
                        decoration: BoxDecoration(
                          color: isSelected ? activeColor : Colors.transparent,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(3),
                          ),
                        ),
                      ),

                      // Icono y Etiqueta
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              iconData,
                              size: 21,
                              color: isSelected ? activeColor : inactiveColor,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected ? activeColor : inactiveColor,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
