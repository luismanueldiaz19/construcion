import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_theme.dart';
import '../providers/purchase_provider.dart';

class PurchaseHeader extends StatelessWidget {
  const PurchaseHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 600;

          final content = [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, size: 20),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Volver',
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Nueva Orden de Compra',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            if (isSmall) const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showDraftsDialog(context),
                  icon: const Icon(Icons.shopping_cart_checkout, size: 18),
                  label: const Text('Mis Borradores'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final provider = Provider.of<PurchaseProvider>(
                      context,
                      listen: false,
                    );
                    provider.addItem();
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar Material'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ];

          if (isSmall) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: content,
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: content,
          );
        },
      ),
    );
  }

  void _showDraftsDialog(BuildContext context) {
    final provider = Provider.of<PurchaseProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: provider,
        child: const _DraftsDialog(),
      ),
    );
  }
}

class _DraftsDialog extends StatefulWidget {
  const _DraftsDialog();

  @override
  State<_DraftsDialog> createState() => _DraftsDialogState();
}

class _DraftsDialogState extends State<_DraftsDialog> {
  List<Map<String, dynamic>> _drafts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    final provider = Provider.of<PurchaseProvider>(context, listen: false);
    final drafts = await provider.getDrafts();
    if (mounted) {
      setState(() {
        _drafts = drafts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PurchaseProvider>(context, listen: false);

    return AlertDialog(
      title: const Text('Mis Borradores'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _drafts.isEmpty
            ? const Center(child: Text('No tienes borradores guardados.'))
            : ListView.builder(
                itemCount: _drafts.length,
                itemBuilder: (context, index) {
                  final draft = _drafts[index];
                  return ListTile(
                    leading: const Icon(Icons.shopping_cart),
                    title: Text(draft['name'] ?? 'Borrador sin nombre'),
                    subtitle: Text(
                      draft['createdAt'] != null
                          ? draft['createdAt'].toString().split('T')[0]
                          : '',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await provider.deleteDraft(draft['id']);
                            _loadDrafts(); // reload list
                          },
                        ),
                        ElevatedButton(
                          onPressed: () {
                            provider.loadDraft(draft['id']);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Cargar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
