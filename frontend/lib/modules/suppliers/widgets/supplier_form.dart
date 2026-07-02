import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_theme.dart';
import '../../../../models/proveedor.dart';
import '../providers/suppliers_provider.dart';

class SupplierForm extends StatefulWidget {
  const SupplierForm({super.key});

  @override
  State<SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends State<SupplierForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _commercialNameController =
      TextEditingController();
  final TextEditingController _rncController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactPositionController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _sectorController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _creditLimitController = TextEditingController();
  final TextEditingController _creditDaysController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _formType = 'empresa';
  String _formClassification = 'bueno';
  bool _formActive = true;
  bool _allowCredit = false;

  bool _isSavingForm = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    final provider = context.read<SuppliersProvider>();
    final proveedor = provider.editingProveedor;

    if (proveedor != null) {
      _codeController.text = proveedor.code ?? '';
      _nameController.text = proveedor.name;
      _commercialNameController.text = proveedor.commercialName ?? '';
      _rncController.text = proveedor.rnc ?? '';
      _contactNameController.text = proveedor.contactName ?? '';
      _contactPositionController.text = proveedor.contactPosition ?? '';
      _phoneController.text = proveedor.phone ?? '';
      _mobileController.text = proveedor.mobile ?? '';
      _whatsappController.text = proveedor.whatsapp ?? '';
      _emailController.text = proveedor.email ?? '';
      _countryController.text = proveedor.country ?? '';
      _provinceController.text = proveedor.province ?? '';
      _cityController.text = proveedor.city ?? '';
      _sectorController.text = proveedor.sector ?? '';
      _addressController.text = proveedor.address ?? '';
      _creditLimitController.text = proveedor.creditLimit.toStringAsFixed(2);
      _creditDaysController.text = proveedor.creditDays.toString();
      _notesController.text = proveedor.notes ?? '';
      _formType = proveedor.type;
      _formClassification = proveedor.classification;
      _formActive = proveedor.active;
      _allowCredit = proveedor.allowCredit;
    } else {
      _codeController.text =
          'PROV-${DateTime.now().millisecondsSinceEpoch % 1000000}';
      _creditLimitController.text = '0.00';
      _creditDaysController.text = '0';
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _commercialNameController.dispose();
    _rncController.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSavingForm = true);

    try {
      final provider = context.read<SuppliersProvider>();
      final isEdit = provider.editingProveedor != null;

      final newProveedor = Proveedor(
        id: isEdit ? provider.editingProveedor!.id : null,
        code: _codeController.text,
        type: _formType,
        name: _nameController.text,
        commercialName: _commercialNameController.text,
        rnc: _rncController.text,
        contactName: _contactNameController.text,
        contactPosition: _contactPositionController.text,
        phone: _phoneController.text,
        mobile: _mobileController.text,
        whatsapp: _whatsappController.text,
        email: _emailController.text,
        country: _countryController.text,
        province: _provinceController.text,
        city: _cityController.text,
        sector: _sectorController.text,
        address: _addressController.text,
        allowCredit: _allowCredit,
        creditLimit: double.tryParse(_creditLimitController.text) ?? 0.0,
        creditDays: int.tryParse(_creditDaysController.text) ?? 0,
        classification: _formClassification,
        active: _formActive,
        notes: _notesController.text,
      );

      await provider.saveProveedor(newProveedor, isEdit);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proveedor guardado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingForm = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SuppliersProvider>();
    final isEdit = provider.editingProveedor != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isEdit
                          ? Icons.edit_note_rounded
                          : Icons.person_add_alt_1_rounded,
                      color: AppTheme.accentColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEdit ? 'Editar Proveedor' : 'Nuevo Proveedor',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => provider.cancelForm(),
                ),
              ],
            ),
            const Divider(height: 32),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('INFORMACIÓN GENERAL'),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _codeController,
                            decoration: _inputDecoration('Código *', Icons.tag),
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _formType,
                            decoration: _inputDecoration(
                              'Tipo de Proveedor *',
                              null,
                            ),
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
                            onChanged: (val) =>
                                setState(() => _formType = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(
                        'Nombre / Razón Social *',
                        Icons.person_outline,
                      ),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _commercialNameController,
                            decoration: _inputDecoration(
                              'Nombre Comercial',
                              Icons.storefront_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _rncController,
                            decoration: _inputDecoration(
                              'RNC / Cédula',
                              Icons.badge_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle('DATOS DE CONTACTO'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _contactNameController,
                            decoration: _inputDecoration(
                              'Nombre Contacto',
                              Icons.contact_mail_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _contactPositionController,
                            decoration: _inputDecoration(
                              'Cargo / Puesto',
                              Icons.work_outline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: _inputDecoration(
                              'Teléfono',
                              Icons.phone_outlined,
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _mobileController,
                            decoration: _inputDecoration(
                              'Celular',
                              Icons.smartphone_outlined,
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _whatsappController,
                            decoration: _inputDecoration(
                              'WhatsApp',
                              Icons.chat_outlined,
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            decoration: _inputDecoration(
                              'Correo Electrónico',
                              Icons.email_outlined,
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle('UBICACIÓN'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _countryController,
                            decoration: _inputDecoration('País', Icons.public),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _provinceController,
                            decoration: _inputDecoration(
                              'Provincia',
                              Icons.map_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: _inputDecoration(
                              'Ciudad',
                              Icons.location_city,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _sectorController,
                            decoration: _inputDecoration(
                              'Sector',
                              Icons.holiday_village_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: _inputDecoration(
                        'Dirección Completa',
                        Icons.place_outlined,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle('CRÉDITO Y CLASIFICACIÓN'),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text(
                        'Permitir Crédito',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      value: _allowCredit,
                      onChanged: (val) => setState(() => _allowCredit = val),
                      activeColor: AppTheme.accentColor,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_allowCredit) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _creditLimitController,
                              decoration: _inputDecoration(
                                'Límite de Crédito',
                                Icons.attach_money,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _creditDaysController,
                              decoration: _inputDecoration(
                                'Días de Crédito',
                                Icons.calendar_today_outlined,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _formClassification,
                            decoration: _inputDecoration(
                              'Clasificación',
                              Icons.star_outline,
                            ),
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
                            onChanged: (val) =>
                                setState(() => _formClassification = val!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SwitchListTile(
                            title: const Text('Proveedor Activo'),
                            value: _formActive,
                            onChanged: (val) =>
                                setState(() => _formActive = val),
                            activeColor: Colors.green,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: _inputDecoration(
                        'Notas / Observaciones',
                        Icons.note_alt_outlined,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSavingForm
                        ? null
                        : () => provider.cancelForm(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'CANCELAR',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSavingForm ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSavingForm
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'GUARDAR',
                            style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppTheme.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.accentColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
