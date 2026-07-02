import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../../models/client.dart';
import '../providers/clients_provider.dart';

class ClientForm extends StatefulWidget {
  final bool isBottomSheet;
  final VoidCallback onCancel;

  const ClientForm({
    super.key,
    required this.isBottomSheet,
    required this.onCancel,
  });

  @override
  State<ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends State<ClientForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _commercialNameController;
  late TextEditingController _documentNumberController;
  late TextEditingController _contactNameController;
  late TextEditingController _contactPositionController;
  late TextEditingController _phoneController;
  late TextEditingController _mobileController;
  late TextEditingController _whatsappController;
  late TextEditingController _emailController;
  late TextEditingController _countryController;
  late TextEditingController _provinceController;
  late TextEditingController _cityController;
  late TextEditingController _sectorController;
  late TextEditingController _addressController;
  late TextEditingController _creditLimitController;
  late TextEditingController _creditDaysController;
  late TextEditingController _notesController;

  late String _formType;
  late String _formClassification;
  late bool _formActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ClientsProvider>();
    final editingClient = provider.editingClient;
    final isAdding = provider.isAddingClient;

    _codeController = TextEditingController(
      text: editingClient?.code ?? (isAdding ? 'CLI-${DateTime.now().millisecondsSinceEpoch % 1000000}' : ''),
    );
    _nameController = TextEditingController(text: editingClient?.name ?? '');
    _commercialNameController = TextEditingController(text: editingClient?.commercialName ?? '');
    _documentNumberController = TextEditingController(text: editingClient?.documentNumber ?? '');
    _contactNameController = TextEditingController(text: editingClient?.contactName ?? '');
    _contactPositionController = TextEditingController(text: editingClient?.contactPosition ?? '');
    _phoneController = TextEditingController(text: editingClient?.phone ?? '');
    _mobileController = TextEditingController(text: editingClient?.mobile ?? '');
    _whatsappController = TextEditingController(text: editingClient?.whatsapp ?? '');
    _emailController = TextEditingController(text: editingClient?.email ?? '');
    _countryController = TextEditingController(text: editingClient?.country ?? '');
    _provinceController = TextEditingController(text: editingClient?.province ?? '');
    _cityController = TextEditingController(text: editingClient?.city ?? '');
    _sectorController = TextEditingController(text: editingClient?.sector ?? '');
    _addressController = TextEditingController(text: editingClient?.address ?? '');
    _creditLimitController = TextEditingController(text: editingClient?.creditLimit.toStringAsFixed(2) ?? '0.00');
    _creditDaysController = TextEditingController(text: editingClient?.creditDays.toString() ?? '0');
    _notesController = TextEditingController(text: editingClient?.notes ?? '');

    _formType = editingClient?.type ?? 'persona_fisica';
    _formClassification = editingClient?.classification ?? 'bueno';
    _formActive = editingClient?.active ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _commercialNameController.dispose();
    _documentNumberController.dispose();
    _contactNameController.dispose();
    _contactPositionController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _sectorController.dispose();
    _addressController.dispose();
    _creditLimitController.dispose();
    _creditDaysController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);

    final provider = context.read<ClientsProvider>();
    final isEdit = provider.editingClient != null;

    final client = Client(
      id: provider.editingClient?.id,
      code: _codeController.text.trim(),
      type: _formType,
      name: _nameController.text.trim(),
      commercialName: _commercialNameController.text.trim().isEmpty ? null : _commercialNameController.text.trim(),
      documentNumber: _documentNumberController.text.trim().isEmpty ? null : _documentNumberController.text.trim(),
      contactName: _contactNameController.text.trim().isEmpty ? null : _contactNameController.text.trim(),
      contactPosition: _contactPositionController.text.trim().isEmpty ? null : _contactPositionController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      mobile: _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
      whatsapp: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
      province: _provinceController.text.trim().isEmpty ? null : _provinceController.text.trim(),
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      sector: _sectorController.text.trim().isEmpty ? null : _sectorController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      creditLimit: double.tryParse(_creditLimitController.text) ?? 0.0,
      creditDays: int.tryParse(_creditDaysController.text) ?? 0,
      classification: _formClassification,
      active: _formActive,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    try {
      await provider.saveClient(client, isEdit);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Cliente actualizado con éxito.' : 'Cliente registrado con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
        if (widget.isBottomSheet) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar cliente: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _conditionalExpanded({required bool isBottomSheet, required Widget child}) {
    return isBottomSheet ? child : Expanded(child: child);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClientsProvider>();
    final isEdit = provider.editingClient != null;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isEdit ? Icons.edit_note : Icons.person_add_alt_1,
                      color: AppTheme.accentColor,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEdit ? 'Editar Cliente' : 'Registrar Cliente',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (widget.isBottomSheet)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onCancel,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onCancel,
                    tooltip: 'Cancelar',
                  ),
              ],
            ),
            const Divider(height: 32),
            _conditionalExpanded(
              isBottomSheet: widget.isBottomSheet,
              child: ListView(
                shrinkWrap: true,
                physics: widget.isBottomSheet ? const NeverScrollableScrollPhysics() : null,
                children: [
                  _buildSectionHeader('INFORMACIÓN GENERAL'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _codeController,
                          decoration: _buildInputDec('Código *', Icons.tag),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: _formType,
                          decoration: _buildInputDec('Tipo de Cliente *', null),
                          items: const [
                            DropdownMenuItem(value: 'persona_fisica', child: Text('Persona Física')),
                            DropdownMenuItem(value: 'empresa', child: Text('Empresa')),
                            DropdownMenuItem(value: 'gobierno', child: Text('Gobierno')),
                            DropdownMenuItem(value: 'institucion', child: Text('Institución')),
                          ],
                          onChanged: (val) => setState(() => _formType = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: _buildInputDec('Nombre / Razón Social *', Icons.person_outline),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _commercialNameController,
                          decoration: _buildInputDec('Nombre Comercial', Icons.storefront),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _documentNumberController,
                          decoration: _buildInputDec('RNC / Cédula', Icons.badge_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('DATOS DE CONTACTO'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _contactNameController,
                          decoration: _buildInputDec('Nombre Contacto', Icons.contact_mail_outlined),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _contactPositionController,
                          decoration: _buildInputDec('Cargo / Puesto', Icons.work_outline),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _buildInputDec('Teléfono', Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          decoration: _buildInputDec('Celular', Icons.phone_android_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _whatsappController,
                          keyboardType: TextInputType.phone,
                          decoration: _buildInputDec('WhatsApp', Icons.chat_bubble_outline),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _buildInputDec('Correo Electrónico', Icons.email_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('CRÉDITO Y CLASIFICACIÓN'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _creditLimitController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          decoration: _buildInputDec('Límite de Crédito RD\$', Icons.attach_money),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _creditDaysController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: _buildInputDec('Días de Crédito', Icons.calendar_today_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _formClassification,
                    decoration: _buildInputDec('Clasificación Comercial *', null),
                    items: const [
                      DropdownMenuItem(value: 'excelente', child: Text('Excelente')),
                      DropdownMenuItem(value: 'bueno', child: Text('Bueno')),
                      DropdownMenuItem(value: 'regular', child: Text('Regular')),
                      DropdownMenuItem(value: 'riesgoso', child: Text('Riesgoso')),
                    ],
                    onChanged: (val) => setState(() => _formClassification = val!),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('DIRECCIÓN Y UBICACIÓN'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _countryController,
                          decoration: _buildInputDec('País', null),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _provinceController,
                          decoration: _buildInputDec('Provincia', null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: _buildInputDec('Ciudad', null),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _sectorController,
                          decoration: _buildInputDec('Sector', null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: _buildInputDec('Dirección Completa', Icons.location_on_outlined),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: _buildInputDec('Notas Adicionales', Icons.notes_outlined),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    value: _formActive,
                    title: const Text('Cliente Activo'),
                    subtitle: const Text('Alterna si este cliente puede ser utilizado en transacciones contables.'),
                    activeThumbColor: AppTheme.accentColor,
                    onChanged: (val) => setState(() => _formActive = val),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!widget.isBottomSheet) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('CANCELAR'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: widget.isBottomSheet ? 1 : 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveClient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            isEdit ? 'GUARDAR' : 'CREAR CLIENTE',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey,
        fontSize: 11,
        letterSpacing: 1.2,
      ),
    );
  }

  InputDecoration _buildInputDec(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
