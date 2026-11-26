import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/client.dart';
import '../services/client_service.dart';
import 'app_button.dart';
import 'app_text_field.dart';

/// Diálogo modal moderno, compacto y completo para registrar o editar un Cliente.
class ClienteDialog extends StatefulWidget {
  final Client? client;
  final ValueChanged<Client>? onSaved;

  const ClienteDialog({
    super.key,
    this.client,
    this.onSaved,
  });

  @override
  State<ClienteDialog> createState() => _ClienteDialogState();
}

class _ClienteDialogState extends State<ClienteDialog> {
  final _formKey = GlobalKey<FormState>();
  final ClientService _clientService = ClientService();

  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _commercialNameCtrl;
  late final TextEditingController _docNumberCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _creditLimitCtrl;
  late final TextEditingController _creditDaysCtrl;
  late final TextEditingController _notesCtrl;

  late String _type;
  late String _classification;
  late bool _active;
  bool _isSaving = false;

  bool get _isEdit => widget.client != null;

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
    _docNumberCtrl = TextEditingController(text: c?.documentNumber ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _mobileCtrl = TextEditingController(text: c?.mobile ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _addressCtrl = TextEditingController(text: c?.address ?? '');
    _cityCtrl = TextEditingController(text: c?.city ?? '');
    _creditLimitCtrl = TextEditingController(
      text: c != null ? c.creditLimit.toStringAsFixed(2) : '0.00',
    );
    _creditDaysCtrl = TextEditingController(
      text: c != null ? c.creditDays.toString() : '0',
    );
    _notesCtrl = TextEditingController(text: c?.notes ?? '');

    _type = c?.type ?? 'empresa';
    _classification = c?.classification ?? 'bueno';
    _active = c?.active ?? true;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _commercialNameCtrl.dispose();
    _docNumberCtrl.dispose();
    _phoneCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _creditLimitCtrl.dispose();
    _creditDaysCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre o razón social es obligatorio.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final clientData = Client(
      id: widget.client?.id,
      code: _codeCtrl.text.trim().isNotEmpty
          ? _codeCtrl.text.trim()
          : 'CLI-${(DateTime.now().millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0')}',
      type: _type,
      name: name,
      commercialName: _commercialNameCtrl.text.trim().isNotEmpty
          ? _commercialNameCtrl.text.trim()
          : null,
      documentNumber: _docNumberCtrl.text.trim().isNotEmpty
          ? _docNumberCtrl.text.trim()
          : null,
      phone: _phoneCtrl.text.trim().isNotEmpty
          ? _phoneCtrl.text.trim()
          : null,
      mobile: _mobileCtrl.text.trim().isNotEmpty
          ? _mobileCtrl.text.trim()
          : null,
      email: _emailCtrl.text.trim().isNotEmpty
          ? _emailCtrl.text.trim()
          : null,
      address: _addressCtrl.text.trim().isNotEmpty
          ? _addressCtrl.text.trim()
          : null,
      city: _cityCtrl.text.trim().isNotEmpty
          ? _cityCtrl.text.trim()
          : null,
      creditLimit: double.tryParse(_creditLimitCtrl.text.trim()) ?? 0.0,
      creditDays: int.tryParse(_creditDaysCtrl.text.trim()) ?? 0,
      classification: _classification,
      active: _active,
      notes: _notesCtrl.text.trim().isNotEmpty
          ? _notesCtrl.text.trim()
          : null,
    );

    try {
      final Client savedClient;
      if (_isEdit) {
        savedClient = await _clientService.updateClient(
          widget.client!.id!,
          clientData,
        );
      } else {
        savedClient = await _clientService.createClient(clientData);
      }

      if (mounted) {
        widget.onSaved?.call(savedClient);
        Navigator.pop(context, savedClient);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? 'Cliente "${savedClient.name}" actualizado.'
                  : 'Cliente "${savedClient.name}" registrado con éxito.',
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar cliente: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabecera Moderna Neo ERP
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF1E293B), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE31E24),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE31E24).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _isEdit
                          ? Icons.edit_note_rounded
                          : Icons.person_add_alt_1_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit ? 'EDITAR CLIENTE' : 'NUEVO CLIENTE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 1.5),
                        Text(
                          _isEdit
                              ? 'Modifique la información del cliente'
                              : 'Complete la información general y fiscal',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
            ),

            // Cuerpo del Formulario
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECCIÓN 1: DATOS FISCALES
                      _buildSectionHeader(
                        icon: Icons.badge_outlined,
                        title: 'DATOS FISCALES Y DE IDENTIFICACIÓN',
                      ),
                      const SizedBox(height: 10),

                      // Fila 1: Código + Tipo de Cliente
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: AppTextField(
                              controller: _codeCtrl,
                              labelText: 'Código *',
                              hintText: 'CLI-000001',
                              prefixIconData: Icons.tag_rounded,
                              validator: (val) => val == null || val.trim().isEmpty
                                  ? 'Obligatorio'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 5,
                            child: _buildTypeDropdown(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Fila 2: Nombre / Razón Social
                      AppTextField(
                        controller: _nameCtrl,
                        labelText: 'Nombre / Razón Social *',
                        hintText: 'Ej: Constructora del Norte S.R.L.',
                        prefixIconData: Icons.business_rounded,
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'El nombre es obligatorio'
                            : null,
                      ),
                      const SizedBox(height: 10),

                      // Fila 3: RNC / Cédula + Nombre Comercial
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _docNumberCtrl,
                              labelText: 'RNC / Cédula',
                              hintText: 'Ej: 131-00000-0',
                              prefixIconData: Icons.credit_card_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppTextField(
                              controller: _commercialNameCtrl,
                              labelText: 'Nombre Comercial',
                              hintText: 'Nombre de fantasía',
                              prefixIconData: Icons.storefront_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // SECCIÓN 2: CONTACTO Y UBICACIÓN
                      _buildSectionHeader(
                        icon: Icons.contact_phone_outlined,
                        title: 'CONTACTO Y UBICACIÓN',
                      ),
                      const SizedBox(height: 10),

                      // Fila 4: Teléfono + Celular
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _phoneCtrl,
                              labelText: 'Teléfono',
                              hintText: '809-555-0101',
                              prefixIconData: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppTextField(
                              controller: _mobileCtrl,
                              labelText: 'Celular / WhatsApp',
                              hintText: '829-555-0102',
                              prefixIconData: Icons.phone_android_rounded,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Fila 5: Correo Electrónico
                      AppTextField(
                        controller: _emailCtrl,
                        labelText: 'Correo Electrónico',
                        hintText: 'cliente@ejemplo.com',
                        prefixIconData: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),

                      // Fila 6: Dirección + Ciudad
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: AppTextField(
                              controller: _addressCtrl,
                              labelText: 'Dirección Completa',
                              hintText: 'Calle, número, sector',
                              prefixIconData: Icons.location_on_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 4,
                            child: AppTextField(
                              controller: _cityCtrl,
                              labelText: 'Ciudad',
                              hintText: 'Ej: Santo Domingo',
                              prefixIconData: Icons.apartment_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // SECCIÓN 3: CONDICIONES COMERCIALES
                      _buildSectionHeader(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'CONDICIONES COMERCIALES',
                      ),
                      const SizedBox(height: 10),

                      // Fila 7: Límite de Crédito + Días de Crédito + Clasificación
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _creditLimitCtrl,
                              labelText: 'Límite Crédito (RD\$)',
                              hintText: '0.00',
                              prefixIconData: Icons.attach_money_rounded,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppTextField(
                              controller: _creditDaysCtrl,
                              labelText: 'Días Crédito',
                              hintText: '0',
                              prefixIconData: Icons.calendar_today_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildClassificationDropdown(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer con Botones de Acción
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    text: 'Cancelar',
                    variant: AppButtonVariant.outlined,
                    size: AppButtonSize.compact,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  AppButton(
                    text: _isEdit ? 'Actualizar Cliente' : 'Guardar Cliente',
                    icon: Icons.check_rounded,
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.compact,
                    isLoading: _isSaving,
                    onPressed: _submitForm,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Tipo de Cliente',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _type,
              isExpanded: true,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A)),
              items: const [
                DropdownMenuItem(value: 'empresa', child: Text('Empresa / Jurídica')),
                DropdownMenuItem(value: 'persona_fisica', child: Text('Persona Física')),
                DropdownMenuItem(value: 'gobierno', child: Text('Gobierno')),
                DropdownMenuItem(value: 'institucion', child: Text('Institución')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _type = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassificationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Clasificación',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _classification,
              isExpanded: true,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A)),
              items: const [
                DropdownMenuItem(value: 'bueno', child: Text('Bueno')),
                DropdownMenuItem(value: 'excelente', child: Text('Excelente')),
                DropdownMenuItem(value: 'regular', child: Text('Regular')),
                DropdownMenuItem(value: 'riesgoso', child: Text('Riesgoso')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _classification = val);
              },
            ),
          ),
        ),
      ],
    );
  }
}
