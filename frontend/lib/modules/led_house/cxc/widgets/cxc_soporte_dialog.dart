import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/cxc_model.dart';
import '../providers/cxc_provider.dart';

class CxcSoporteDialog extends StatefulWidget {
  final CxcModel cxc;

  const CxcSoporteDialog({super.key, required this.cxc});

  @override
  State<CxcSoporteDialog> createState() => _CxcSoporteDialogState();
}

class _CxcSoporteDialogState extends State<CxcSoporteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notaController = TextEditingController();
  DateTime _fechaVisita = DateTime.now().add(const Duration(days: 1));
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CxcProvider>(context, listen: false).fetchSoportes(widget.cxc.id!);
    });
  }

  @override
  void dispose() {
    _notaController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = Provider.of<CxcProvider>(context, listen: false);

    final data = {
      'nota': _notaController.text.trim(),
      'fecha': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'fecha_visita': DateFormat('yyyy-MM-dd').format(_fechaVisita),
    };

    final success = await provider.addSoporte(widget.cxc.id!, data);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      _notaController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nota guardada'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${provider.error}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gestión de Cobro - ${widget.cxc.cliente}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lado izquierdo: Historial
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Historial de Intervenciones',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Consumer<CxcProvider>(
                            builder: (context, provider, child) {
                              if (provider.isLoadingSoportes) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (provider.soportes.isEmpty) {
                                return const Center(child: Text('No hay historial registrado.'));
                              }
                              return ListView.builder(
                                itemCount: provider.soportes.length,
                                itemBuilder: (context, index) {
                                  final soporte = provider.soportes[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: const Icon(Icons.phone_in_talk, color: Colors.blue),
                                      title: Text(soporte.nota),
                                      subtitle: Text('Gestión: ${soporte.fecha} | Próx. Visita: ${soporte.fechaVisita ?? 'N/A'}'),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  const VerticalDivider(),
                  const SizedBox(width: 24),
                  // Lado derecho: Formulario
                  Expanded(
                    flex: 2,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nueva Nota / Intervención',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _notaController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Nota de lo conversado',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (v) => v!.isEmpty ? 'La nota es requerida' : null,
                          ),
                          const SizedBox(height: 16),
                          const Text('Agendar Próxima Visita / Cobro:', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _fechaVisita,
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) setState(() => _fechaVisita = date);
                            },
                            child: IgnorePointer(
                              child: TextFormField(
                                key: ValueKey(_fechaVisita),
                                initialValue: DateFormat('dd/MM/yyyy').format(_fechaVisita),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.calendar_month, color: Colors.grey),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _save,
                              icon: _isSaving
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.save, color: Colors.white),
                              label: const Text('Guardar Gestión', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
