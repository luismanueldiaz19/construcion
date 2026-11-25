import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_theme.dart';
import '../../../../models/subpartida.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_dropdown.dart';
import '../../../../widgets/app_status_badge.dart';

/// Diálogo compacto para registrar un nuevo porcentaje de avance físico en una sub-partida.
class RegistrarAvanceDialog extends StatefulWidget {
  final Subpartida subpartida;

  const RegistrarAvanceDialog({super.key, required this.subpartida});

  static Future<double?> show(BuildContext context, Subpartida subpartida) {
    return showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RegistrarAvanceDialog(subpartida: subpartida),
    );
  }

  @override
  State<RegistrarAvanceDialog> createState() => _RegistrarAvanceDialogState();
}

class _RegistrarAvanceDialogState extends State<RegistrarAvanceDialog> {
  late List<double> _options;
  late double _selectedValue;

  @override
  void initState() {
    super.initState();
    final actual = widget.subpartida.avanceActual;
    final generated = <double>[
      for (double v = actual + 5.0; v < 100.0; v += 5.0) v,
      100.0,
    ];
    _options = generated.toSet().toList()..sort();
    _selectedValue = _options.first;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);
    final nuevoValorEjecutado =
        (_selectedValue / 100.0) * widget.subpartida.totalPresupuestado;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                    color: AppTheme.accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Registrar Avance Físico',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  AppStatusBadge(
                    label: 'Actual: ${widget.subpartida.avanceActual.toInt()}%',
                    type: AppStatusType.neutral,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.subpartida.descripcion,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Divider(height: 18, color: Color(0xFFE2E8F0)),
              AppDropdown<double>(
                labelText: 'Nuevo Avance (%)',
                value: _selectedValue,
                prefixIconData: Icons.percent_rounded,
                items: _options
                    .map(
                      (val) => DropdownMenuItem<double>(
                        value: val,
                        child: Text('${val.toInt()}%'),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedValue = val);
                },
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Valor ejecutado equivalente',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      currencyFmt.format(nuevoValorEjecutado),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
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
                      text: 'Guardar',
                      icon: Icons.check_rounded,
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.compact,
                      borderRadius: 9,
                      isFullWidth: true,
                      onPressed: () => Navigator.of(context).pop(_selectedValue),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
