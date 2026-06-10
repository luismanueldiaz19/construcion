import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/assets_provider.dart';
import '../../../core/constants.dart';
import 'asset_form_screen.dart';
import 'asset_expense_form_screen.dart';
import 'asset_categories_screen.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({Key? key}) : super(key: key);

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AssetsProvider>(context, listen: false).fetchAssets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1A1C1E);
    final accentColor = const Color(0xFFE31E24);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activos y Equipos'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AssetsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }
          if (provider.assets.isEmpty) {
            return const Center(child: Text('No hay activos registrados.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.assets.length,
            itemBuilder: (context, index) {
              final asset = provider.assets[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: accentColor.withValues(alpha: 0.1),
                    child: Icon(Icons.computer, color: accentColor),
                  ),
                  title: Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('TCO: \$${asset.tco?.toStringAsFixed(2) ?? "0.00"} - Estado: ${asset.status}'),
                  trailing: IconButton(
                    icon: Icon(Icons.add_circle_outline, color: accentColor),
                    tooltip: 'Registrar Gasto',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssetExpenseFormScreen(asset: asset),
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    // TODO: Navigate to details screen
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AssetFormScreen()),
          );
        },
        backgroundColor: accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
