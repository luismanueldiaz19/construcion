import 'package:flutter/material.dart';
import '../../../widgets/app_header_bar.dart';
import '../../drawer/app_navigation_drawer.dart';
import '../widgets/custom_home_bottom_nav.dart';
import 'home_proyectos_screen.dart';
import 'home_clientes_screen.dart';
import 'home_inventario_screen.dart';
import 'home_cxc_screen.dart';
import 'home_mas_screen.dart';

// Módulo LED-HOUSE
import '../../led_house/screens/ledhouse_detalles_screen.dart';
import '../../led_house/cxc/screens/cxc_screen.dart';
import '../../led_house/cxp/screens/cxp_screen.dart';
import '../../led_house/screens/cuenta_catalogo_screen.dart';
import '../../led_house/screens/clientes/ledhouse_clientes_screen.dart';

// Módulos ERP completos
import '../../projects/historial_proyectos_screen.dart';
import '../../purchases/screens/purchase_form_screen.dart';
import '../../purchases/screens/compras_report_screen.dart';
import '../../suppliers/screens/suppliers_screen.dart';
import '../../inventory/local_inventories_screen.dart';
import '../../inventory/reception_screen.dart';
import '../../inventory/inventory_screen.dart';
import '../../accounting/cuentas_por_pagar_screen.dart';
import '../../payments/payments_screen.dart';
import '../../payments/cobros_screen.dart';
import '../../accounting/catalog_screen.dart';
import '../../accounting/journal_screen.dart';
import '../../accounting/profit_loss_screen.dart';
import '../../accounting/screens/obligaciones_screen.dart';
import '../../accounting/screens/conciliaciones_screen.dart';
import '../../assets/presentation/assets_screen.dart';
import '../../nomina/screens/employees_screen.dart';
import '../../nomina/screens/payroll_dashboard_screen.dart';
import '../../nomina/screens/nomina_exports_screen.dart';
import '../../nomina/screens/nomina_catalogs_screen.dart';
import '../../users/users_screen.dart';
import '../../settings/settings_screen.dart';
import '../../reports/gastos_report_screen.dart';

class _TabMeta {
  final String title;
  final String subtitle;
  final String badgeLetter;

  const _TabMeta({
    required this.title,
    required this.subtitle,
    required this.badgeLetter,
  });
}

/// Pantalla principal Home que administra la cabecera unificada (AppHeaderBar),
/// la barra de navegación inferior (BottomNav) y el nuevo Drawer de navegación lateral.
class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _currentIndex;
  int _drawerSelectedIndex = 0;

  final List<Widget> _pages = const [
    HomeProyectosScreen(),
    HomeClientesScreen(),
    HomeInventarioScreen(),
    HomeCxcScreen(),
    HomeMasScreen(),
  ];

  static const List<_TabMeta> _tabMetas = [
    _TabMeta(
      title: 'NEO PROJECT',
      subtitle: 'Gestión y control de obras',
      badgeLetter: 'P',
    ),
    _TabMeta(
      title: 'CLIENTES',
      subtitle: 'Directorio y gestión de cuentas',
      badgeLetter: 'C',
    ),
    _TabMeta(
      title: 'INVENTARIO',
      subtitle: 'Materiales, almacenes y stock de obra',
      badgeLetter: 'I',
    ),
    _TabMeta(
      title: 'CUENTAS POR COBRAR',
      subtitle: 'Control de cobros y facturas a clientes',
      badgeLetter: 'C',
    ),
    _TabMeta(
      title: 'MÁS MÓDULOS',
      subtitle: 'Configuración y utilidades del ERP',
      badgeLetter: 'M',
    ),
  ];

  static const List<HomeNavItem> _navItems = [
    HomeNavItem(
      icon: Icons.engineering_outlined,
      activeIcon: Icons.engineering_rounded,
      label: 'Proyectos',
    ),
    HomeNavItem(
      icon: Icons.contact_phone_outlined,
      activeIcon: Icons.contact_phone_rounded,
      label: 'Clientes',
    ),
    HomeNavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      label: 'Inventario',
    ),
    HomeNavItem(
      icon: Icons.request_quote_outlined,
      activeIcon: Icons.request_quote_rounded,
      label: 'CXC',
    ),
    HomeNavItem(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Más',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _onTabTapped(int index) {
    if (index == 4) {
      // Al presionar la pestaña "Más", abre de inmediato el nuevo AppNavigationDrawer
      _openDrawer();
      return;
    }
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _handleDrawerNavigation(int index) {
    // Cerrar el drawer
    _scaffoldKey.currentState?.closeDrawer();

    setState(() {
      _drawerSelectedIndex = index;
    });

    // Mapeo con los tabs principales del Home
    if (index == 0) {
      // Proyectos
      _onTabTapped(0);
    } else if (index == 20) {
      // Directorio de Clientes
      _onTabTapped(1);
    } else if (index == 10) {
      // Materiales de construcción (Inventario)
      _onTabTapped(2);
    } else if (index == 23) {
      // Cuentas por Cobrar
      _onTabTapped(3);
    } else {
      // Navegación fluida a pantallas especializadas (incluyendo módulo LED HOUSE)
      final Widget? screen = _getScreenForIndex(index);
      if (screen != null) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Módulo en desarrollo (código #$index)'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1500),
          ),
        );
      }
    }
  }

  Widget? _getScreenForIndex(int index) {
    switch (index) {
      // 1. Gestión de Proyectos
      case 4:
        return const HistorialProyectosScreen();

      // 2. Compras y Proveedores
      case 6:
        return const PurchaseFormScreen();
      case 7:
        return const SuppliersScreen();
      case 8:
        return const ComprasReportScreen();

      // 3. Inventario
      case 11:
        return const LocalInventoriesScreen();
      case 12:
        return const ReceptionScreen();
      case 13:
        return const InventoryScreen();

      // 4. Cuentas por Pagar
      case 15:
        return const CuentasPorPagarScreen();
      case 17:
        return const PaymentsScreen();

      // 5. Cuentas por Cobrar
      case 22:
        return const CobrosScreen();

      // 6. Finanzas y Contabilidad
      case 25:
        return const CatalogScreen();
      case 26:
        return const JournalScreen();
      case 27:
        return const ProfitLossScreen();
      case 28:
        return const ObligacionesScreen();
      case 29:
        return const ConciliacionesScreen();

      // 7. Activos Fijos
      case 30:
        return const AssetsScreen();

      // 8. Recursos Humanos
      case 34:
        return const EmployeesScreen();
      case 35:
        return const PayrollDashboardScreen();
      case 37:
        return const NominaExportsScreen();

      // 9. Configuración
      case 40:
        return const UsersScreen();
      case 42:
        return const SettingsScreen();
      case 47:
        return const NominaCatalogsScreen();

      // 10. Reportes y Auditoría
      case 43:
        return const GastosReportScreen();

      // 11. LED HOUSE (Módulo completo)
      case 48:
        return const LedhouseDetallesScreen(); // Estado de Resultado
      case 49:
        return const CxcScreen(); // Cuentas por Cobrar Ledhouse
      case 50:
        return const CxpScreen(); // Cuentas por Pagar Ledhouse
      case 51:
        return const CuentaCatalogoScreen(); // Catálogo de Cuentas Ledhouse
      case 52:
        return const LedhouseClientesScreen(); // Clientes Ledhouse

      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMeta = _tabMetas[_currentIndex];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      // Encabezado global unificado con botón de menú interactivo para abrir el drawer
      appBar: AppHeaderBar(
        title: currentMeta.title,
        subtitle: currentMeta.subtitle,
        badgeLetter: currentMeta.badgeLetter,
        showMenuButton: true,
        onMenuPressed: _openDrawer,
      ),
      // Drawer lateral con perfil de Carlos Mendoza, buscador y módulos
      drawer: Drawer(
        width: 280,
        backgroundColor: const Color(0xFF0F172A),
        child: AppNavigationDrawer(
          selectedIndex: _drawerSelectedIndex,
          onDestinationSelected: _handleDrawerNavigation,
          onCollapse: () {
            _scaffoldKey.currentState?.closeDrawer();
          },
          onScanQr: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lector QR activado para inventario y activos'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: CustomHomeBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: _navItems,
      ),
    );
  }
}
