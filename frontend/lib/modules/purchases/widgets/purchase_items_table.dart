import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../providers/purchase_provider.dart';
import '../../../../widgets/search_selector_dialog.dart';

class PurchaseItemsTable extends StatelessWidget {
  const PurchaseItemsTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _HeaderTitle('DESCRIPCIÓN')),
                Expanded(flex: 1, child: _HeaderTitle('CANTIDAD')),
                Expanded(flex: 1, child: _HeaderTitle('PRECIO UNIT.')),
                Expanded(flex: 1, child: _HeaderTitle('IMPUESTO (%)')),
                Expanded(flex: 1, child: Align(alignment: Alignment.centerRight, child: _HeaderTitle('TOTAL'))),
                SizedBox(width: 48), // Space for delete button
              ],
            ),
          ),
          // Table Body
          Consumer<PurchaseProvider>(
            builder: (context, provider, child) {
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.items.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (context, index) {
                  final item = provider.items[index];
                  final isLastEmpty = item['material_id'] == null;
                  
                  if (isLastEmpty) {
                    return _EmptySearchRow(index: index);
                  }
                  return _DataRow(index: index, item: item);
                },
              );
            },
          ),
          // Table Footer Tip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Text(
              'Tip: Usa Tab para navegar. Busca por código o descripción.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  final String title;
  const _HeaderTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final int index;
  final Map<String, dynamic> item;

  const _DataRow({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PurchaseProvider>(context, listen: false);
    final material = provider.materiales.cast<dynamic>().firstWhere(
      (m) => m['id'] == item['material_id'],
      orElse: () => null,
    );

    final qty = item['cantidad'] ?? 0.0;
    final price = item['precio_unitario'] ?? 0.0;
    final total = qty * price;
    final f = NumberFormat.currency(symbol: '\$');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Description
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material?['nombre'] ?? 'Material Desconocido',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Código: ${material?['codigo'] ?? 'N/A'}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          // QTY
          Expanded(
            flex: 1,
            child: _buildInputCell(
              initialValue: qty == 0 ? '' : qty.toString(),
              onChanged: (v) => provider.updateItemCantidad(index, double.tryParse(v) ?? 0.0),
            ),
          ),
          // UNIT PRICE
          Expanded(
            flex: 1,
            child: _buildInputCell(
              initialValue: price == 0 ? '' : price.toString(),
              prefix: '\$ ',
              onChanged: (v) => provider.updateItemPrecio(index, double.tryParse(v) ?? 0.0),
            ),
          ),
          // TAX (%)
          Expanded(
            flex: 1,
            child: _buildInputCell(
              initialValue: '18', // Fixed 18% for ITBIS in DR, but visual only or can be editable if we expand model
              enabled: false,
            ),
          ),
          // TOTAL
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                f.format(total),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
          // Actions
          SizedBox(
            width: 48,
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                onPressed: () => provider.removeItem(index),
                tooltip: 'Eliminar',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCell({
    required String initialValue,
    String? prefix,
    bool enabled = true,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: TextFormField(
        initialValue: initialValue,
        enabled: enabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,4}')),
        ],
        style: TextStyle(
          fontSize: 13,
          color: enabled ? Colors.black : Colors.grey.shade600,
        ),
        decoration: InputDecoration(
          prefixText: prefix,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.blue),
          ),
          fillColor: enabled ? Colors.white : Colors.grey.shade50,
          filled: true,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _EmptySearchRow extends StatelessWidget {
  final int index;
  const _EmptySearchRow({required this.index});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final provider = Provider.of<PurchaseProvider>(context, listen: false);
        _showMaterialSearch(context, provider);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Text(
                'Escribe para buscar...',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            Expanded(flex: 1, child: _dashedBox()),
            Expanded(flex: 1, child: _dashedBox()),
            Expanded(flex: 1, child: _dashedBox()),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '\$0.00',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 48), // Action space
          ],
        ),
      ),
    );
  }

  Widget _dashedBox() {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: CustomPaint(
        painter: _DashedBorderPainter(color: Colors.grey.shade300),
        child: const SizedBox(
          height: 38,
          width: double.infinity,
        ),
      ),
    );
  }

  void _showMaterialSearch(BuildContext context, PurchaseProvider provider) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => SearchSelectorDialog(
        title: 'Material',
        items: provider.materiales,
        displayMapper: (m) => "${m['nombre']} (${m['unidad']})",
        subtitleMapper: (m) => "Código: ${m['codigo'] ?? 'N/A'} | Unidad: ${m['unidad']}",
        onAdd: () {
          Navigator.pop(context);
        },
      ),
    );

    if (!context.mounted) return;

    if (result != null) {
      try {
        provider.updateItemMaterial(index, result);
        provider.addItem();
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text('Aviso'),
              ],
            ),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    }
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final fallbackPaint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(6)),
        fallbackPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
