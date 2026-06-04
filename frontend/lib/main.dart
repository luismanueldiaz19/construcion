import 'dart:ui';
import 'package:construccion_erp/core/constants.dart';
import 'package:construccion_erp/modules/projects/historial_proyectos_screen.dart';
import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'core/auth_provider.dart';
import 'modules/auth/splash_screen.dart';
import 'modules/projects/projects_screen.dart';
import 'modules/accounting/accounting_screen.dart';
import 'modules/accounting/cuentas_por_pagar_screen.dart';
import 'modules/accounting/cuentas_por_cobrar_screen.dart';
import 'modules/payments/payments_screen.dart';
import 'modules/inventory/inventory_screen.dart';
import 'modules/reports/compras_report_screen.dart';
import 'modules/reports/gastos_report_screen.dart';
import 'modules/inventory/suppliers_screen.dart';
import 'modules/inventory/purchase_form_screen.dart';
import 'modules/inventory/products_screen.dart';
import 'modules/inventory/reception_screen.dart';
import 'package:provider/provider.dart';
import 'modules/dashboard/dashboard_provider.dart';
import 'modules/projects/projects_provider.dart';
import 'widgets/custom_sidebar.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ProjectsProvider()),
      ],
      child: const ConstruccionERP(),
    ),
  );
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

class ConstruccionERP extends StatelessWidget {
  const ConstruccionERP({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neo Project S.R.L',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scrollBehavior: AppScrollBehavior(),
      home: const SplashScreen(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ProjectsScreen(),
    const Center(child: Text('No se implementara')),

    const HistorialProyectosScreen(),
    const SuppliersScreen(),
    const ProductsScreen(),
    const PurchaseFormScreen(),
    const ReceptionScreen(),
    const ComprasReportScreen(),
    const GastosReportScreen(),
    const InventoryScreen(),
    const CuentasPorPagarScreen(),
    const CuentasPorCobrarScreen(),
    const PaymentsScreen(),
    const AccountingScreen(),
    const Center(child: Text('Configuración')),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width <= 850;

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              backgroundColor: const Color(0xFF1A1C1E),
              elevation: 0,
              title: Row(
                children: [
                  Image.asset(
                    logoPath,
                    height: 30,
                    color: Colors.white,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.construction,
                      color: Color(0xFFE31E24),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'NEO PROJECT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            )
          : null,
      drawer: isMobile
          ? Drawer(
              width: 260,
              child: CustomSidebar(
                extended: true,
                selectedIndex: _selectedIndex,
                onDestinationSelected: (int index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                  Navigator.of(context).pop(); // Cierra el Drawer
                },
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            CustomSidebar(
              extended: true,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                color: Colors.white.withValues(alpha: 0.7),
                child: _screens[_selectedIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
