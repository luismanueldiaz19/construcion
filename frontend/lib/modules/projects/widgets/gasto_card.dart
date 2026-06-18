import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/gasto_proyecto.dart';

class GastoCard extends StatelessWidget {
  final GastoProyecto gasto;
  final VoidCallback onPrint;

  const GastoCard({super.key, required this.gasto, required this.onPrint});

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,##0.00', 'en_US');
    IconData icon = Icons.payments;
    Color color = Colors.blue;

    if (gasto.tipoGasto.contains('Mano de Obra')) {
      icon = Icons.engineering;
      color = Colors.orange;
    } else if (gasto.tipoGasto.contains('Alquiler')) {
      icon = Icons.construction;
      color = Colors.purple;
    } else if (gasto.tipoGasto.contains('Transporte')) {
      icon = Icons.local_shipping;
      color = Colors.cyan;
    }

    final fechaStr = gasto.fecha.toIso8601String().split('T')[0];
    final subpartidaInfo = gasto.subpartida != null
        ? " • Sub: ${gasto.subpartida!.descripcion}"
        : "";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color),
          ),
          title: Text(
            gasto.descripcion ?? 'Gasto sin descripción',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${gasto.proveedor?.name ?? gasto.proveedor?.commercialName ?? 'Sin proveedor'}",
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  "$fechaStr$subpartidaInfo",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "\$${f.format(gasto.monto)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.redAccent,
                    ),
                  ),
                  Text(
                    gasto.metodoPago,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                tooltip: 'Imprimir Recibo',
                onPressed: onPrint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
