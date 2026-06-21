import 'package:construccion_erp/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth_provider.dart';
import '../modules/auth/login_screen.dart';

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
    if (widget.selectedIndex >= 0 && widget.selectedIndex <= 4) {
      _expandedSection = '1. GESTIÓN DE PROYECTOS';
    } else if (widget.selectedIndex >= 5 && widget.selectedIndex <= 9) {
      _expandedSection = '2. COMPRAS Y PROVEEDORES';
    } else if (widget.selectedIndex >= 10 && widget.selectedIndex <= 14) {
      _expandedSection = '3. INVENTARIO';
    } else if (widget.selectedIndex >= 15 && widget.selectedIndex <= 19) {
      _expandedSection = '4. CUENTAS POR PAGAR';
    } else if (widget.selectedIndex >= 20 && widget.selectedIndex <= 24) {
      _expandedSection = '5. CUENTAS POR COBRAR';
    } else if (widget.selectedIndex >= 25 && widget.selectedIndex <= 29) {
      _expandedSection = '6. FINANZAS Y CONTABILIDAD';
    } else if (widget.selectedIndex >= 30 && widget.selectedIndex <= 33) {
      _expandedSection = '7. ACTIVOS FIJOS';
    } else if (widget.selectedIndex >= 34 && widget.selectedIndex <= 37) {
      _expandedSection = '8. RECURSOS HUMANOS';
    } else if (widget.selectedIndex >= 38 && widget.selectedIndex <= 42) {
      _expandedSection = '9. CONFIGURACIÓN';
    } else if (widget.selectedIndex >= 43 && widget.selectedIndex <= 46) {
      _expandedSection = '10. REPORTES Y AUDITORÍA';
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
      width: widget.extended ? 280 : 80,
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
        children:
            [
              _buildHeader(accentColor),
              const Divider(color: Colors.white10, height: 1),
              Expanded(
                child:
                    ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      children:
                          [
                            _buildExpansionSection(
                              '1. GESTIÓN DE PROYECTOS',
                              Icons.business_center_outlined,
                              [
                                _buildMenuItem(
                                  0,
                                  Icons.engineering_outlined,
                                  Icons.engineering,
                                  'Planificación de obras',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  1,
                                  Icons.list_alt_outlined,
                                  Icons.list_alt,
                                  'Presupuesto de partidas',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  2,
                                  Icons.analytics_outlined,
                                  Icons.analytics,
                                  'Avance físico-financiero',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  3,
                                  Icons.attach_money_outlined,
                                  Icons.attach_money,
                                  'Control de presupuestos',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  4,
                                  Icons.trending_up_outlined,
                                  Icons.trending_up,
                                  'Reportes de progreso',
                                  accentColor,
                                ),
                              ],
                            ),
                            _buildExpansionSection(
                              '2. COMPRAS Y PROVEEDORES',
                              Icons.shopping_bag_outlined,
                              [
                                _buildMenuItem(
                                  5,
                                  Icons.request_quote_outlined,
                                  Icons.request_quote,
                                  'Solicitudes de compra',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  6,
                                  Icons.add_shopping_cart_outlined,
                                  Icons.add_shopping_cart,
                                  'Registrar compra',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  7,
                                  Icons.contact_phone_outlined,
                                  Icons.contact_phone,
                                  'Proveedores',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  8,
                                  Icons.receipt_long_outlined,
                                  Icons.receipt_long,
                                  'Facturas recibidas',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  9,
                                  Icons.account_balance_wallet_outlined,
                                  Icons.account_balance_wallet,
                                  'Control de ITBIS en compras',
                                  accentColor,
                                ),
                              ],
                            ),
                            _buildExpansionSection(
                              '3. INVENTARIO',
                              Icons.inventory_2_outlined,
                              [
                                _buildMenuItem(
                                  10,
                                  Icons.category_outlined,
                                  Icons.category,
                                  'Materiales de construcción',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  11,
                                  Icons.warehouse_outlined,
                                  Icons.warehouse,
                                  'Inventarios Locales',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  12,
                                  Icons.local_shipping_outlined,
                                  Icons.local_shipping,
                                  'Entradas y salidas',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  13,
                                  Icons.inventory_outlined,
                                  Icons.inventory,
                                  'Kardex y costos promedio',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  14,
                                  Icons.warning_amber_outlined,
                                  Icons.warning_amber,
                                  'Alertas de stock mínimo',
                                  accentColor,
                                ),
                              ],
                            ),
                            _buildExpansionSection(
                              '4. CUENTAS POR PAGAR',
                              Icons.assignment_late_outlined,
                              [
                                _buildMenuItem(
                                  15,
                                  Icons.money_off_outlined,
                                  Icons.money_off,
                                  'Facturas pendientes',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  16,
                                  Icons.payment_outlined,
                                  Icons.payment,
                                  'Anticipos a proveedores',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  17,
                                  Icons.event_available_outlined,
                                  Icons.event_available,
                                  'Pagos programados',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  18,
                                  Icons.request_page_outlined,
                                  Icons.request_page,
                                  'Retenciones fiscales',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  19,
                                  Icons.account_balance_outlined,
                                  Icons.account_balance,
                                  'Conciliación bancaria',
                                  accentColor,
                                ),
                              ],
                            ),
                            _buildExpansionSection(
                              '5. CUENTAS POR COBRAR',
                              Icons.pending_actions_outlined,
                              [
                                _buildMenuItem(
                                  20,
                                  Icons.people_outline,
                                  Icons.people,
                                  'Directorio de clientes',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  22,
                                  Icons.price_check_outlined,
                                  Icons.price_check,
                                  'Cobros parciales por avance',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  23,
                                  Icons.account_box_outlined,
                                  Icons.account_box,
                                  'Cuentas por cobrar',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  24,
                                  Icons.calculate_outlined,
                                  Icons.calculate,
                                  'ITBIS facturado',
                                  accentColor,
                                ),
                              ],
                            ),
                            _buildExpansionSection(
                              '6. FINANZAS Y CONTABILIDAD',
                              Icons.account_balance_outlined,
                              [
                                _buildMenuItem(
                                  25,
                                  Icons.format_list_numbered_outlined,
                                  Icons.format_list_numbered,
                                  'Catálogo contable jerárquico',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  26,
                                  Icons.autorenew_outlined,
                                  Icons.autorenew,
                                  'Asientos automáticos',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  27,
                                  Icons.bar_chart_outlined,
                                  Icons.bar_chart,
                                  'Estados financieros',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  28,
                                  Icons.gavel_outlined,
                                  Icons.gavel,
                                  'Obligaciones fiscales',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  29,
                                  Icons.lock_clock_outlined,
                                  Icons.lock_clock,
                                  'Conciliaciones y cierres contables',
                                  accentColor,
                                ),
                              ],
                            ),
                            _buildExpansionSection(
                              '7. ACTIVOS FIJOS',
                              Icons.precision_manufacturing_outlined,
                              [
                                _buildMenuItem(
                                  30,
                                  Icons.computer_outlined,
                                  Icons.computer,
                                  'Registro de equipos',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  31,
                                  Icons.trending_down_outlined,
                                  Icons.trending_down,
                                  'Depreciación',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  32,
                                  Icons.build_outlined,
                                  Icons.build,
                                  'Mantenimiento',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  33,
                                  Icons.swap_horiz_outlined,
                                  Icons.swap_horiz,
                                  'Transferencias',
                                  accentColor,
                                ),
                              ],
                            ),
                            _buildExpansionSection(
                              '8. RECURSOS HUMANOS',
                              Icons.people_outline,
                              [
                                _buildMenuItem(
                                  34,
                                  Icons.badge_outlined,
                                  Icons.badge,
                                  'Nómina de empleados',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  35,
                                  Icons.description_outlined,
                                  Icons.description,
                                  'Contratos de obra',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  36,
                                  Icons.access_time_outlined,
                                  Icons.access_time,
                                  'Asistencia',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  37,
                                  Icons.health_and_safety_outlined,
                                  Icons.health_and_safety,
                                  'Retenciones SS',
                                  accentColor,
                                ),
                              ],
                            ),
                            _buildExpansionSection(
                              '9. CONFIGURACIÓN',
                              Icons.settings_outlined,
                              [
                                _buildMenuItem(
                                  38,
                                  Icons.settings_applications_outlined,
                                  Icons.settings_applications,
                                  'Parametrización',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  39,
                                  Icons.account_tree_outlined,
                                  Icons.account_tree,
                                  'Catálogo de cuentas',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  40,
                                  Icons.admin_panel_settings_outlined,
                                  Icons.admin_panel_settings,
                                  'Roles y permisos',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  41,
                                  Icons.api_outlined,
                                  Icons.api,
                                  'Integraciones',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  42,
                                  Icons.settings_suggest_outlined,
                                  Icons.settings_suggest,
                                  'Ajustes Generales',
                                  accentColor,
                                ),
                              ],
                            ),
                            _buildExpansionSection(
                              '10. REPORTES Y AUDITORÍA',
                              Icons.assessment_outlined,
                              [
                                _buildMenuItem(
                                  43,
                                  Icons.insert_chart_outlined,
                                  Icons.insert_chart,
                                  'Reportes de avance',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  44,
                                  Icons.pie_chart_outline,
                                  Icons.pie_chart,
                                  'Estado de cuentas',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  45,
                                  Icons.fact_check_outlined,
                                  Icons.fact_check,
                                  'Auditoría',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  46,
                                  Icons.picture_as_pdf_outlined,
                                  Icons.picture_as_pdf,
                                  'Exportación',
                                  accentColor,
                                ),
                              ],
                            ),
                          ],
                    ),
              ),
              const Divider(color: Colors.white10, height: 1),
              _buildLogoutButton(accentColor),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isExpanded
              ? Colors.black.withValues(alpha: 0.25)
              : Colors.transparent,
        ),
        child: ExpansionTile(
          key: Key('${title}_$isExpanded'),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) => _handleExpansion(title, expanded),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: Icon(
            icon,
            color: isExpanded
                ? Colors.white
                : Colors.white.withValues(alpha: 0.4),
            size: 20,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isExpanded
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          trailing: Icon(
            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: Colors.white24,
            size: 18,
          ),
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(left: 16, bottom: 8),
              padding: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: const Color(0xFFE31E24).withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
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
                      fontSize: 12,
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

  Widget _buildLogoutButton(Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: const Color(0xFF2C2F33),
                title: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  '¿Está seguro de que desea salir del sistema?',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).logout();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                    ),
                    child: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: widget.extended
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout_outlined,
                color: Colors.white70,
                size: 20,
              ),
              if (widget.extended) ...[
                const SizedBox(width: 12),
                const Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
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
