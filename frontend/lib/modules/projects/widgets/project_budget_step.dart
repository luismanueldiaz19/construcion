import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../core/utils/excel_parser.dart';
import '../providers/project_form_provider.dart';

class ProjectBudgetStep extends StatelessWidget {
  final NumberFormat formatter;

  const ProjectBudgetStep({super.key, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectFormProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          Icons.list_alt, 
          'Presupuesto Detallado',
          trailing: provider.partidas.isNotEmpty
              ? TextButton.icon(
                  onPressed: () => _confirmClearAll(context, provider),
                  icon: const Icon(Icons.delete_sweep, color: Colors.red),
                  label: const Text('Eliminar Todo', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                )
              : null,
        ),
        ...provider.partidas.asMap().entries.map(
          (e) => _PartidaCard(
            pIndex: e.key,
            partida: e.value,
            formatter: formatter,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: provider.addPartida,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text(
                'NUEVA PARTIDA',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _showExcelImportInstructions(context, provider),
              icon: const Icon(Icons.table_view),
              label: const Text(
                'IMPORTAR EXCEL',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionTitle(IconData icon, String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, ProjectFormProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('¿Eliminar todo?'),
          ],
        ),
        content: const Text('¿Estás seguro de que deseas eliminar todas las partidas y sub-partidas? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              provider.clearAllPartidas();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Todas las partidas han sido eliminadas'), 
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.delete_forever),
            label: const Text('SÍ, ELIMINAR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showExcelImportInstructions(
    BuildContext context,
    ProjectFormProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.green),
            SizedBox(width: 8),
            Text('Formato de Excel Requerido'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Para que la importación funcione correctamente, el archivo de Excel (.xlsx) debe tener estrictamente las siguientes columnas desde la fila 1:',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A: NO (Número de partida, ej: 1.00, 1.01)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'B: PARTIDAS (Descripción del trabajo)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'C: CANT. (Cantidad)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'D: UD (Unidad de medida, ej: M2, M3)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'E: PU (Precio Unitario)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nota: \n- Las filas donde CANT. esté vacío o sea 0, se tratarán como Categorías (Títulos de Partida).\n- Las filas con CANT. > 0 se tratarán como Sub-partidas y se agregarán a la categoría anterior.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              _importExcel(context, provider);
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('ENTENDIDO, SUBIR EXCEL'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importExcel(
    BuildContext context,
    ProjectFormProvider provider,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/logo.png', height: 80),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text(
                  'Importando Partidas...',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Por favor, espera un momento',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

      final result = await ExcelParser.parseBudgetExcel();

      // Close the loading dialog
      if (context.mounted) Navigator.pop(context);

      if (result != null && result.isNotEmpty) {
        await provider.appendFromExcel(result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '¡Importación exitosa! Se agregaron ${result.length} partidas.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        // Ensure loading dialog is closed even on error if it's still showing
        // Checking if we can pop might be tricky without a GlobalKey for the navigator,
        // but we'll try to pop it safely by checking the state or assuming it was popped if it failed before.
        // For safety, we just show the error.
        Navigator.of(context, rootNavigator: true).pop();

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              'Error de Importación',
              style: TextStyle(color: Colors.red),
            ),
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      }
    }
  }
}

class _PartidaCard extends StatelessWidget {
  final int pIndex;
  final Map<String, dynamic> partida;
  final NumberFormat formatter;

  const _PartidaCard({
    required this.pIndex,
    required this.partida,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ProjectFormProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.02),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  radius: 14,
                  child: Text(
                    '${pIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: partida['descripcion'],
                    onChanged: (v) =>
                        provider.updatePartidaDescripcion(pIndex, v),
                    decoration: const InputDecoration(
                      hintText: 'Nombre de la Partida (Ej: Cimentación)',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => provider.removePartida(pIndex),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...(partida['subpartidas'] as List).asMap().entries.map(
                  (e) => _SubpartidaRow(
                    pIndex: pIndex,
                    sIndex: e.key,
                    sub: e.value,
                    formatter: formatter,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => provider.addSubpartida(pIndex),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar Item'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubpartidaRow extends StatelessWidget {
  final int pIndex;
  final int sIndex;
  final Map<String, dynamic> sub;
  final NumberFormat formatter;

  const _SubpartidaRow({
    required this.pIndex,
    required this.sIndex,
    required this.sub,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ProjectFormProvider>();
    double rowTotal =
        (sub['cantidad'] as double) * (sub['costo_unitario'] as double);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildSubField(
                        initialValue: sub['descripcion'],
                        label: 'Descripción',
                        onChanged: (v) => provider.updateSubpartida(
                          pIndex,
                          sIndex,
                          'descripcion',
                          v,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: _buildSubField(
                        initialValue: sub['unidad'],
                        label: 'Unidad',
                        onChanged: (v) => provider.updateSubpartida(
                          pIndex,
                          sIndex,
                          'unidad',
                          v,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          provider.removeSubpartida(pIndex, sIndex),
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.orange,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildSubField(
                        initialValue: sub['cantidad'].toString(),
                        label: 'Cant.',
                        isNumber: true,
                        onChanged: (v) => provider.updateSubpartida(
                          pIndex,
                          sIndex,
                          'cantidad',
                          double.tryParse(v) ?? 0.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _buildSubField(
                        initialValue: sub['costo_unitario'].toString(),
                        label: 'Costo Unitario',
                        isNumber: true,
                        onChanged: (v) => provider.updateSubpartida(
                          pIndex,
                          sIndex,
                          'costo_unitario',
                          double.tryParse(v) ?? 0.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'TOTAL',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          FittedBox(
                            child: Text(
                              formatter.format(rowTotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
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

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: _buildSubField(
                  initialValue: sub['descripcion'],
                  label: 'Descripción',
                  onChanged: (v) => provider.updateSubpartida(
                    pIndex,
                    sIndex,
                    'descripcion',
                    v,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSubField(
                  initialValue: sub['unidad'],
                  label: 'Unidad',
                  onChanged: (v) =>
                      provider.updateSubpartida(pIndex, sIndex, 'unidad', v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSubField(
                  initialValue: sub['cantidad'].toString(),
                  label: 'Cant.',
                  isNumber: true,
                  onChanged: (v) => provider.updateSubpartida(
                    pIndex,
                    sIndex,
                    'cantidad',
                    double.tryParse(v) ?? 0.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildSubField(
                  initialValue: sub['costo_unitario'].toString(),
                  label: 'Costo U.',
                  isNumber: true,
                  onChanged: (v) => provider.updateSubpartida(
                    pIndex,
                    sIndex,
                    'costo_unitario',
                    double.tryParse(v) ?? 0.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(fontSize: 8, color: Colors.grey),
                    ),
                    FittedBox(
                      child: Text(
                        formatter.format(rowTotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => provider.removeSubpartida(pIndex, sIndex),
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.orange,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubField({
    required String initialValue,
    required String label,
    required Function(String) onChanged,
    bool isNumber = false,
  }) {
    return TextFormField(
      initialValue: initialValue == '0.0' ? '' : initialValue,
      onChanged: onChanged,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))]
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 10),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        border: InputBorder.none,
      ),
      style: const TextStyle(fontSize: 12),
    );
  }
}
