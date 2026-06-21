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
import 'modules/payments/cobros_screen.dart';
import 'modules/inventory/inventory_screen.dart';
import 'modules/inventory/local_inventories_screen.dart';
import 'modules/reports/compras_report_screen.dart';
import 'modules/reports/gastos_report_screen.dart';
import 'modules/inventory/suppliers_screen.dart';
import 'modules/inventory/purchase_form_screen.dart';
import 'modules/inventory/products_screen.dart';
import 'modules/inventory/reception_screen.dart';
import 'modules/clients/clients_screen.dart';
import 'modules/assets/presentation/assets_screen.dart';
import 'package:provider/provider.dart';
import 'modules/dashboard/dashboard_provider.dart';
import 'modules/projects/projects_provider.dart';
import 'modules/assets/providers/assets_provider.dart';
import 'modules/settings/settings_screen.dart';
import 'modules/users/providers/users_provider.dart';
import 'modules/users/users_screen.dart';
import 'widgets/custom_sidebar.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ProjectsProvider()),
        ChangeNotifierProvider(create: (_) => AssetsProvider()),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
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

class EmptyScreen extends StatelessWidget {
  final String title;
  const EmptyScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 80,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '$title\n(En desarrollo)',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, color: Colors.grey),
          ),
        ],
      ),
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
    // 1. Gestión de Proyectos (0-4)
    const ProjectsScreen(), // 0. Planificación de obras
    const EmptyScreen('Presupuesto de partidas'), // 1
    const EmptyScreen('Avance físico-financiero'), // 2
    const EmptyScreen('Control de presupuestos'), // 3
    const HistorialProyectosScreen(), // 4. Reportes de progreso
    // 2. Compras y Proveedores (5-9)
    const EmptyScreen('Solicitudes de compra'), // 5
    const PurchaseFormScreen(), // 6. Registrar compra
    const SuppliersScreen(), // 7. Registro de proveedores
    const ComprasReportScreen(), // 8. Facturas recibidas
    const EmptyScreen('Control de ITBIS en compras'), // 9
    // 3. Inventario (10-14)
    const ProductsScreen(), // 10. Materiales de construcción
    const LocalInventoriesScreen(), // 11. Herramientas y equipos
    const ReceptionScreen(), // 12. Entradas y salidas
    const InventoryScreen(), // 13. Kardex y costos promedio
    const EmptyScreen('Alertas de stock mínimo'), // 14
    // 4. Cuentas por Pagar (15-19)
    const CuentasPorPagarScreen(), // 15. Facturas pendientes
    const EmptyScreen('Anticipos a proveedores'), // 16
    const PaymentsScreen(), // 17. Pagos programados
    const EmptyScreen('Retenciones fiscales'), // 18
    const EmptyScreen('Conciliación bancaria'), // 19
    // 5. Cuentas por Cobrar (20-24)
    const ClientsScreen(), // 20. Directorio de clientes
    const EmptyScreen('Anticipos recibidos'), // 21
    const CobrosScreen(), // 22. Cobros parciales por avance (Historial de Cobros)
    const CuentasPorCobrarScreen(), // 23. Estado de cuentas de clientes
    const EmptyScreen('ITBIS facturado'), // 24
    // 6. Finanzas y Contabilidad (25-29)
    const AccountingScreen(), // 25. Catálogo contable jerárquico
    const EmptyScreen('Asientos automáticos'), // 26
    const EmptyScreen('Estados financieros'), // 27
    const EmptyScreen('Obligaciones fiscales'), // 28
    const EmptyScreen('Conciliaciones y cierres contables'), // 29
    // 7. Activos Fijos (30-33)
    const AssetsScreen(), // 30. Registro de equipos y maquinarias
    const EmptyScreen('Depreciación contable y fiscal'), // 31
    const EmptyScreen('Mantenimiento programado'), // 32
    const EmptyScreen('Transferencias entre proyectos'), // 33
    // 8. Recursos Humanos (34-37)
    const EmptyScreen('Nómina de empleados'), // 34
    const EmptyScreen('Contratos de obra'), // 35
    const EmptyScreen('Horas trabajadas y control de asistencia'), // 36
    const EmptyScreen('Retenciones de seguridad social'), // 37
    // 9. Configuración (38-42)
    const EmptyScreen('Parametrización de impuestos'), // 38
    const EmptyScreen('Catálogo de cuentas personalizable'), // 39
    const UsersScreen(), // 40. Roles y permisos de usuario
    const EmptyScreen('Integraciones externas'), // 41
    const SettingsScreen(), // 42. Configuración general
    // 10. Reportes y Auditoría (43-46)
    const GastosReportScreen(), // 43. Reportes de avance de obra (Gastos)
    const EmptyScreen('Estado de cuentas por proyecto'), // 44
    const EmptyScreen('Auditoría de movimientos contables'), // 45
    const EmptyScreen('Exportación a PDF/Excel'), // 46
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
