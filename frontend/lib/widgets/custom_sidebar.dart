import 'package:construccion_erp/core/constants.dart';
import 'package:flutter/material.dart';

class CustomSidebar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1A1C1E); // Dark Grey from logo
    final accentColor = const Color(0xFFE31E24); // Red from logo

    return Container(
      width: extended ? 260 : 80,
      decoration: BoxDecoration(
        color: primaryColor,
        border: Border(
          right: BorderSide(color: Colors.black.withOpacity(0.3), width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(accentColor),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildSectionHeader('GESTIÓN', extended),
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

                _buildSectionHeader('INVENTARIO', extended),
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
                  Icons.inventory_2_outlined,
                  Icons.inventory_2,
                  'Inventario Proy.',
                  accentColor,
                ),

                _buildSectionHeader('FINANZAS', extended),
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

                _buildSectionHeader('REPORTES', extended),
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

                _buildSectionHeader('SISTEMA', extended),
                _buildMenuItem(
                  14,
                  Icons.settings_outlined,
                  Icons.settings,
                  'Configuración',
                  accentColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color accentColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: extended ? 150 : 80, // El cabezal también crece un poco
      padding: EdgeInsets.symmetric(vertical: extended ? 20 : 10),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: Image.asset(
          logoPath,
          key: ValueKey<bool>(
            extended,
          ), // Necesario para que AnimatedSwitcher detecte el cambio
          color: Colors.white,
          height: extended
              ? 100
              : 40, // Ajustado a tamaños más reales para el contenedor
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool visible) {
    if (!visible) return const SizedBox(height: 16);
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 20, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(0.4),
          letterSpacing: 1.1,
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
    final isSelected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: () => onDestinationSelected(index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? accentColor : Colors.white.withOpacity(0.7),
                size: 22,
              ),
              if (extended) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
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
