import 'package:construccion_erp/modules/projects/historial_proyectos_screen.dart';
import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'modules/dashboard/dashboard_screen.dart';
import 'modules/projects/projects_screen.dart';
import 'modules/accounting/accounting_screen.dart';
import 'modules/accounting/cuentas_por_pagar_screen.dart';
import 'modules/accounting/cuentas_por_cobrar_screen.dart';
import 'modules/payments/payments_screen.dart';
import 'modules/payments/cobros_screen.dart';
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
    // const DashboardScreen(),
    const Center(child: Text('No se implementara')),
    const ProjectsScreen(),
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
    return Scaffold(
      body: Row(
        children: [
          CustomSidebar(
            extended: MediaQuery.of(context).size.width > 1200,
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
