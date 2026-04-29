import 'package:construccion_erp/modules/projects/historial_proyectos_screen.dart';
import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'modules/dashboard/dashboard_screen.dart';
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
import 'package:provider/provider.dart';
import 'modules/dashboard/dashboard_provider.dart';
import 'modules/projects/projects_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ProjectsProvider()),
      ],
      child: const ConstruccionERP(),
    ),
  );
}

class ConstruccionERP extends StatelessWidget {
  const ConstruccionERP({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neo Project S.R.L',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainLayout(),
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
    const DashboardScreen(),
    const ProjectsScreen(),
    const HistorialProyectosScreen(),
    const SuppliersScreen(),
    const ProductsScreen(),
    const PurchaseFormScreen(),
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
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.of(context).size.width > 1200,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Icon(Icons.engineering, color: Colors.white, size: 40),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.business_outlined),
                selectedIcon: Icon(Icons.business),
                label: Text('Proyectos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today_outlined),
                label: Text('Historial Proyectos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Proveedores'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_outlined),
                selectedIcon: Icon(Icons.inventory),
                label: Text('Productos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.add_shopping_cart_outlined),
                selectedIcon: Icon(Icons.add_shopping_cart),
                label: Text('Nueva Compra'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.shopping_cart_outlined),
                selectedIcon: Icon(Icons.shopping_cart),
                label: Text('Compras'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('Gastos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Inventario Proy.'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.money_off_outlined),
                selectedIcon: Icon(Icons.money_off),
                label: Text('Cuentas por Pagar'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: Text('Cuentas por Cobrar'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: Text('Historial de Pagos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.account_balance_outlined),
                selectedIcon: Icon(Icons.account_balance),
                label: Text('Contabilidad'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Configuración'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}
