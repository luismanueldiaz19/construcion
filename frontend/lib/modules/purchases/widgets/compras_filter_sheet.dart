import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../models/proyecto.dart';
import '../../../../models/proveedor.dart';
import '../../../../widgets/app_button.dart';
import '../providers/compras_report_provider.dart';

/// Modal ultra-compacto y ergonómico para filtrar compras.
/// Sigue los lineamientos de diseño de [flutter-small-widgets].
class ComprasFilterSheet extends StatefulWidget {
  const ComprasFilterSheet({super.key});

  static void show(BuildContext context) {
    final provider = context.read<ComprasReportProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: ChangeNotifierProvider.value(
              value: provider,
              child: const ComprasFilterSheet(),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const ComprasFilterSheet(),
        ),
      );
    }
  }

  @override
  State<ComprasFilterSheet> createState() => _ComprasFilterSheetState();
}

class _ComprasFilterSheetState extends State<ComprasFilterSheet> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ComprasReportProvider>(context);

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera compacta
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtros de Compras',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                color: const Color(0xFF64748B),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. Selector Proyecto
          _buildCompactDropdown<Proyecto?>(
            label: 'Proyecto',
            value: provider.selectedProyecto,
            items: [
              const DropdownMenuItem<Proyecto?>(
                value: null,
                child: Text('Todos los proyectos'),
              ),
              ...provider.proyectos.map((p) => DropdownMenuItem<Proyecto?>(
                    value: p,
                    child: Text(p.nombre),
                  )),
            ],
            onChanged: (val) => provider.setProyecto(val),
          ),
          const SizedBox(height: 10),

          // 2. Selector Proveedor
          _buildCompactDropdown<Proveedor?>(
            label: 'Proveedor',
            value: provider.selectedProveedor,
            items: [
              const DropdownMenuItem<Proveedor?>(
                value: null,
                child: Text('Todos los proveedores'),
              ),
              ...provider.proveedores.map((p) => DropdownMenuItem<Proveedor?>(
                    value: p,
                    child: Text(p.name),
                  )),
            ],
            onChanged: (val) => provider.setProveedor(val),
          ),
          const SizedBox(height: 10),

          // 3. Selector Estado
          _buildCompactDropdown<String?>(
            label: 'Estado de Pago',
            value: provider.selectedEstado,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Todos los estados'),
              ),
              ...provider.estados.map((s) => DropdownMenuItem<String?>(
                    value: s,
                    child: Text(s),
                  )),
            ],
            onChanged: (val) => provider.setEstado(val),
          ),
          const SizedBox(height: 10),

          // 4. Selector Rango de Fechas
          InkWell(
            onTap: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                initialDateRange: provider.selectedDateRange,
              );
              if (range != null) {
                provider.setDateRange(range);
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(6),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.selectedDateRange == null
                          ? 'Cualquier fecha'
                          : '${DateFormat('dd/MM/yy').format(provider.selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(provider.selectedDateRange!.end)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: provider.selectedDateRange == null
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (provider.selectedDateRange != null)
                    GestureDetector(
                      onTap: () => provider.setDateRange(null),
                      child: const Icon(Icons.clear, size: 14, color: Color(0xFF94A3B8)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Botones de acción compactos
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Limpiar',
                  variant: AppButtonVariant.outlined,
                  size: AppButtonSize.compact,
                  onPressed: () {
                    provider.clearFilters();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  text: 'Aplicar',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.compact,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(6),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF64748B)),
          style: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w500,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
