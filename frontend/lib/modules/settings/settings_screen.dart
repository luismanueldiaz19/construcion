import 'package:flutter/material.dart';
import '../assets/presentation/asset_categories_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1A1C1E);
    final accentColor = const Color(0xFFE31E24);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuraciones del Sistema'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Administración',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: accentColor.withValues(alpha: 0.1),
                child: Icon(Icons.category, color: accentColor),
              ),
              title: const Text('Categorías de Activos', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Gestionar categorías de equipos, herramientas y vehículos'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AssetCategoriesScreen()),
                );
              },
            ),
          ),
          // Here we can add more settings tiles in the future
        ],
      ),
    );
  }
}
