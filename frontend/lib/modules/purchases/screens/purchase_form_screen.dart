import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_theme.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_screen_wrapper.dart';
import '../providers/purchase_provider.dart';
import '../widgets/purchase_bottom_bar.dart';
import '../widgets/purchase_details_card.dart';
import '../widgets/purchase_items_table.dart';

/// Pantalla de registro de compra reconstruida con soporte nativo para los 2 modos
/// de pantalla (Escritorio y Móvil), cero desbordamientos y componentes globales UI.
class PurchaseFormScreen extends StatelessWidget {
  const PurchaseFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PurchaseProvider(),
      child: const _PurchaseFormContent(),
    );
  }
}

class _PurchaseFormContent extends StatelessWidget {
  const _PurchaseFormContent();

  void _showDraftsDialog(BuildContext context, PurchaseProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: provider,
        child: const _DraftsDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchaseProvider>();

    return AppScreenWrapper(
      title: 'Nueva Orden de Compra',
      subtitle: 'Registro de materiales y suministros para proyectos de obra',
      isLoading: provider.isLoading,
      errorMessage: provider.error,
      onRetry: provider.loadData,
      actions: [
        // Botón Mis Borradores
        AppButton(
          text: 'Mis Borradores',
          icon: Icons.bookmark_border_rounded,
          variant: AppButtonVariant.outlined,
          size: AppButtonSize.compact,
          onPressed: () => _showDraftsDialog(context, provider),
        ),

        // Botón Agregar Material
        AppButton(
          text: 'Agregar Material',
          icon: Icons.add_rounded,
          variant: AppButtonVariant.primary,
          size: AppButtonSize.compact,
          onPressed: () => provider.addItem(),
        ),
      ],
      // Modo 1: Escritorio (>= 850px) - Distribución horizontal de 2 columnas + barra inferior
      desktopView: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Columna izquierda: Tabla de partidas
                const Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: PurchaseItemsTable(),
                  ),
                ),
                const SizedBox(width: 16),
                // Columna derecha: Detalles de proveedor, proyecto y comprobante
                const SizedBox(
                  width: 360,
                  child: SingleChildScrollView(
                    child: PurchaseDetailsCard(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const PurchaseBottomBar(),
        ],
      ),
      // Modo 2: Móvil (< 850px) - Distribución vertical con scroll seguro
      mobileView: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PurchaseDetailsCard(),
            SizedBox(height: 14),
            PurchaseItemsTable(),
            SizedBox(height: 14),
            PurchaseBottomBar(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Diálogo para ver y cargar borradores de compras guardadas
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

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 400),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mis Borradores Guardados',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _drafts.isEmpty
                        ? const Center(
                            child: Text(
                              'No tienes borradores de compra guardados.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _drafts.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final draft = _drafts[index];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 18,
                                    color: AppTheme.accentColor,
                                  ),
                                ),
                                title: Text(
                                  draft['name'] ?? 'Borrador sin título',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  draft['createdAt'] != null
                                      ? draft['createdAt'].toString().split('T')[0]
                                      : '',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () async {
                                        await provider.deleteDraft(draft['id']);
                                        _loadDrafts();
                                      },
                                    ),
                                    AppButton(
                                      text: 'Cargar',
                                      size: AppButtonSize.compact,
                                      variant: AppButtonVariant.primary,
                                      onPressed: () {
                                        provider.loadDraft(draft['id']);
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
