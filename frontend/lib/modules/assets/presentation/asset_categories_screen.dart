import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/assets_provider.dart';

class AssetCategoriesScreen extends StatefulWidget {
  const AssetCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<AssetCategoriesScreen> createState() => _AssetCategoriesScreenState();
}

class _AssetCategoriesScreenState extends State<AssetCategoriesScreen> {
  final _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Provider.of<AssetsProvider>(context, listen: false).categories.isEmpty) {
        Provider.of<AssetsProvider>(context, listen: false).fetchAssets();
      }
    });
  }

  void _addCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await Provider.of<AssetsProvider>(context, listen: false).createCategory(name);
      _nameController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _deleteCategory(int id) async {
    try {
      await Provider.of<AssetsProvider>(context, listen: false).deleteCategory(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1A1C1E);
    final accentColor = const Color(0xFFE31E24);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Categorías'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AssetsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Formulario agregar
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nueva Categoría',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                          onPressed: _isSaving ? null : _addCategory,
                          child: _isSaving 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Agregar'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Lista de categorias
                Expanded(
                  child: provider.categories.isEmpty
                      ? const Center(child: Text('No hay categorías registradas'))
                      : ListView.builder(
                          itemCount: provider.categories.length,
                          itemBuilder: (context, index) {
                            final cat = provider.categories[index];
                            return Card(
                              child: ListTile(
                                leading: Icon(Icons.category, color: accentColor),
                                title: Text(cat.name),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.grey),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Eliminar Categoría'),
                                        content: const Text('¿Estás seguro que deseas eliminar esta categoría?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Cancelar'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              _deleteCategory(cat.id);
                                            },
                                            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
