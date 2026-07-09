import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../models/compra.dart';
import '../../services/purchase_service.dart';
import '../../widgets/custom_text_field.dart';

class ReceptionScreen extends StatefulWidget {
  const ReceptionScreen({super.key});

  @override
  State<ReceptionScreen> createState() => _ReceptionScreenState();
}

class _ReceptionScreenState extends State<ReceptionScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  List<Compra> _comprasPendientes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _purchaseService.getComprasPendientes();
      setState(() {
        _comprasPendientes = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Recepción de Materiales en Obra'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _comprasPendientes.isEmpty
          ? const Center(child: Text('No hay compras pendientes de recepción'))
          : LayoutBuilder(
              builder: (context, constraints) {
                double cardWidth = constraints.maxWidth;
                if (constraints.maxWidth > 1200) {
                  cardWidth = (constraints.maxWidth - 48 - 32) / 3 - 0.1;
                } else if (constraints.maxWidth > 800) {
                  cardWidth = (constraints.maxWidth - 48 - 16) / 2 - 0.1;
                } else {
                  cardWidth =
                      constraints.maxWidth - 48; // full width minus padding
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: _comprasPendientes.map((c) {
                      return SizedBox(
                        width: cardWidth,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          shadowColor: Colors.black26,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        "FACTURA #${c.id}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade800,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      c.fecha,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  c.proveedor?.name ?? 'Proveedor Desconocido',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.business_center,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        c.proyecto?.nombre ??
                                            'Proyecto Desconocido',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: Divider(),
                                ),
                                const Text(
                                  "Materiales a recibir:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...(c.detalles ?? []).map((d) {
                                  double total = double.parse(
                                    d['cantidad'].toString(),
                                  );
                                  double recibido = double.parse(
                                    (d['cantidad_recibida'] ?? 0).toString(),
                                  );
                                  bool completo = recibido >= total;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          completo
                                              ? Icons.check_circle
                                              : Icons.pending,
                                          size: 16,
                                          color: completo
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade800,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text:
                                                      "${d['material']['nombre']} ",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text:
                                                      "($recibido / $total ${d['material']['unidad']})",
                                                  style: TextStyle(
                                                    color: completo
                                                        ? Colors.green
                                                        : Colors
                                                              .orange
                                                              .shade700,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Total Compra",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            f.format(c.total),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () => _confirmarRecepcion(c),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF004AAD,
                                          ),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.inventory,
                                          size: 18,
                                        ),
                                        label: const Text('Recibir'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }

  void _confirmarRecepcion(Compra compra) {
    final personController = TextEditingController();
    final Map<int, TextEditingController> itemControllers = {};

    for (var d in compra.detalles ?? []) {
      double pendiente =
          double.parse(d['cantidad'].toString()) -
          double.parse((d['cantidad_recibida'] ?? 0).toString());
      if (pendiente > 0) {
        itemControllers[d['id']] = TextEditingController(
          text: pendiente.toString(),
        );
      }
    }

    if (itemControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos los materiales ya han sido recibidos'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(Icons.inventory, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text('Recibir Materiales - Factura #${compra.id}'),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '¿Quién recibe los materiales?',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: personController,
                          hintText: 'Ej. Juan Pérez',
                          prefixIcon: const Icon(
                            Icons.person,
                            color: Colors.blue,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El nombre es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Cantidades Recibidas:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Divider(),
                        ...itemControllers.entries.map((entry) {
                          final d = (compra.detalles ?? []).firstWhere(
                            (element) => element['id'] == entry.key,
                          );
                          double total = double.parse(d['cantidad'].toString());
                          double yaRecibido = double.parse(
                            (d['cantidad_recibida'] ?? 0).toString(),
                          );
                          double pendiente = total - yaRecibido;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        d['material']['nombre'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'Pendiente: $pendiente ${d['material']['unidad']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange.shade800,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: CustomTextField(
                                    controller: entry.value,
                                    textAlign: TextAlign.right,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}'),
                                      ),
                                    ],
                                    hintText: '0.00',
                                    suffixText: ' ${d['material']['unidad']}',
                                    fillColor: Colors.blueGrey.shade50,
                                    isDense: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Requerido';
                                      double? qty = double.tryParse(value);
                                      if (qty == null) return 'Inválido';
                                      if (qty < 0) return 'Mínimo 0';
                                      if (qty > pendiente)
                                        return 'Máx $pendiente';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          List<Map<String, dynamic>> items = [];

                          itemControllers.forEach((id, controller) {
                            double qty = double.tryParse(controller.text) ?? 0;
                            if (qty > 0) {
                              items.add({
                                'compra_detalle_id': id,
                                'cantidad': qty,
                              });
                            }
                          });

                          if (items.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Debe recibir al menos una cantidad mayor a 0',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            isSubmitting = true;
                          });

                          try {
                            await _purchaseService.registrarRecepcion({
                              'compra_id': compra.id,
                              'fecha': DateFormat(
                                'yyyy-MM-dd',
                              ).format(DateTime.now()),
                              'recibido_por': personController.text,
                              'items': items,
                            });
                            if (context.mounted) {
                              Navigator.pop(context);
                              _loadData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Inventario actualizado correctamente',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() {
                              isSubmitting = false;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(isSubmitting ? 'Procesando...' : 'Dar Entrada'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
