import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../core/app_theme.dart';
import '../../../services/accounting_service.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_date_picker_field.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_status_badge.dart';
import '../../../widgets/app_text_field.dart';

/// Modal inferior compacto para registrar un cobro / abono de una cuenta por cobrar.
class RegistrarCobroSheet extends StatefulWidget {
  final Map<String, dynamic> cuenta;
  final List<dynamic> bancos;

  const RegistrarCobroSheet({
    super.key,
    required this.cuenta,
    required this.bancos,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Map<String, dynamic> cuenta,
    required List<dynamic> bancos,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RegistrarCobroSheet(cuenta: cuenta, bancos: bancos),
    );
  }

  @override
  State<RegistrarCobroSheet> createState() => _RegistrarCobroSheetState();
}

class _RegistrarCobroSheetState extends State<RegistrarCobroSheet> {
  final _formKey = GlobalKey<FormState>();
  final _accountingService = AccountingService();
  late final TextEditingController _montoCtrl;
  final _conceptoCtrl = TextEditingController();

  DateTime _fechaPago = DateTime.now();
  String _metodoPago = 'Transferencia';
  int? _selectedBancoId;
  PlatformFile? _comprobanteFile;
  bool _isSubmitting = false;

  static final _decimalFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
  ];

  double get _saldo =>
      double.tryParse(widget.cuenta['saldo']?.toString() ?? '0') ?? 0.0;

  @override
  void initState() {
    super.initState();
    _montoCtrl = TextEditingController(text: _saldo.toStringAsFixed(2));
    if (widget.bancos.isNotEmpty) {
      final defaultBanco = widget.bancos.firstWhere(
        (b) => b['nombre'].toString().toLowerCase().contains('banco'),
        orElse: () => widget.bancos.first,
      );
      _selectedBancoId = defaultBanco['id'] as int?;
    }
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _conceptoCtrl.dispose();
    super.dispose();
  }

  void _applyPercentage(double pct) {
    final val = (_saldo * pct / 100.0);
    setState(() => _montoCtrl.text = val.toStringAsFixed(2));
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _comprobanteFile = result.files.first);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final monto = double.tryParse(_montoCtrl.text.trim()) ?? 0.0;
    if (monto <= 0) {
      AppAlert.showToast(
        context,
        'Ingresa un monto válido mayor a 0.',
        type: AppAlertType.warning,
      );
      return;
    }
    if (monto > _saldo + 0.01) {
      AppAlert.showToast(
        context,
        'El monto no puede exceder el saldo pendiente.',
        type: AppAlertType.error,
      );
      return;
    }
    if (_selectedBancoId == null) {
      AppAlert.showToast(
        context,
        'Selecciona una cuenta o banco destino.',
        type: AppAlertType.warning,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      http.MultipartFile? fileParam;
      if (_comprobanteFile != null) {
        if (_comprobanteFile!.bytes != null) {
          fileParam = http.MultipartFile.fromBytes(
            'comprobante',
            _comprobanteFile!.bytes!,
            filename: _comprobanteFile!.name,
          );
        } else if (_comprobanteFile!.path != null) {
          fileParam = await http.MultipartFile.fromPath(
            'comprobante',
            _comprobanteFile!.path!,
          );
        }
      }

      await _accountingService.createPago(
        {
          'proyecto_id': widget.cuenta['id'],
          'monto': monto,
          'fecha': DateFormat('yyyy-MM-dd').format(_fechaPago),
          'metodo_pago': _metodoPago,
          'banco_id': _selectedBancoId,
          'comentario': _conceptoCtrl.text.trim().toUpperCase(),
        },
        file: fileParam,
      );

      if (mounted) {
        AppAlert.showToast(
          context,
          'Cobro registrado correctamente.',
          type: AppAlertType.success,
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        AppAlert.showToast(
          context,
          'Error al registrar cobro: $e',
          type: AppAlertType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);
    final proyecto = widget.cuenta['proyecto']?.toString() ?? 'Proyecto';
    final cliente = widget.cuenta['cliente']?.toString() ?? '';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.86,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 10, 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        color: AppTheme.accentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Registrar Cobro',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              cliente.isNotEmpty
                                  ? '$proyecto · $cliente'
                                  : proyecto,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppStatusBadge(
                        label: currencyFmt.format(_saldo),
                        type: AppStatusType.pending,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded, size: 19),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Botones rápidos de porcentaje
                        Row(
                          children: [25.0, 50.0, 75.0, 100.0].map((pct) {
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: pct < 100 ? 6 : 0,
                                ),
                                child: InkWell(
                                  onTap: () => _applyPercentage(pct),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${pct.toInt()}%',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _Labeled(
                                'Monto a Cobrar *',
                                AppTextField(
                                  controller: _montoCtrl,
                                  prefixText: '\$ ',
                                  textAlign: TextAlign.right,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: _decimalFormatters,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Requerido'
                                          : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AppDatePickerField(
                                labelText: 'Fecha de Cobro',
                                selectedDate: _fechaPago,
                                isClearable: false,
                                onDateChanged: (d) {
                                  if (d != null) {
                                    setState(() => _fechaPago = d);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        AppDropdown<String>(
                          labelText: 'Método de Pago',
                          value: _metodoPago,
                          prefixIconData: Icons.account_balance_wallet_outlined,
                          items: const [
                            DropdownMenuItem(
                              value: 'Transferencia',
                              child: Text('Transferencia'),
                            ),
                            DropdownMenuItem(
                              value: 'Efectivo',
                              child: Text('Efectivo'),
                            ),
                            DropdownMenuItem(
                              value: 'Cheque',
                              child: Text('Cheque'),
                            ),
                            DropdownMenuItem(
                              value: 'Depósito',
                              child: Text('Depósito'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _metodoPago = v ?? 'Transferencia'),
                        ),
                        const SizedBox(height: 10),

                        if (widget.bancos.isNotEmpty)
                          AppDropdown<int>(
                            labelText: 'Banco / Cuenta Destino',
                            value: _selectedBancoId,
                            prefixIconData: Icons.account_balance_outlined,
                            items: widget.bancos
                                .map(
                                  (b) => DropdownMenuItem<int>(
                                    value: b['id'] as int,
                                    child: Text(
                                      b['nombre']?.toString() ?? 'Banco',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedBancoId = v),
                          ),
                        const SizedBox(height: 10),

                        _Labeled(
                          'Concepto / Comentario',
                          AppTextField(
                            controller: _conceptoCtrl,
                            hintText: 'EJ: ABONO CUBICACIÓN #1...',
                            uppercase: true,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Adjuntar comprobante
                        Row(
                          children: [
                            AppButton(
                              text: _comprobanteFile == null
                                  ? 'Adjuntar Comprobante'
                                  : 'Cambiar Archivo',
                              icon: Icons.attach_file_rounded,
                              size: AppButtonSize.compact,
                              variant: AppButtonVariant.outlined,
                              borderRadius: 8,
                              onPressed: _pickFile,
                            ),
                            if (_comprobanteFile != null) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _comprobanteFile!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: AppTheme.dangerColor,
                                ),
                                onPressed: () =>
                                    setState(() => _comprobanteFile = null),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Cancelar',
                            variant: AppButtonVariant.outlined,
                            size: AppButtonSize.compact,
                            borderRadius: 9,
                            isFullWidth: true,
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton(
                            text: 'Confirmar Cobro',
                            icon: Icons.check_rounded,
                            variant: AppButtonVariant.primary,
                            size: AppButtonSize.compact,
                            borderRadius: 9,
                            isFullWidth: true,
                            isLoading: _isSubmitting,
                            onPressed: _submit,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  final String label;
  final Widget child;
  const _Labeled(this.label, this.child);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}
