import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_theme.dart';
import '../providers/purchase_provider.dart';

class PurchaseBottomBar extends StatelessWidget {
  const PurchaseBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PurchaseProvider>(
      builder: (context, provider, child) {
        double total = provider.items.fold(
          0.0,
          (sum, item) => sum + ((item['cantidad'] ?? 0.0) * (item['precio_unitario'] ?? 0.0)),
        );
        double subtotal = total / 1.18;
        double itbis = total - subtotal;
        final f = NumberFormat.currency(symbol: '\$');

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 600; // Increased threshold for bottom bar

              final totalsSection = Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: isSmall ? WrapAlignment.center : WrapAlignment.start,
                children: [
                  _buildAmountColumn('SUB-TOTAL', f.format(subtotal)),
                  _buildDivider(),
                  _buildAmountColumn('ITBIS (18%)', f.format(itbis)),
                  _buildDivider(),
                  _buildAmountColumn('TOTAL GENERAL', f.format(total), isTotal: true),
                ],
              );

              final buttonsSection = SizedBox(
                width: isSmall ? double.infinity : null,
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: isSmall ? WrapAlignment.center : WrapAlignment.end,
                  children: [
                    SizedBox(
                      width: isSmall ? double.infinity : null,
                      child: OutlinedButton(
                        onPressed: provider.isSubmitting ? null : () async {
                          final defaultName = 'Borrador ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}';
                          final nameController = TextEditingController(text: defaultName);
                          final name = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Guardar Borrador'),
                              content: TextField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  hintText: 'Ej: Compra mensual Ferretería X',
                                  labelText: 'Nombre del borrador',
                                ),
                                autofocus: true,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, nameController.text.trim()),
                                  child: const Text('Guardar'),
                                ),
                              ],
                            ),
                          );

                          if (name != null && name.isNotEmpty) {
                            try {
                              await provider.saveDraft(name);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Borrador "$name" guardado'), backgroundColor: Colors.blue),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text('GUARDAR BORRADOR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(
                      width: isSmall ? double.infinity : null,
                      child: ElevatedButton(
                        onPressed: provider.isSubmitting
                            ? null
                            : () async {
                                try {
                                  await provider.submit();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Compra registrada con éxito'), backgroundColor: Colors.green),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: provider.isSubmitting
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('REGISTRAR COMPRA', style: TextStyle(fontWeight: FontWeight.bold)),
                                  SizedBox(width: 8),
                                  Icon(Icons.check_circle, size: 18),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              );

              if (isSmall) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    totalsSection,
                    const SizedBox(height: 24),
                    buttonsSection,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  totalsSection,
                  buttonsSection,
                ],
              );
            }
          ),
        );
      },
    );
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
            color: isTotal ? AppTheme.primaryColor : Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppTheme.primaryColor : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        height: 32,
        width: 1,
        color: Colors.grey.shade300,
      ),
    );
  }
}
