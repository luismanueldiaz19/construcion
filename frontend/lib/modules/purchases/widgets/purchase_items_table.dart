import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../../../core/app_theme.dart';
import '../../../../widgets/app_card.dart';
import '../../../../widgets/search_selector_dialog.dart';
import '../providers/purchase_provider.dart';

/// Tabla de partidas de compra completamente responsiva:
/// - En Escritorio (>= 550px): Tabla horizontal organizada y compacta.
/// - En Móvil (< 550px): Tarjetas de material verticales que eliminan el scroll horizontal.
/// - Cero desbordamientos de pantalla en cualquier resolución.
class PurchaseItemsTable extends StatelessWidget {
  const PurchaseItemsTable({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Partidas y Materiales',
      subtitle: 'Detalle de suministros, cantidades y costos unitarios',
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 550;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isMobile)
                const _MobileItemsList()
              else
                const _DesktopItemsTable(),

              // Pie de tabla con texto protegido dentro de Expanded (cero overflows)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: Presione en la fila para buscar material. Use Tab para navegar entre celdas.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Vista de tabla para pantallas grandes (Desktop >= 550px)
class _DesktopItemsTable extends StatelessWidget {
  const _DesktopItemsTable();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Encabezado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3, child: _HeaderTitle('DESCRIPCIÓN')),
              Expanded(flex: 1, child: _HeaderTitle('CANTIDAD')),
              Expanded(flex: 1, child: _HeaderTitle('PRECIO UNIT.')),
              Expanded(flex: 1, child: _HeaderTitle('IMPUESTO (%)')),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _HeaderTitle('TOTAL'),
                ),
              ),
              SizedBox(width: 40),
            ],
          ),
        ),

        // Filas de datos
        Consumer<PurchaseProvider>(
          builder: (context, provider, child) {
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.items.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey.shade100),
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
      ],
    );
  }
}

/// Vista de tarjetas de partida para pantallas móviles o estrechas (< 550px)
class _MobileItemsList extends StatelessWidget {
  const _MobileItemsList();

  @override
  Widget build(BuildContext context) {
    return Consumer<PurchaseProvider>(
      builder: (context, provider, child) {
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: provider.items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = provider.items[index];
            final isLastEmpty = item['material_id'] == null;

            if (isLastEmpty) {
              return _MobileEmptyRow(index: index);
            }
            return _MobileDataCard(index: index, item: item);
          },
        );
      },
    );
  }
}

class _MobileDataCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> item;

  const _MobileDataCard({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PurchaseProvider>(context, listen: false);
    final material = provider.materiales.cast<dynamic>().firstWhere(
      (m) => m['id'] == item['material_id'],
      orElse: () => null,
    );

    final qty = (item['cantidad'] as num?)?.toDouble() ?? 0.0;
    final price = (item['precio_unitario'] as num?)?.toDouble() ?? 0.0;
    final total = qty * price;
    final f = NumberFormat.currency(symbol: '\$');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fila superior: Nombre del material y botón eliminar
          Row(
            children: [
              Expanded(
                child: Text(
                  material?['nombre']?.toString() ?? 'Material',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => provider.removeItem(index),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                ),
              ),
            ],
          ),
          Text(
            'Cód: ${material?['codigo'] ?? 'N/A'} • Unidad: ${material?['unidad'] ?? 'N/A'}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),

          // Fila de controles: Cantidad, Precio y Total
          Row(
            children: [
              // Cantidad
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cant.', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 34,
                      child: TextFormField(
                        initialValue: qty == 0 ? '' : (qty % 1 == 0 ? qty.toInt().toString() : qty.toString()),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 12),
                        decoration: _inputDecoration('0'),
                        onChanged: (v) =>
                            provider.updateItemCantidad(index, double.tryParse(v) ?? 0.0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Precio
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Precio Unit.', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 34,
                      child: TextFormField(
                        initialValue: price == 0 ? '' : price.toString(),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 12),
                        decoration: _inputDecoration('\$ 0.00'),
                        onChanged: (v) =>
                            provider.updateItemPrecio(index, double.tryParse(v) ?? 0.0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Total
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      f.format(total),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
        borderSide: const BorderSide(color: AppTheme.accentColor, width: 1.2),
      ),
      fillColor: Colors.white,
      filled: true,
    );
  }
}

class _MobileEmptyRow extends StatelessWidget {
  final int index;
  const _MobileEmptyRow({required this.index});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final provider = Provider.of<PurchaseProvider>(context, listen: false);
        _showMaterialSearch(context, provider, index);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, size: 16, color: AppTheme.accentColor),
            SizedBox(width: 8),
            Text(
              'Toca para buscar y agregar material...',
              style: TextStyle(
                color: AppTheme.accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
        fontSize: 10.5,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade600,
        letterSpacing: 0.4,
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

    final qty = (item['cantidad'] as num?)?.toDouble() ?? 0.0;
    final price = (item['precio_unitario'] as num?)?.toDouble() ?? 0.0;
    final total = qty * price;
    final f = NumberFormat.currency(symbol: '\$');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Descripción y código
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  material?['nombre']?.toString() ?? 'Material Desconocido',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Cód: ${material?['codigo'] ?? 'N/A'} • Unidad: ${material?['unidad'] ?? 'N/A'}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),

          // Cantidad
          Expanded(
            flex: 1,
            child: _buildInputCell(
              initialValue: qty == 0 ? '' : (qty % 1 == 0 ? qty.toInt().toString() : qty.toString()),
              onChanged: (v) =>
                  provider.updateItemCantidad(index, double.tryParse(v) ?? 0.0),
            ),
          ),

          // Precio Unitario
          Expanded(
            flex: 1,
            child: _buildInputCell(
              initialValue: price == 0 ? '' : price.toString(),
              prefix: '\$ ',
              onChanged: (v) =>
                  provider.updateItemPrecio(index, double.tryParse(v) ?? 0.0),
            ),
          ),

          // Impuesto ITBIS (18%)
          Expanded(
            flex: 1,
            child: _buildInputCell(
              initialValue: '18%',
              enabled: false,
            ),
          ),

          // Total por fila
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                f.format(total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),

          // Botón de eliminar
          SizedBox(
            width: 40,
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                onPressed: () => provider.removeItem(index),
                tooltip: 'Eliminar partida',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
      padding: const EdgeInsets.only(right: 10.0),
      child: SizedBox(
        height: 36,
        child: TextFormField(
          initialValue: initialValue,
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,4}')),
          ],
          style: TextStyle(
            fontSize: 12,
            color: enabled ? AppTheme.textPrimary : Colors.grey.shade600,
          ),
          decoration: InputDecoration(
            prefixText: prefix,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
              borderSide: const BorderSide(color: AppTheme.accentColor, width: 1.2),
            ),
            fillColor: enabled ? Colors.white : const Color(0xFFF1F5F9),
            filled: true,
          ),
          onChanged: onChanged,
        ),
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
        _showMaterialSearch(context, provider, index);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text(
                    'Buscar y agregar material...',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 1, child: _dashedBox()),
            Expanded(flex: 1, child: _dashedBox()),
            Expanded(flex: 1, child: _dashedBox()),
            const Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '\$0.00',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _dashedBox() {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
      ),
    );
  }
}

void _showMaterialSearch(BuildContext context, PurchaseProvider provider, int index) async {
  final result = await showDialog<int>(
    context: context,
    builder: (ctx) => SearchSelectorDialog(
      title: 'Seleccionar Material',
      items: provider.materiales,
      displayMapper: (m) => "${m['nombre']} (${m['unidad']})",
      subtitleMapper: (m) =>
          "Código: ${m['codigo'] ?? 'N/A'} • Ref: \$${m['precio_costo'] ?? '0.00'}",
      onAdd: () {
        Navigator.pop(ctx);
      },
    ),
  );

  if (!context.mounted) return;

  if (result != null) {
    try {
      provider.updateItemMaterial(index, result);
      provider.addItem();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
