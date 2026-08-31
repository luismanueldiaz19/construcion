import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../widgets/custom_button.dart';
import '../providers/cuenta_catalogo_provider.dart';
import '../models/cuenta_catalogo_model.dart';

class CuentaCatalogoScreen extends StatefulWidget {
  const CuentaCatalogoScreen({super.key});

  @override
  State<CuentaCatalogoScreen> createState() => _CuentaCatalogoScreenState();
}

class _CuentaCatalogoScreenState extends State<CuentaCatalogoScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CuentaCatalogoProvider>().fetchCuentas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CuentaCatalogoProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo Ledhouse')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar and Add Button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar por código o descripción',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: (value) {
                      context.read<CuentaCatalogoProvider>().setSearchQuery(
                        value,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                CustomButton(
                  text: 'Nueva Cuenta',
                  icon: Icons.add,
                  onPressed: () => _mostrarFormulario(context),
                ),
                const SizedBox(width: 8),
                CustomButton(
                  text: 'Importar',
                  icon: Icons.upload_file,
                  color: Colors.green,
                  onPressed: () => _importarExcel(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (provider.errorMessage.isNotEmpty)
              Text(
                provider.errorMessage,
                style: const TextStyle(color: Colors.red),
              ),

            // Data Table
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.cuentas.isEmpty
                  ? const Center(child: Text('No hay cuentas registradas'))
                  : ListView(
                      children: [
                        DataTable(
                          columns: const [
                            DataColumn(label: Text('Código')),
                            DataColumn(label: Text('Descripción')),
                            DataColumn(label: Text('Origen')),
                            DataColumn(label: Text('Acciones')),
                          ],
                          rows: provider.cuentas.map((cuenta) {
                            return DataRow(
                              cells: [
                                DataCell(Text(cuenta.codigo)),
                                DataCell(Text(cuenta.descripcion)),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getColorPorOrigen(
                                        cuenta.origen,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _getColorPorOrigen(
                                          cuenta.origen,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      cuenta.origen,
                                      style: TextStyle(
                                        color: _getColorPorOrigen(
                                          cuenta.origen,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () => _mostrarFormulario(
                                          context,
                                          cuenta: cuenta,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _confirmarEliminacion(
                                          context,
                                          cuenta,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFormulario(BuildContext context, {CuentaCatalogo? cuenta}) {
    showDialog(
      context: context,
      builder: (ctx) {
        return _CuentaCatalogoForm(cuenta: cuenta);
      },
    );
  }

  Color _getColorPorOrigen(String origen) {
    switch (origen) {
      case 'VENTAS':
        return Colors.green;
      case 'COSTOS':
        return Colors.orange;
      case 'GASTOS':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _confirmarEliminacion(BuildContext context, CuentaCatalogo cuenta) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Eliminar Cuenta'),
          content: Text(
            '¿Seguro que desea eliminar la cuenta ${cuenta.codigo}?',
          ),
          actions: [
            CustomButton(
              text: 'Cancelar',
              isOutlined: true,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            CustomButton(
              text: 'Eliminar',
              color: Colors.red,
              onPressed: () async {
                Navigator.of(ctx).pop();
                final success = await context
                    .read<CuentaCatalogoProvider>()
                    .deleteCuenta(cuenta.id!);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cuenta eliminada')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _importarExcel(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Importando...')));

        final provider = context.read<CuentaCatalogoProvider>();
        final success = await provider.importCuentas(file.bytes!, file.name);

        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Importación completada')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al importar: ${provider.errorMessage}'),
            ),
          );
        }
      }
    }
  }
}

class _CuentaCatalogoForm extends StatefulWidget {
  final CuentaCatalogo? cuenta;

  const _CuentaCatalogoForm({Key? key, this.cuenta}) : super(key: key);

  @override
  __CuentaCatalogoFormState createState() => __CuentaCatalogoFormState();
}

class __CuentaCatalogoFormState extends State<_CuentaCatalogoForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codigoController;
  late TextEditingController _descripcionController;
  String _origenSeleccionado = 'VENTAS';
  final List<String> _origenes = ['VENTAS', 'COSTOS', 'GASTOS'];

  @override
  void initState() {
    super.initState();
    _codigoController = TextEditingController(
      text: widget.cuenta?.codigo ?? '',
    );
    _descripcionController = TextEditingController(
      text: widget.cuenta?.descripcion ?? '',
    );
    if (widget.cuenta != null && _origenes.contains(widget.cuenta!.origen)) {
      _origenSeleccionado = widget.cuenta!.origen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.cuenta != null;
    return AlertDialog(
      title: Text(isEditing ? 'Editar Cuenta' : 'Nueva Cuenta'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codigoController,
                decoration: const InputDecoration(labelText: 'Código'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _origenSeleccionado,
                decoration: const InputDecoration(labelText: 'Origen'),
                items: _origenes.map((origen) {
                  return DropdownMenuItem(value: origen, child: Text(origen));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _origenSeleccionado = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        CustomButton(
          text: 'Cancelar',
          isOutlined: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
        CustomButton(
          text: 'Guardar',
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final data = {
                'codigo': _codigoController.text,
                'descripcion': _descripcionController.text,
                'origen': _origenSeleccionado,
              };

              final provider = context.read<CuentaCatalogoProvider>();
              bool success;

              if (isEditing) {
                success = await provider.updateCuenta(widget.cuenta!.id!, data);
              } else {
                success = await provider.addCuenta(data);
              }

              if (success) {
                if (mounted) Navigator.of(context).pop();
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${provider.errorMessage}')),
                  );
                }
              }
            }
          },
        ),
      ],
    );
  }
}
