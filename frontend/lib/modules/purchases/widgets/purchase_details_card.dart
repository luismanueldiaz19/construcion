import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_theme.dart';
import '../providers/purchase_provider.dart';
import '../../../../models/proveedor.dart';
import '../../../../widgets/search_selector_dialog.dart';

class PurchaseDetailsCard extends StatelessWidget {
  const PurchaseDetailsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detalles de la Compra',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),

                // Supplier Search
                _buildLabel('Proveedor'),
                Consumer<PurchaseProvider>(
                  builder: (context, provider, child) {
                    return _buildSearchField(
                      context: context,
                      hint: 'Buscar Proveedor',
                      value: provider.selectedProveedorId,
                      items: provider.proveedores,
                      displayMapper: (p) => (p as Proveedor).name,
                      onTap: () => _showSupplierSearch(context, provider),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Project Dropdown
                _buildLabel('Proyecto'),
                Consumer<PurchaseProvider>(
                  builder: (context, provider, child) {
                    return DropdownButtonFormField<int>(
                      value: provider.selectedProyectoId,
                      decoration: _inputDecoration(
                        'Seleccionar Proyecto',
                        null,
                      ),
                      items: provider.proyectos
                          .map(
                            (p) => DropdownMenuItem<int>(
                              value: p['id'],
                              child: Text(p['nombre']),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => provider.updateProyecto(v),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Purchase Type & Date
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 400) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTipoCompra(context),
                          const SizedBox(height: 16),
                          _buildFechaFactura(context),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildTipoCompra(context)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildFechaFactura(context)),
                      ],
                    );
                  },
                ),
                // Reference & Comprobante
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 400) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildReferencia(context),
                          const SizedBox(height: 16),
                          _buildComprobante(context),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildReferencia(context)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildComprobante(context)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Internal Notes
                _buildLabel('Notas Internas'),
                Consumer<PurchaseProvider>(
                  builder: (context, provider, child) {
                    return TextFormField(
                      controller: provider.notaController,
                      maxLines: 3,
                      decoration: _inputDecoration(
                        'Añadir información adicional...',
                        null,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Upload Invoice PDF Placeholder Card
        _buildUploadCard(),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTipoCompra(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Tipo de Compra'),
        Consumer<PurchaseProvider>(
          builder: (context, provider, child) {
            return DropdownButtonFormField<String>(
              value: provider.tipoCompra,
              decoration: _inputDecoration(null, null),
              items: const [
                DropdownMenuItem(value: 'Contado', child: Text('Contado')),
                DropdownMenuItem(value: 'Crédito', child: Text('Crédito')),
              ],
              onChanged: (v) => provider.updateTipoCompra(v!),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFechaFactura(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Fecha de Factura'),
        Consumer<PurchaseProvider>(
          builder: (context, provider, child) {
            return InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: provider.fecha,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) provider.updateFecha(date);
              },
              child: InputDecorator(
                decoration: _inputDecoration(
                  null,
                  Icons.calendar_today_outlined,
                ),
                child: Text(DateFormat('MM/dd/yyyy').format(provider.fecha)),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReferencia(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Referencia / No. Orden'),
        Consumer<PurchaseProvider>(
          builder: (context, provider, child) {
            return TextFormField(
              controller: provider.ordenController,
              decoration: _inputDecoration('REF-XXXXX-X', null),
            );
          },
        ),
      ],
    );
  }

  Widget _buildComprobante(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('No. de Comprobante'),
        Consumer<PurchaseProvider>(
          builder: (context, provider, child) {
            return TextFormField(
              controller: provider.comprobanteController,
              decoration: _inputDecoration('B0100000001', null),
            );
          },
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String? hint, IconData? suffixIcon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      isDense: true,
      suffixIcon: suffixIcon != null
          ? Icon(suffixIcon, size: 18, color: Colors.grey.shade500)
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blue),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildSearchField({
    required BuildContext context,
    required String hint,
    required dynamic value,
    required List<dynamic> items,
    required String Function(dynamic) displayMapper,
    required VoidCallback onTap,
  }) {
    final selectedItem = items.cast<dynamic>().firstWhere(
      (i) => (i is Proveedor ? i.id : i['id']) == value,
      orElse: () => null,
    );
    final displayText = selectedItem != null
        ? displayMapper(selectedItem)
        : hint;

    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade500),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        child: Text(
          displayText,
          style: TextStyle(
            color: selectedItem != null ? Colors.black : Colors.grey.shade400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showSupplierSearch(
    BuildContext context,
    PurchaseProvider provider,
  ) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => SearchSelectorDialog(
        title: 'Supplier',
        items: provider.proveedores,
        displayMapper: (p) => (p as Proveedor).name,
        subtitleMapper: (p) => "RNC: ${(p as Proveedor).rnc ?? 'N/A'}",
        onAdd: () {
          Navigator.pop(context); // close
          // Add supplier logic if necessary
        },
      ),
    );

    if (result != null) {
      provider.updateProveedor(result);
    }
  }

  Widget _buildUploadCard() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade300,
          style: BorderStyle
              .none, // Can use dotted_border package ideally, we use solid or none
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                color: Colors.black,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Subir PDF de Factura',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tamaño máximo: 5MB (PDF, JPG, PNG)',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
