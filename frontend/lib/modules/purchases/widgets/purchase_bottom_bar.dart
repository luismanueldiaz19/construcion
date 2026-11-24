import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_theme.dart';
import '../../../../widgets/app_alert.dart';
import '../../../../widgets/app_button.dart';
import '../providers/purchase_provider.dart';

/// Barra inferior estandarizada con desglose de totales e invocación de acciones
/// principales mediante botones globales con indicador de carga integrado.
class PurchaseBottomBar extends StatelessWidget {
  const PurchaseBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PurchaseProvider>(
      builder: (context, provider, child) {
        final double total = provider.items.fold(
          0.0,
          (sum, item) =>
              sum +
              (((item['cantidad'] as num?)?.toDouble() ?? 0.0) *
                  ((item['precio_unitario'] as num?)?.toDouble() ?? 0.0)),
        );
        final double subtotal = total / 1.18;
        final double itbis = total - subtotal;
        final f = NumberFormat.currency(symbol: '\$');

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 620;

              final totalsSection = isSmall
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildAmountColumn('SUB-TOTAL', f.format(subtotal)),
                        _buildAmountColumn('ITBIS (18%)', f.format(itbis)),
                        _buildAmountColumn('TOTAL GENERAL', f.format(total), isTotal: true),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAmountColumn('SUB-TOTAL', f.format(subtotal)),
                        _buildDivider(),
                        _buildAmountColumn('ITBIS (18%)', f.format(itbis)),
                        _buildDivider(),
                        _buildAmountColumn('TOTAL GENERAL', f.format(total), isTotal: true),
                      ],
                    );

              final buttonsSection = Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: isSmall ? WrapAlignment.center : WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Botón Guardar Borrador
                  AppButton(
                    text: 'GUARDAR BORRADOR',
                    variant: AppButtonVariant.outlined,
                    size: AppButtonSize.compact,
                    onPressed: provider.isSubmitting
                        ? null
                        : () => _handleSaveDraft(context, provider),
                  ),

                  // Botón Registrar Compra (con spinner integrado)
                  AppButton(
                    text: 'REGISTRAR COMPRA',
                    icon: Icons.check_circle_outline_rounded,
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.compact,
                    isLoading: provider.isSubmitting,
                    onPressed: () => _handleRegisterPurchase(context, provider),
                  ),
                ],
              );

              if (isSmall) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    totalsSection,
                    const SizedBox(height: 12),
                    buttonsSection,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  totalsSection,
                  buttonsSection,
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _handleSaveDraft(BuildContext context, PurchaseProvider provider) async {
    final defaultName =
        'Borrador ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}';
    final nameController = TextEditingController(text: defaultName);

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Guardar Borrador', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'Ej: Compra mensual de cemento',
            labelText: 'Nombre identificador',
            isDense: true,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty && context.mounted) {
      try {
        await provider.saveDraft(name);
        if (context.mounted) {
          AppAlert.showToast(
            context,
            'Borrador "$name" guardado exitosamente',
            type: AppAlertType.success,
          );
        }
      } catch (e) {
        if (context.mounted) {
          AppAlert.showToast(
            context,
            'Error al guardar borrador: $e',
            type: AppAlertType.error,
          );
        }
      }
    }
  }

  void _handleRegisterPurchase(
    BuildContext context,
    PurchaseProvider provider,
  ) async {
    try {
      await provider.submit();
      if (context.mounted) {
        AppAlert.showToast(
          context,
          'Compra registrada correctamente',
          type: AppAlertType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppAlert.showToast(
          context,
          e.toString().replaceAll('Exception: ', ''),
          type: AppAlertType.error,
        );
      }
    }
  }

  Widget _buildAmountColumn(String label, String amount, {bool isTotal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppTheme.accentColor : Colors.grey.shade500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 16 : 13.5,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppTheme.accentColor : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Container(
        height: 24,
        width: 1,
        color: Colors.grey.shade300,
      ),
    );
  }
}
