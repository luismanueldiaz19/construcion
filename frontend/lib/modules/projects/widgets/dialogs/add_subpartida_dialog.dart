import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/project_details_provider.dart';

class AddSubpartidaDialog extends StatefulWidget {
  final int partidaId;

  const AddSubpartidaDialog({super.key, required this.partidaId});

  @override
  State<AddSubpartidaDialog> createState() => _AddSubpartidaDialogState();
}

class _AddSubpartidaDialogState extends State<AddSubpartidaDialog> {
  final _subDescripcionController = TextEditingController();
  final _subCantidadController = TextEditingController(text: '1');
  final _subCostoController = TextEditingController(text: '0');
  final _subUnidadController = TextEditingController(text: 'GL');
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _subDescripcionController.dispose();
    _subCantidadController.dispose();
    _subCostoController.dispose();
    _subUnidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectDetailsProvider>(context, listen: false);

    return AlertDialog(
      title: const Text('Añadir Sub-partida'),
      content: SizedBox(
        width: 500,
        child: _isSaving
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _subDescripcionController,
                        decoration: const InputDecoration(labelText: 'Descripción Sub-partida', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _subUnidadController,
                              decoration: const InputDecoration(labelText: 'Unidad', border: OutlineInputBorder()),
                              validator: (v) => v!.isEmpty ? 'Req.' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _subCantidadController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                              decoration: const InputDecoration(labelText: 'Cant.', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _subCostoController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                              decoration: const InputDecoration(labelText: 'Costo Unit.', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _isSaving = true);
                  try {
                    await provider.projectService.addSubpartida(widget.partidaId, {
                      'descripcion': _subDescripcionController.text,
                      'unidad': _subUnidadController.text,
                      'cantidad': double.tryParse(_subCantidadController.text) ?? 1,
                      'costo_unitario': double.tryParse(_subCostoController.text) ?? 0,
                    });
                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  } catch (e) {
                    setState(() => _isSaving = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
          child: const Text('Añadir Sub-partida'),
        ),
      ],
    );
  }
}
