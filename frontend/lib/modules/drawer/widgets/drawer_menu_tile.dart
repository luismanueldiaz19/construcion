import 'package:flutter/material.dart';
import '../models/drawer_menu_item.dart';

/// Elemento interactivo de submenú dentro del drawer.
/// Resalta en rojo corporativo (#E31E24) cuando está seleccionado.
class DrawerMenuTile extends StatefulWidget {
  final DrawerSubItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const DrawerMenuTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<DrawerMenuTile> createState() => _DrawerMenuTileState();
}

class _DrawerMenuTileState extends State<DrawerMenuTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFE31E24);
    const normalColor = Color(0xFF94A3B8);
    const hoverBg = Color(0xFF1E293B);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1.5),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? activeColor.withValues(alpha: 0.12)
              : (_isHovered ? hoverBg : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Icono
                Icon(
                  widget.isSelected && widget.item.activeIcon != null
                      ? widget.item.activeIcon
                      : widget.item.icon,
                  size: 16.5,
                  color: widget.isSelected ? activeColor : normalColor,
                ),
                const SizedBox(width: 10),

                // Título
                Expanded(
                  child: Text(
                    widget.item.title,
                    style: TextStyle(
                      color: widget.isSelected ? Colors.white : normalColor,
                      fontSize: 11.5,
                      fontWeight: widget.isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Indicador de barra roja activo en el extremo derecho
                if (widget.isSelected)
                  Container(
                    width: 3.5,
                    height: 16,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
