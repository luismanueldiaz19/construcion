import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../auth/login_screen.dart';
import 'models/drawer_menu_item.dart';
import 'widgets/drawer_header_profile.dart';
import 'widgets/drawer_expansion_section.dart';

/// Menú Drop / Drawer independiente para la navegación del ERP Neo Project.
/// Incorpora el diseño de cabecera con perfil de usuario, buscador rápido de módulos,
/// botón de acción QR, módulos desplegables en acordeón y filtrado dinámico en tiempo real.
class AppNavigationDrawer extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback? onCollapse;
  final VoidCallback? onScanQr;
  final double width;

  const AppNavigationDrawer({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.onCollapse,
    this.onScanQr,
    this.width = 280,
  });

  @override
  State<AppNavigationDrawer> createState() => _AppNavigationDrawerState();
}

class _AppNavigationDrawerState extends State<AppNavigationDrawer> {
  final TextEditingController _searchController = TextEditingController();
  final List<DrawerSection> _allSections = DrawerSection.getDefaultSections();
  String _searchQuery = '';
  String? _expandedSectionId;

  @override
  void initState() {
    super.initState();
    _autoExpandActiveSection();
  }

  @override
  void didUpdateWidget(AppNavigationDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _autoExpandActiveSection();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _autoExpandActiveSection() {
    for (final section in _allSections) {
      if (section.items.any((item) => item.index == widget.selectedIndex)) {
        setState(() {
          _expandedSectionId = section.id;
        });
        break;
      }
    }
  }

  List<DrawerSection> _getFilteredSections() {
    if (_searchQuery.isEmpty) return _allSections;

    final query = _searchQuery.toLowerCase();
    final List<DrawerSection> results = [];

    for (final section in _allSections) {
      final matchesSectionTitle = section.title.toLowerCase().contains(query);
      final matchingItems = section.items.where((item) {
        return item.title.toLowerCase().contains(query);
      }).toList();

      if (matchesSectionTitle) {
        results.add(section);
      } else if (matchingItems.isNotEmpty) {
        results.add(
          DrawerSection(
            id: section.id,
            title: section.title,
            icon: section.icon,
            items: matchingItems,
          ),
        );
      }
    }

    return results;
  }

  void _handleLogout(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userName =
        authProvider.username != null && authProvider.username!.isNotEmpty
        ? authProvider.username!
        : 'Ing. Carlos Mendoza';
    const userRole = 'Admin · Plaza Moca SRL';

    final filteredSections = _getFilteredSections();

    return Container(
      width: widget.width,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Base dark slate
        border: Border(right: BorderSide(color: Color(0xFF1E293B), width: 1.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          // 1. Cabecera con Perfil, Buscador y Botón QR
          DrawerHeaderProfile(
            userName: userName,
            userRole: userRole,
            searchController: _searchController,
            onSearchChanged: (val) {
              setState(() {
                _searchQuery = val.trim();
              });
            },
            onCollapse: widget.onCollapse,
            onQrPressed:
                widget.onScanQr ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Escáner QR disponible para inventario y activos',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
          ),
          const Divider(height: 1, color: Color(0xFF1E293B)),

          // 2. Lista de Módulos Desplegables con scroll
          Expanded(
            child: filteredSections.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No se encontraron módulos',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredSections.length,
                    itemBuilder: (context, index) {
                      final section = filteredSections[index];
                      // Si hay búsqueda activa, expande todo por defecto
                      final isExpanded =
                          _searchQuery.isNotEmpty ||
                          _expandedSectionId == section.id;

                      return DrawerExpansionSection(
                        section: section,
                        isExpanded: isExpanded,
                        selectedIndex: widget.selectedIndex,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            if (expanded) {
                              _expandedSectionId = section.id;
                            } else if (_expandedSectionId == section.id) {
                              _expandedSectionId = null;
                            }
                          });
                        },
                        onItemSelected: widget.onDestinationSelected,
                      );
                    },
                  ),
          ),

          // 3. Pie del Drawer: Cerrar Sesión
          const Divider(height: 1, color: Color(0xFF1E293B)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFF0F172A),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _handleLogout(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: Color(0xFFEF4444), // Red-500
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
