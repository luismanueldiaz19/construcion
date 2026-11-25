import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_theme.dart';
import '../../../models/client.dart';
import '../../../services/client_service.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_header_bar.dart';
import '../../../widgets/app_text_field.dart';

/// Pantalla integrada para crear o editar un Cliente con AppHeaderBar y campos en mayúsculas.
class ClientFormScreen extends StatefulWidget {
  final Client? client;

  const ClientFormScreen({super.key, this.client});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientService = ClientService();

  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _commercialNameCtrl;
  late final TextEditingController _docCtrl;
  late final TextEditingController _contactNameCtrl;
  late final TextEditingController _contactPosCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _whatsappCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _provinceCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _sectorCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _creditLimitCtrl;
  late final TextEditingController _creditDaysCtrl;
  late final TextEditingController _notesCtrl;

  late String _type;
  late String _classification;
  late bool _active;
  bool _isSaving = false;

  bool get _isEdit => widget.client != null;

  static final _decimalFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _codeCtrl = TextEditingController(
      text: c?.code ??
          'CLI-${(DateTime.now().millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0')}',
    );
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _commercialNameCtrl = TextEditingController(text: c?.commercialName ?? '');
    _docCtrl = TextEditingController(text: c?.documentNumber ?? '');
    _contactNameCtrl = TextEditingController(text: c?.contactName ?? '');
    _contactPosCtrl = TextEditingController(text: c?.contactPosition ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _mobileCtrl = TextEditingController(text: c?.mobile ?? '');
    _whatsappCtrl = TextEditingController(text: c?.whatsapp ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _countryCtrl =
        TextEditingController(text: c?.country ?? 'REPÚBLICA DOMINICANA');
    _provinceCtrl = TextEditingController(text: c?.province ?? '');
    _cityCtrl = TextEditingController(text: c?.city ?? '');
    _sectorCtrl = TextEditingController(text: c?.sector ?? '');
    _addressCtrl = TextEditingController(text: c?.address ?? '');
    _creditLimitCtrl = TextEditingController(
      text: c != null ? c.creditLimit.toStringAsFixed(2) : '0.00',
    );
    _creditDaysCtrl =
        TextEditingController(text: c != null ? c.creditDays.toString() : '0');
    _notesCtrl = TextEditingController(text: c?.notes ?? '');

    _type = c?.type ?? 'persona_fisica';
    _classification = c?.classification ?? 'bueno';
    _active = c?.active ?? true;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _commercialNameCtrl.dispose();
    _docCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPosCtrl.dispose();
    _phoneCtrl.dispose();
    _mobileCtrl.dispose();
    _whatsappCtrl.dispose();
    _emailCtrl.dispose();
    _countryCtrl.dispose();
    _provinceCtrl.dispose();
    _cityCtrl.dispose();
    _sectorCtrl.dispose();
    _addressCtrl.dispose();
    _creditLimitCtrl.dispose();
    _creditDaysCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String? _optUpper(TextEditingController ctrl) {
    final v = ctrl.text.trim();
    return v.isEmpty ? null : v.toUpperCase();
  }

  String? _optRaw(TextEditingController ctrl) {
    final v = ctrl.text.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final client = Client(
        id: widget.client?.id,
        code: _codeCtrl.text.trim().toUpperCase(),
        type: _type,
        name: _nameCtrl.text.trim().toUpperCase(),
        commercialName: _optUpper(_commercialNameCtrl),
        documentNumber: _optUpper(_docCtrl),
        contactName: _optUpper(_contactNameCtrl),
        contactPosition: _optUpper(_contactPosCtrl),
        phone: _optRaw(_phoneCtrl),
        mobile: _optRaw(_mobileCtrl),
        whatsapp: _optRaw(_whatsappCtrl),
        email: _optRaw(_emailCtrl),
        country: _optUpper(_countryCtrl),
        province: _optUpper(_provinceCtrl),
        city: _optUpper(_cityCtrl),
        sector: _optUpper(_sectorCtrl),
        address: _optUpper(_addressCtrl),
        creditLimit: double.tryParse(_creditLimitCtrl.text.trim()) ?? 0.0,
        creditDays: int.tryParse(_creditDaysCtrl.text.trim()) ?? 0,
        classification: _classification,
        active: _active,
        notes: _optUpper(_notesCtrl),
      );

      if (_isEdit && widget.client?.id != null) {
        await _clientService.updateClient(widget.client!.id!, client);
      } else {
        await _clientService.createClient(client);
      }

      if (mounted) {
        AppAlert.showToast(
          context,
          _isEdit
              ? 'Cliente actualizado correctamente.'
              : 'Cliente registrado correctamente.',
          type: AppAlertType.success,
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        AppAlert.showToast(
          context,
          'Error al guardar cliente: $e',
          type: AppAlertType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeaderBar(
        title: _isEdit ? 'EDITAR CLIENTE' : 'NUEVO CLIENTE',
        subtitle: _isEdit ? widget.client!.name : 'Directorio de clientes',
        badgeLetter: 'C',
        showMenuButton: false,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SectionHeader('Identificación'),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _Labeled(
                                'Código *',
                                AppTextField(
                                  controller: _codeCtrl,
                                  uppercase: true,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Requerido'
                                          : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AppDropdown<String>(
                                labelText: 'Tipo de Cliente',
                                value: _type,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'persona_fisica',
                                    child: Text('Persona Física'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'empresa',
                                    child: Text('Empresa'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'gobierno',
                                    child: Text('Gobierno'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'institucion',
                                    child: Text('Institución'),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _type = v ?? 'persona_fisica'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _Labeled(
                          'Nombre / Razón Social *',
                          AppTextField(
                            controller: _nameCtrl,
                            hintText: 'EJ: CONSTRUCTORA DEL CARIBE S.R.L.',
                            prefixIconData: Icons.person_outline_rounded,
                            uppercase: true,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Campo requerido'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _Labeled(
                                'Nombre Comercial',
                                AppTextField(
                                  controller: _commercialNameCtrl,
                                  hintText: 'Opcional',
                                  uppercase: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Labeled(
                                'RNC / Cédula',
                                AppTextField(
                                  controller: _docCtrl,
                                  hintText: 'EJ: 131-12345-6',
                                  uppercase: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: Color(0xFFE2E8F0)),

                        const _SectionHeader('Contacto'),
                        Row(
                          children: [
                            Expanded(
                              child: _Labeled(
                                'Teléfono',
                                AppTextField(
                                  controller: _phoneCtrl,
                                  hintText: '809-000-0000',
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Labeled(
                                'Celular / WhatsApp',
                                AppTextField(
                                  controller: _mobileCtrl,
                                  hintText: '829-000-0000',
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _Labeled(
                          'Correo Electrónico',
                          AppTextField(
                            controller: _emailCtrl,
                            hintText: 'correo@empresa.com',
                            prefixIconData: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _Labeled(
                                'Persona de Contacto',
                                AppTextField(
                                  controller: _contactNameCtrl,
                                  uppercase: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Labeled(
                                'Cargo',
                                AppTextField(
                                  controller: _contactPosCtrl,
                                  uppercase: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: Color(0xFFE2E8F0)),

                        const _SectionHeader('Ubicación'),
                        Row(
                          children: [
                            Expanded(
                              child: _Labeled(
                                'Provincia',
                                AppTextField(
                                  controller: _provinceCtrl,
                                  uppercase: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Labeled(
                                'Ciudad / Sector',
                                AppTextField(
                                  controller: _cityCtrl,
                                  uppercase: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _Labeled(
                          'Dirección',
                          AppTextField(
                            controller: _addressCtrl,
                            hintText: 'CALLE, NÚMERO, REFERENCIA...',
                            uppercase: true,
                          ),
                        ),
                        const Divider(height: 24, color: Color(0xFFE2E8F0)),

                        const _SectionHeader('Crédito y Clasificación'),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _Labeled(
                                'Límite de Crédito',
                                AppTextField(
                                  controller: _creditLimitCtrl,
                                  prefixText: '\$ ',
                                  textAlign: TextAlign.right,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: _decimalFormatters,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Labeled(
                                'Días Crédito',
                                AppTextField(
                                  controller: _creditDaysCtrl,
                                  textAlign: TextAlign.right,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        AppDropdown<String>(
                          labelText: 'Clasificación',
                          value: _classification,
                          items: const [
                            DropdownMenuItem(
                              value: 'excelente',
                              child: Text('Excelente'),
                            ),
                            DropdownMenuItem(
                              value: 'bueno',
                              child: Text('Bueno'),
                            ),
                            DropdownMenuItem(
                              value: 'regular',
                              child: Text('Regular'),
                            ),
                            DropdownMenuItem(
                              value: 'riesgoso',
                              child: Text('Riesgoso'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _classification = v ?? 'bueno'),
                        ),
                        const SizedBox(height: 10),
                        _Labeled(
                          'Notas',
                          AppTextField(
                            controller: _notesCtrl,
                            hintText: 'OBSERVACIONES DEL CLIENTE...',
                            uppercase: true,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          activeThumbColor: AppTheme.accentColor,
                          title: const Text(
                            'Cliente Activo',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          value: _active,
                          onChanged: (val) => setState(() => _active = val),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Barra inferior fija
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Cancelar',
                          variant: AppButtonVariant.outlined,
                          size: AppButtonSize.compact,
                          borderRadius: 9,
                          isFullWidth: true,
                          onPressed:
                              _isSaving ? null : () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppButton(
                          text: _isEdit ? 'Guardar' : 'Crear Cliente',
                          icon: Icons.check_rounded,
                          variant: AppButtonVariant.primary,
                          size: AppButtonSize.compact,
                          borderRadius: 9,
                          isFullWidth: true,
                          isLoading: _isSaving,
                          onPressed: _save,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
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
