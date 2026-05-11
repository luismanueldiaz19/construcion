import 'package:construccion_erp/core/constants.dart';
import 'package:flutter/material.dart';

class CustomSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final bool extended;

  const CustomSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.extended = true,
  });

  @override
  State<CustomSidebar> createState() => _CustomSidebarState();
}

class _CustomSidebarState extends State<CustomSidebar> {
  String? _expandedSection;

  @override
  void initState() {
    super.initState();
    _updateExpandedSection();
  }

  @override
  void didUpdateWidget(CustomSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _updateExpandedSection();
    }
  }

  void _updateExpandedSection() {
    // Determine which section should be open based on selectedIndex
    if (widget.selectedIndex >= 0 && widget.selectedIndex <= 2) {
      _expandedSection = 'GESTIÓN';
    } else if ((widget.selectedIndex >= 3 && widget.selectedIndex <= 6) ||
        widget.selectedIndex == 9) {
      _expandedSection = 'INVENTARIO';
    } else if (widget.selectedIndex >= 10 && widget.selectedIndex <= 13) {
      _expandedSection = 'FINANZAS';
    } else if (widget.selectedIndex == 7 || widget.selectedIndex == 8) {
      _expandedSection = 'REPORTES';
    } else if (widget.selectedIndex == 14) {
      _expandedSection = 'SISTEMA';
    }
  }

  void _handleExpansion(String section, bool expanded) {
    setState(() {
      if (expanded) {
        _expandedSection = section;
      } else if (_expandedSection == section) {
        _expandedSection = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1A1C1E); // Dark Grey
    final accentColor = const Color(0xFFE31E24); // Red
    final secondaryColor = const Color(0xFF2C2F33); // Lighter Grey

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: widget.extended ? 260 : 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primaryColor, secondaryColor],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(accentColor),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildExpansionSection(
                  'GESTIÓN',
                  Icons.business_center_outlined,
                  [
                    _buildMenuItem(
                      0,
                      Icons.dashboard_outlined,
                      Icons.dashboard,
                      'Dashboard',
                      accentColor,
                    ),
                    _buildMenuItem(
                      1,
                      Icons.business_outlined,
                      Icons.business,
                      'Proyectos',
                      accentColor,
                    ),
                    _buildMenuItem(
                      2,
                      Icons.calendar_today_outlined,
                      Icons.calendar_today,
                      'Historial Proyectos',
                      accentColor,
                    ),
                  ],
                ),
                _buildExpansionSection(
                  'INVENTARIO',
                  Icons.inventory_2_outlined,
                  [
                    _buildMenuItem(
                      3,
                      Icons.people_outline,
                      Icons.people,
                      'Proveedores',
                      accentColor,
                    ),
                    _buildMenuItem(
                      4,
                      Icons.inventory_outlined,
                      Icons.inventory,
                      'Productos',
                      accentColor,
                    ),
                    _buildMenuItem(
                      5,
                      Icons.add_shopping_cart_outlined,
                      Icons.add_shopping_cart,
                      'Nueva Compra',
                      accentColor,
                    ),
                    _buildMenuItem(
                      6,
                      Icons.local_shipping_outlined,
                      Icons.local_shipping,
                      'Recepción',
                      accentColor,
                    ),
                    _buildMenuItem(
                      9,
                      Icons.storage_outlined,
                      Icons.storage,
                      'Inventario Proy.',
                      accentColor,
                    ),
                  ],
                ),
                _buildExpansionSection(
                  'FINANZAS',
                  Icons.account_balance_wallet_outlined,
                  [
                    _buildMenuItem(
                      10,
                      Icons.money_off_outlined,
                      Icons.money_off,
                      'Cuentas por Pagar',
                      accentColor,
                    ),
                    _buildMenuItem(
                      11,
                      Icons.pending_actions_outlined,
                      Icons.pending_actions,
                      'Cuentas por Cobrar',
                      accentColor,
                    ),
                    _buildMenuItem(
                      12,
                      Icons.history_outlined,
                      Icons.history,
                      'Historial de Pagos',
                      accentColor,
                    ),
                    _buildMenuItem(
                      13,
                      Icons.account_balance_outlined,
                      Icons.account_balance,
                      'Contabilidad',
                      accentColor,
                    ),
                  ],
                ),
                _buildExpansionSection('REPORTES', Icons.bar_chart_outlined, [
                  _buildMenuItem(
                    7,
                    Icons.shopping_cart_outlined,
                    Icons.shopping_cart,
                    'Compras',
                    accentColor,
                  ),
                  _buildMenuItem(
                    8,
                    Icons.receipt_long_outlined,
                    Icons.receipt_long,
                    'Gastos',
                    accentColor,
                  ),
                ]),
                _buildExpansionSection('SISTEMA', Icons.settings_outlined, [
                  _buildMenuItem(
                    14,
                    Icons.settings_outlined,
                    Icons.settings,
                    'Configuración',
                    accentColor,
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionSection(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    final bool isExpanded = _expandedSection == title;

    if (!widget.extended) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Icon(icon, color: Colors.white24, size: 20),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        hoverColor: Colors.white.withValues(alpha: 0.05),
      ),
      child: ExpansionTile(
        key: Key('${title}_$isExpanded'),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) => _handleExpansion(title, expanded),
        leading: Icon(
          icon,
          color: isExpanded
              ? Colors.white
              : Colors.white.withValues(alpha: 0.4),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isExpanded
                ? Colors.white
                : Colors.white.withValues(alpha: 0.4),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        trailing: Icon(
          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: Colors.white24,
          size: 18,
        ),
        children: children,
      ),
    );
  }

  Widget _buildHeader(Color accentColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: widget.extended ? 120 : 80,
      padding: EdgeInsets.symmetric(vertical: widget.extended ? 20 : 10),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: Image.asset(
          logoPath,
          key: ValueKey(widget.extended),
          color: Colors.white,
          height: widget.extended ? 80 : 40,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
    Color accentColor,
  ) {
    final isSelected = widget.selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: () => widget.onDestinationSelected(index),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(
                    color: accentColor.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected
                    ? accentColor
                    : Colors.white.withValues(alpha: 0.6),
                size: 20,
              ),
              if (widget.extended) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.6),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 14,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
