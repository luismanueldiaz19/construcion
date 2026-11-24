import 'package:flutter/material.dart';
import '../../../widgets/app_header_bar.dart';
import '../../drawer/app_navigation_drawer.dart';
import '../widgets/custom_home_bottom_nav.dart';
import 'home_inicio_screen.dart';
import 'home_proyectos_screen.dart';
import 'home_clientes_screen.dart';
import 'home_cxc_screen.dart';
import 'home_mas_screen.dart';

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
    HomeInicioScreen(),
    HomeProyectosScreen(),
    HomeClientesScreen(),
    HomeCxcScreen(),
    HomeMasScreen(),
  ];

  static const List<_TabMeta> _tabMetas = [
    _TabMeta(
      title: 'NEO PROJECT',
      subtitle: 'ERP Constructora · RD',
      badgeLetter: 'N',
    ),
    _TabMeta(
      title: 'PROYECTOS',
      subtitle: 'Gestión y control de obras',
      badgeLetter: 'P',
    ),
    _TabMeta(
      title: 'CLIENTES',
      subtitle: 'Directorio y gestión de cuentas',
      badgeLetter: 'C',
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
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Inicio',
    ),
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

    // Mapeo inteligente con los tabs principales del Home
    if (index == 0) {
      // Proyectos
      _onTabTapped(1);
    } else if (index == 20) {
      // Directorio de Clientes
      _onTabTapped(2);
    } else if (index == 23 || index == 22) {
      // Cuentas por Cobrar
      _onTabTapped(3);
    } else {
      // Módulo adicional
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navegando a módulo #$index del sistema'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1500),
        ),
      );
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
