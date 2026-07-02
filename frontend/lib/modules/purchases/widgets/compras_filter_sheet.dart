import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_theme.dart';
import '../../../../models/proyecto.dart';
import '../../../../models/proveedor.dart';
import '../providers/compras_report_provider.dart';
import '../../../../widgets/quick_date_filter.dart';

class ComprasFilterSheet extends StatelessWidget {
  const ComprasFilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ComprasReportProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtrar Compras',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: provider.searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar comprobante, ID, orden...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: provider.updateSearchQuery,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Proyecto>(
                value: provider.selectedProyecto,
                decoration: InputDecoration(
                  labelText: 'Proyecto',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: [
                  const DropdownMenuItem<Proyecto>(
                    value: null,
                    child: Text('Todos los proyectos'),
                  ),
                  ...provider.proyectos.map((p) => DropdownMenuItem<Proyecto>(
                        value: p,
                        child: Text(p.nombre),
                      )),
                ],
                onChanged: provider.setProyecto,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Proveedor>(
                value: provider.selectedProveedor,
                decoration: InputDecoration(
                  labelText: 'Proveedor',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: [
                  const DropdownMenuItem<Proveedor>(
                    value: null,
                    child: Text('Todos los proveedores'),
                  ),
                  ...provider.proveedores.map((p) => DropdownMenuItem<Proveedor>(
                        value: p,
                        child: Text(p.name),
                      )),
                ],
                onChanged: provider.setProveedor,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: provider.selectedEstado,
                decoration: InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Todos los estados'),
                  ),
                  ...provider.estados.map((s) => DropdownMenuItem<String>(
                        value: s,
                        child: Text(s),
                      )),
                ],
                onChanged: provider.setEstado,
              ),
              const SizedBox(height: 16),
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
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Rango de Fechas',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        provider.selectedDateRange == null
                            ? 'No seleccionado'
                            : '${DateFormat('dd/MM/yy').format(provider.selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(provider.selectedDateRange!.end)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Icon(Icons.date_range, size: 20, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: provider.clearFilters,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Limpiar Filtros', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Aplicar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
