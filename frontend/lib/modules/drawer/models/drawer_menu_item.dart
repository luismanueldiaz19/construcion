import 'package:flutter/material.dart';

/// Representa un elemento o pantalla final dentro de un módulo del drawer.
class DrawerSubItem {
  final int index;
  final String title;
  final IconData icon;
  final IconData? activeIcon;
  final String? badge;

  const DrawerSubItem({
    required this.index,
    required this.title,
    required this.icon,
    this.activeIcon,
    this.badge,
  });
}

/// Representa una sección o módulo desplegable dentro del drawer.
class DrawerSection {
  final String id;
  final String title;
  final IconData icon;
  final List<DrawerSubItem> items;

  const DrawerSection({
    required this.id,
    required this.title,
    required this.icon,
    required this.items,
  });

  /// Catálogo estándar completo de todas las secciones del ERP.
  static List<DrawerSection> getDefaultSections() {
    return const [
      DrawerSection(
        id: 'proyectos',
        title: '1. GESTIÓN DE PROYECTOS',
        icon: Icons.business_center_outlined,
        items: [
          DrawerSubItem(
            index: 0,
            title: 'Proyectos',
            icon: Icons.engineering_outlined,
            activeIcon: Icons.engineering,
          ),
          DrawerSubItem(
            index: 4,
            title: 'Historial de Proyectos',
            icon: Icons.history_outlined,
            activeIcon: Icons.history,
          ),
        ],
      ),
      DrawerSection(
        id: 'compras',
        title: '2. COMPRAS Y PROVEEDORES',
        icon: Icons.shopping_bag_outlined,
        items: [
          DrawerSubItem(
            index: 5,
            title: 'Solicitudes de compra',
            icon: Icons.request_quote_outlined,
            activeIcon: Icons.request_quote,
          ),
          DrawerSubItem(
            index: 6,
            title: 'Registrar compra',
            icon: Icons.add_shopping_cart_outlined,
            activeIcon: Icons.add_shopping_cart,
          ),
          DrawerSubItem(
            index: 7,
            title: 'Proveedores',
            icon: Icons.contact_phone_outlined,
            activeIcon: Icons.contact_phone,
          ),
          DrawerSubItem(
            index: 8,
            title: 'Facturas recibidas',
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long,
          ),
          DrawerSubItem(
            index: 9,
            title: 'Control de ITBIS en compras',
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet,
          ),
        ],
      ),
      DrawerSection(
        id: 'inventario',
        title: '3. INVENTARIO',
        icon: Icons.inventory_2_outlined,
        items: [
          DrawerSubItem(
            index: 10,
            title: 'Materiales de construcción',
            icon: Icons.category_outlined,
            activeIcon: Icons.category,
          ),
          DrawerSubItem(
            index: 11,
            title: 'Inventarios Locales',
            icon: Icons.warehouse_outlined,
            activeIcon: Icons.warehouse,
          ),
          DrawerSubItem(
            index: 12,
            title: 'Recepción de materiales',
            icon: Icons.move_to_inbox_outlined,
            activeIcon: Icons.move_to_inbox,
          ),
          DrawerSubItem(
            index: 13,
            title: 'Inventarios',
            icon: Icons.inventory_outlined,
            activeIcon: Icons.inventory,
          ),
        ],
      ),
      DrawerSection(
        id: 'cxp',
        title: '4. CUENTAS POR PAGAR',
        icon: Icons.assignment_late_outlined,
        items: [
          DrawerSubItem(
            index: 15,
            title: 'Facturas pendientes',
            icon: Icons.money_off_outlined,
            activeIcon: Icons.money_off,
          ),
          DrawerSubItem(
            index: 16,
            title: 'Anticipos a proveedores',
            icon: Icons.payment_outlined,
            activeIcon: Icons.payment,
          ),
          DrawerSubItem(
            index: 17,
            title: 'Historial de Pagos (Gastos)',
            icon: Icons.outbound_outlined,
            activeIcon: Icons.outbound,
          ),
          DrawerSubItem(
            index: 18,
            title: 'Retenciones fiscales',
            icon: Icons.request_page_outlined,
            activeIcon: Icons.request_page,
          ),
          DrawerSubItem(
            index: 19,
            title: 'Conciliación bancaria',
            icon: Icons.account_balance_outlined,
            activeIcon: Icons.account_balance,
          ),
        ],
      ),
      DrawerSection(
        id: 'cxc',
        title: '5. CUENTAS POR COBRAR',
        icon: Icons.pending_actions_outlined,
        items: [
          DrawerSubItem(
            index: 20,
            title: 'Directorio de clientes',
            icon: Icons.people_outline,
            activeIcon: Icons.people,
          ),
          DrawerSubItem(
            index: 22,
            title: 'Historial de Cobros (Ingresos)',
            icon: Icons.move_to_inbox_outlined,
            activeIcon: Icons.move_to_inbox,
          ),
          DrawerSubItem(
            index: 23,
            title: 'Cuentas por cobrar',
            icon: Icons.account_box_outlined,
            activeIcon: Icons.account_box,
          ),
          DrawerSubItem(
            index: 24,
            title: 'ITBIS facturado',
            icon: Icons.calculate_outlined,
            activeIcon: Icons.calculate,
          ),
        ],
      ),
      DrawerSection(
        id: 'finanzas',
        title: '6. FINANZAS Y CONTABILIDAD',
        icon: Icons.account_balance_outlined,
        items: [
          DrawerSubItem(
            index: 25,
            title: 'Catálogo de Cuentas',
            icon: Icons.format_list_numbered_outlined,
            activeIcon: Icons.format_list_numbered,
          ),
          DrawerSubItem(
            index: 26,
            title: 'Libro Diario',
            icon: Icons.menu_book_outlined,
            activeIcon: Icons.menu_book,
          ),
          DrawerSubItem(
            index: 27,
            title: 'Estado de Resultados',
            icon: Icons.bar_chart_outlined,
            activeIcon: Icons.bar_chart,
          ),
          DrawerSubItem(
            index: 28,
            title: 'Obligaciones fiscales',
            icon: Icons.gavel_outlined,
            activeIcon: Icons.gavel,
          ),
          DrawerSubItem(
            index: 29,
            title: 'Conciliaciones y cierres contables',
            icon: Icons.lock_clock_outlined,
            activeIcon: Icons.lock_clock,
          ),
        ],
      ),
      DrawerSection(
        id: 'activos',
        title: '7. ACTIVOS FIJOS',
        icon: Icons.precision_manufacturing_outlined,
        items: [
          DrawerSubItem(
            index: 30,
            title: 'Registro de equipos',
            icon: Icons.computer_outlined,
            activeIcon: Icons.computer,
          ),
          DrawerSubItem(
            index: 31,
            title: 'Depreciación',
            icon: Icons.trending_down_outlined,
            activeIcon: Icons.trending_down,
          ),
          DrawerSubItem(
            index: 32,
            title: 'Mantenimiento',
            icon: Icons.build_outlined,
            activeIcon: Icons.build,
          ),
          DrawerSubItem(
            index: 33,
            title: 'Transferencias',
            icon: Icons.swap_horiz_outlined,
            activeIcon: Icons.swap_horiz,
          ),
        ],
      ),
      DrawerSection(
        id: 'rrhh',
        title: '8. RECURSOS HUMANOS',
        icon: Icons.people_outline,
        items: [
          DrawerSubItem(
            index: 34,
            title: 'Empleados',
            icon: Icons.badge_outlined,
            activeIcon: Icons.badge,
          ),
          DrawerSubItem(
            index: 35,
            title: 'Gestión de Nómina',
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long,
          ),
          DrawerSubItem(
            index: 36,
            title: 'Asistencia',
            icon: Icons.access_time_outlined,
            activeIcon: Icons.access_time,
          ),
          DrawerSubItem(
            index: 37,
            title: 'Retenciones SS',
            icon: Icons.health_and_safety_outlined,
            activeIcon: Icons.health_and_safety,
          ),
        ],
      ),
      DrawerSection(
        id: 'configuracion',
        title: '9. CONFIGURACIÓN',
        icon: Icons.settings_outlined,
        items: [
          DrawerSubItem(
            index: 38,
            title: 'Parametrización',
            icon: Icons.settings_applications_outlined,
            activeIcon: Icons.settings_applications,
          ),
          DrawerSubItem(
            index: 39,
            title: 'Catálogo de cuentas',
            icon: Icons.account_tree_outlined,
            activeIcon: Icons.account_tree,
          ),
          DrawerSubItem(
            index: 40,
            title: 'Roles y permisos',
            icon: Icons.admin_panel_settings_outlined,
            activeIcon: Icons.admin_panel_settings,
          ),
          DrawerSubItem(
            index: 41,
            title: 'Integraciones',
            icon: Icons.api_outlined,
            activeIcon: Icons.api,
          ),
          DrawerSubItem(
            index: 42,
            title: 'Ajustes Generales',
            icon: Icons.settings_suggest_outlined,
            activeIcon: Icons.settings_suggest,
          ),
          DrawerSubItem(
            index: 47,
            title: 'Cargos y Departamentos',
            icon: Icons.business_outlined,
            activeIcon: Icons.business,
          ),
        ],
      ),
      DrawerSection(
        id: 'reportes',
        title: '10. REPORTES Y AUDITORÍA',
        icon: Icons.assessment_outlined,
        items: [
          DrawerSubItem(
            index: 43,
            title: 'Reportes de avance',
            icon: Icons.insert_chart_outlined,
            activeIcon: Icons.insert_chart,
          ),
          DrawerSubItem(
            index: 44,
            title: 'Auditoría de cambios',
            icon: Icons.pie_chart_outline,
            activeIcon: Icons.pie_chart,
          ),
          DrawerSubItem(
            index: 45,
            title: 'Reportes financieros',
            icon: Icons.analytics_outlined,
            activeIcon: Icons.analytics,
          ),
          DrawerSubItem(
            index: 46,
            title: 'Exportación',
            icon: Icons.picture_as_pdf_outlined,
            activeIcon: Icons.picture_as_pdf,
          ),
        ],
      ),
      DrawerSection(
        id: 'ledhouse',
        title: '11. LED-HOUSE',
        icon: Icons.lightbulb_outline,
        items: [
          DrawerSubItem(
            index: 48,
            title: 'Estado de Resultado',
            icon: Icons.bar_chart_outlined,
            activeIcon: Icons.bar_chart,
          ),
          DrawerSubItem(
            index: 49,
            title: 'Cuentas por Cobrar',
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet,
          ),
          DrawerSubItem(
            index: 50,
            title: 'Cuentas por Pagar',
            icon: Icons.money_off_outlined,
            activeIcon: Icons.money_off,
          ),
          DrawerSubItem(
            index: 51,
            title: 'Catálogo de Cuentas',
            icon: Icons.list_alt_outlined,
            activeIcon: Icons.list_alt,
          ),
          DrawerSubItem(
            index: 52,
            title: 'Clientes Ledhouse',
            icon: Icons.people_outline,
            activeIcon: Icons.people,
          ),
        ],
      ),
    ];
  }
}
