import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_theme.dart';
import '../../../../models/proveedor.dart';
import '../../../../widgets/app_card.dart';
import '../../../../widgets/app_date_picker_field.dart';
import '../../../../widgets/app_dropdown.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../../widgets/search_selector_dialog.dart';
import '../providers/purchase_provider.dart';

/// Tarjeta de detalles de compra estandarizada con componentes globales.
///
/// Elimina desbordamientos de pantalla (overflows), adapta campos en 1 o 2 columnas
/// según el ancho disponible y sigue las directrices ultra-compactas del sistema.
class PurchaseDetailsCard extends StatelessWidget {
  const PurchaseDetailsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchaseProvider>();

    // Obtener nombre del proveedor seleccionado
    final selectedProveedor = provider.proveedores.cast<dynamic>().firstWhere(
      (p) => (p is Proveedor ? p.id : p['id']) == provider.selectedProveedorId,
      orElse: () => null,
    );
    final String proveedorTexto = selectedProveedor != null
        ? (selectedProveedor is Proveedor
            ? selectedProveedor.name
            : selectedProveedor['nombre'] ?? '')
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppCard(
          title: 'Detalles de la Compra',
          subtitle: 'Proveedor, proyecto y comprobante fiscal',
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Selector de Proveedor
              InkWell(
                onTap: () => _showSupplierSearch(context, provider),
                borderRadius: BorderRadius.circular(10),
                child: IgnorePointer(
                  child: AppTextField(
                    labelText: 'Proveedor',
                    hintText: 'Buscar y seleccionar proveedor...',
                    controller: TextEditingController(text: proveedorTexto),
                    prefixIconData: Icons.storefront_rounded,
                    suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 2. Dropdown de Proyecto (con isExpanded: true para prevenir overflows)
              AppDropdown<int>(
                labelText: 'Proyecto Destino',
                hintText: 'Seleccionar Proyecto',
                prefixIconData: Icons.construction_rounded,
                value: provider.selectedProyectoId,
                isExpanded: true,
                items: provider.proyectos.map((p) {
                  return DropdownMenuItem<int>(
                    value: p['id'] as int,
                    child: Text(
                      p['nombre']?.toString() ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  );
                }).toList(),
                onChanged: (v) => provider.updateProyecto(v),
              ),

              const SizedBox(height: 12),

              // 3. Fila flexible: Tipo de Compra y Fecha de Factura
              LayoutBuilder(
                builder: (context, constraints) {
                  final isTight = constraints.maxWidth < 280;

                  final tipoField = AppDropdown<String>(
                    labelText: 'Tipo de Compra',
                    value: provider.tipoCompra,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'Contado',
                        child: Text('Contado', style: TextStyle(fontSize: 12.5)),
                      ),
                      DropdownMenuItem(
                        value: 'Crédito',
                        child: Text('Crédito', style: TextStyle(fontSize: 12.5)),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) provider.updateTipoCompra(v);
                    },
                  );

                  final fechaField = AppDatePickerField(
                    labelText: 'Fecha de Factura',
                    selectedDate: provider.fecha,
                    isClearable: false,
                    onDateChanged: (d) {
                      if (d != null) provider.updateFecha(d);
                    },
                  );

                  if (isTight) {
                    return Column(
                      children: [
                        tipoField,
                        const SizedBox(height: 12),
                        fechaField,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: tipoField),
                      const SizedBox(width: 10),
                      Expanded(child: fechaField),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),

              // 4. Fila flexible: Referencia y Número de Comprobante
              LayoutBuilder(
                builder: (context, constraints) {
                  final isTight = constraints.maxWidth < 280;

                  final ordenField = AppTextField(
                    labelText: 'Referencia / No. Orden',
                    hintText: 'REF-XXXXX-X',
                    controller: provider.ordenController,
                    prefixIconData: Icons.tag_rounded,
                  );

                  final ncfField = AppTextField(
                    labelText: 'No. Comprobante (NCF)',
                    hintText: 'B0100000001',
                    controller: provider.comprobanteController,
                    prefixIconData: Icons.receipt_long_rounded,
                  );

                  if (isTight) {
                    return Column(
                      children: [
                        ordenField,
                        const SizedBox(height: 12),
                        ncfField,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: ordenField),
                      const SizedBox(width: 10),
                      Expanded(child: ncfField),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),

              // 5. Notas Internas
              AppTextField(
                labelText: 'Notas Internas / Observaciones',
                hintText: 'Añadir información adicional sobre la compra...',
                controller: provider.notaController,
                maxLines: 2,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 6. Tarjeta para adjuntar documento PDF
        _buildUploadInvoiceCard(),
      ],
    );
  }

  void _showSupplierSearch(BuildContext context, PurchaseProvider provider) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => SearchSelectorDialog(
        title: 'Seleccionar Proveedor',
        items: provider.proveedores,
        displayMapper: (p) => (p as Proveedor).name,
        subtitleMapper: (p) => 'RNC: ${(p as Proveedor).rnc ?? 'N/A'}',
        onAdd: () {
          Navigator.pop(context);
        },
      ),
    );

    if (result != null) {
      provider.updateProveedor(result);
    }
  }

  Widget _buildUploadInvoiceCard() {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: InkWell(
        onTap: () {
          // Acción de subir archivo (placeholder)
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_upload_outlined,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adjuntar Factura PDF',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Formatos admitidos: PDF, JPG, PNG (máx. 5MB)',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.attach_file_rounded, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
