import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_theme.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_status_badge.dart';
import '../../../../widgets/app_text_field.dart';

/// Diálogo dedicado para crear o editar una Partida con todas sus Sub-partidas.
class PartidaFormDialog extends StatefulWidget {
  final Map<String, dynamic>? initialPartida;
  final NumberFormat formatter;

  const PartidaFormDialog({
    super.key,
    this.initialPartida,
    required this.formatter,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    Map<String, dynamic>? initialPartida,
    required NumberFormat formatter,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PartidaFormDialog(
        initialPartida: initialPartida,
        formatter: formatter,
      ),
    );
  }

  @override
  State<PartidaFormDialog> createState() => _PartidaFormDialogState();
}

class _SubpartidaControllers {
  final TextEditingController descripcion;
  final TextEditingController unidad;
  final TextEditingController cantidad;
  final TextEditingController costoUnitario;

  _SubpartidaControllers({
    String descripcion = '',
    String unidad = 'GL',
    double cantidad = 0.0,
    double costoUnitario = 0.0,
  })  : descripcion = TextEditingController(text: descripcion),
        unidad = TextEditingController(text: unidad.isEmpty ? 'GL' : unidad),
        cantidad = TextEditingController(
          text: cantidad == 0.0 ? '' : _formatNum(cantidad),
        ),
        costoUnitario = TextEditingController(
          text: costoUnitario == 0.0 ? '' : _formatNum(costoUnitario),
        );

  static String _formatNum(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : value.toString();

  double get cantidadVal => double.tryParse(cantidad.text.trim()) ?? 0.0;
  double get costoVal => double.tryParse(costoUnitario.text.trim()) ?? 0.0;
  double get total => cantidadVal * costoVal;

  Map<String, dynamic> toMap() => {
        'descripcion': descripcion.text.trim().toUpperCase(),
        'unidad': unidad.text.trim().isEmpty
            ? 'GL'
            : unidad.text.trim().toUpperCase(),
        'cantidad': cantidadVal,
        'costo_unitario': costoVal,
      };

  void dispose() {
    descripcion.dispose();
    unidad.dispose();
    cantidad.dispose();
    costoUnitario.dispose();
  }
}

class _PartidaFormDialogState extends State<PartidaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _listScrollController = ScrollController();
  late final TextEditingController _nombreController;
  final List<_SubpartidaControllers> _items = [];

  static final List<TextInputFormatter> _decimalFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
  ];

  bool get _isEditing => widget.initialPartida != null;

  double get _partidaTotal =>
      _items.fold<double>(0.0, (sum, item) => sum + item.total);

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPartida;
    _nombreController = TextEditingController(
      text: initial?['descripcion']?.toString() ?? '',
    );

    final existingSubs = (initial?['subpartidas'] as List?) ?? [];
    if (existingSubs.isNotEmpty) {
      for (final s in existingSubs) {
        _items.add(
          _SubpartidaControllers(
            descripcion: s['descripcion']?.toString() ?? '',
            unidad: s['unidad']?.toString() ?? 'GL',
            cantidad: (s['cantidad'] as num?)?.toDouble() ?? 0.0,
            costoUnitario: (s['costo_unitario'] as num?)?.toDouble() ?? 0.0,
          ),
        );
      }
    } else {
      _items.add(_SubpartidaControllers());
    }
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    _nombreController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() => _items.add(_SubpartidaControllers()));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listScrollController.hasClients) {
        _listScrollController.animateTo(
          _listScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final result = <String, dynamic>{
      'descripcion': _nombreController.text.trim().toUpperCase(),
      'subpartidas': _items.map((e) => e.toMap()).toList(),
    };
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final listMaxHeight = (screenHeight * 0.34).clamp(160.0, 320.0);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera del diálogo
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 10, 10),
                child: Row(
                  children: [
                    Icon(
                      _isEditing
                          ? Icons.edit_note_rounded
                          : Icons.playlist_add_rounded,
                      color: AppTheme.accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isEditing ? 'Editar Partida' : 'Nueva Partida',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    AppStatusBadge(
                      label: widget.formatter.format(_partidaTotal),
                      type: AppStatusType.info,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Nombre de la partida + barra de agregar ítem (fijos arriba)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Nombre de la Partida *',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 5),
                    AppTextField(
                      controller: _nombreController,
                      hintText: 'EJ: PRELIMINARES, CIMENTACIÓN, ELÉCTRICO...',
                      prefixIconData: Icons.folder_outlined,
                      uppercase: true,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ingresa el nombre de la partida'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Sub-partidas / Ítems (${_items.length})',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        AppButton(
                          text: 'Agregar Ítem',
                          icon: Icons.add_rounded,
                          size: AppButtonSize.compact,
                          variant: AppButtonVariant.outlined,
                          borderRadius: 8,
                          onPressed: _addItem,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Lista scrollable de sub-partidas con altura acotada (~mitad de pantalla)
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: listMaxHeight),
                child: Scrollbar(
                  controller: _listScrollController,
                  thumbVisibility: _items.length > 2,
                  child: ListView.builder(
                    controller: _listScrollController,
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                    itemCount: _items.length,
                    itemBuilder: (_, i) => _SubpartidaDialogItem(
                      index: i,
                      item: _items[i],
                      canRemove: _items.length > 1,
                      formatter: widget.formatter,
                      decimalFormatters: _decimalFormatters,
                      onChanged: () => setState(() {}),
                      onRemove: () => _removeItem(i),
                    ),
                  ),
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Pie con botones cómodos
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Cancelar',
                        variant: AppButtonVariant.outlined,
                        size: AppButtonSize.compact,
                        borderRadius: 9,
                        isFullWidth: true,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        text: _isEditing ? 'Guardar' : 'Agregar',
                        icon: Icons.check_rounded,
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.compact,
                        borderRadius: 9,
                        isFullWidth: true,
                        onPressed: _save,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubpartidaDialogItem extends StatelessWidget {
  final int index;
  final _SubpartidaControllers item;
  final bool canRemove;
  final NumberFormat formatter;
  final List<TextInputFormatter> decimalFormatters;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _SubpartidaDialogItem({
    required this.index,
    required this.item,
    required this.canRemove,
    required this.formatter,
    required this.decimalFormatters,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Ítem #${index + 1}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              Text(
                formatter.format(item.total),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (canRemove) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: AppTheme.dangerColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: AppTextField(
                  controller: item.descripcion,
                  labelText: 'Descripción *',
                  hintText: 'EJ: TOPOGRAFÍA, EXCAVACIÓN...',
                  uppercase: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppTextField(
                  controller: item.unidad,
                  labelText: 'Ud.',
                  uppercase: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: item.cantidad,
                  labelText: 'Cantidad',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: decimalFormatters,
                  textAlign: TextAlign.right,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: AppTextField(
                  controller: item.costoUnitario,
                  labelText: 'Costo Unitario',
                  prefixText: '\$ ',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: decimalFormatters,
                  textAlign: TextAlign.right,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
