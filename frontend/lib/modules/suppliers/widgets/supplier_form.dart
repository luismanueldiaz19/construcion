import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_theme.dart';
import '../../../../models/proveedor.dart';
import '../providers/suppliers_provider.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_alert.dart';

/// Formulario modal ultra-compacto y moderno para creación y edición de proveedores.
/// Cumple estrictamente con la skill [flutter-small-widgets].
class SupplierForm extends StatefulWidget {
  final VoidCallback? onClose;
  const SupplierForm({super.key, this.onClose});

  @override
  State<SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends State<SupplierForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _commercialNameController = TextEditingController();
  final TextEditingController _rncController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactPositionController = TextEditingController();
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
        AppAlert.showToast(
          context,
          'Proveedor guardado exitosamente',
          type: AppAlertType.success,
        );
        widget.onClose?.call();
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

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera compacta y moderna
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isEdit ? Icons.edit_note_rounded : Icons.person_add_rounded,
                        color: AppTheme.accentColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEdit ? 'Editar Proveedor' : 'Nuevo Proveedor',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  tooltip: 'Cerrar',
                  onPressed: () {
                    provider.cancelForm();
                    widget.onClose?.call();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 10),

            // Contenido desplazable con campos ultra-compactos
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // SECCIÓN 1: INFORMACIÓN GENERAL
                    _buildSectionHeader('INFORMACIÓN GENERAL'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _codeController,
                            style: const TextStyle(fontSize: 12),
                            decoration: _inputDecoration('Código *', Icons.tag),
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _formType,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: _inputDecoration(
                              'Tipo de Proveedor *',
                              Icons.apartment_rounded,
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
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      decoration: _inputDecoration(
                        'Nombre / Razón Social *',
                        Icons.person_outline_rounded,
                      ),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _commercialNameController,
                            style: const TextStyle(fontSize: 12),
                            decoration: _inputDecoration(
                              'Nombre Comercial',
                              Icons.storefront_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _rncController,
                            style: const TextStyle(fontSize: 12),
                            decoration: _inputDecoration(
                              'RNC / Cédula',
                              Icons.badge_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // SECCIÓN 2: DATOS DE CONTACTO
                    _buildSectionHeader('DATOS DE CONTACTO'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _contactNameController,
                            style: const TextStyle(fontSize: 12),
                            decoration: _inputDecoration(
                              'Nombre Contacto',
                              Icons.contact_mail_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _contactPositionController,
                            style: const TextStyle(fontSize: 12),
                            decoration: _inputDecoration(
                              'Cargo / Puesto',
                              Icons.work_outline_rounded,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            style: const TextStyle(fontSize: 12),
                            decoration: _inputDecoration(
                              'Teléfono',
                              Icons.phone_outlined,
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _mobileController,
                            style: const TextStyle(fontSize: 12),
                            decoration: _inputDecoration(
                              'Celular',
                              Icons.smartphone_outlined,
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _whatsappController,
                            style: const TextStyle(fontSize: 12),
                            decoration: _inputDecoration(
                              'WhatsApp',
                              Icons.chat_outlined,
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            style: const TextStyle(fontSize: 12),
                            decoration: _inputDecoration(
                              'Correo Electrónico',
                              Icons.email_outlined,
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // SECCIÓN 3: UBICACIÓN
                    _buildSectionHeader('UBICACIÓN'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _countryController,
                            style: const TextStyle(fontSize: 12),
                            decoration: _inputDecoration('País', Icons.public),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _provinceController,
                            style: const TextStyle(fontSize: 12),
                            decoration: _inputDecoration(
                              'Provincia',
                              Icons.map_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            style: const TextStyle(fontSize: 12),
                            decoration: _inputDecoration(
                              'Ciudad',
                              Icons.location_city_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _sectorController,
                            style: const TextStyle(fontSize: 12),
                            decoration: _inputDecoration(
                              'Sector',
                              Icons.holiday_village_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressController,
                      style: const TextStyle(fontSize: 12),
                      decoration: _inputDecoration(
                        'Dirección Completa',
                        Icons.place_outlined,
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 12),

                    // SECCIÓN 4: CONDICIONES COMERCIALES Y CLASIFICACIÓN
                    _buildSectionHeader('CONDICIONES COMERCIALES Y ESTADO'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Permitir Crédito',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Transform.scale(
                            scale: 0.7,
                            child: Switch(
                              value: _allowCredit,
                              activeTrackColor: AppTheme.accentColor,
                              onChanged: (val) => setState(() => _allowCredit = val),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_allowCredit) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _creditLimitController,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                              decoration: _inputDecoration(
                                'Límite de Crédito',
                                Icons.attach_money_rounded,
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _creditDaysController,
                              style: const TextStyle(fontSize: 12),
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _formClassification,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                            decoration: _inputDecoration(
                              'Clasificación',
                              Icons.star_outline_rounded,
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'Activo',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                Transform.scale(
                                  scale: 0.65,
                                  child: Switch(
                                    value: _formActive,
                                    activeTrackColor: const Color(0xFF16A34A),
                                    onChanged: (val) =>
                                        setState(() => _formActive = val),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      style: const TextStyle(fontSize: 12),
                      decoration: _inputDecoration(
                        'Notas / Observaciones',
                        Icons.note_alt_outlined,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 10),

            // Barra inferior de botones alineada a la derecha
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  text: 'Cancelar',
                  variant: AppButtonVariant.outlined,
                  size: AppButtonSize.compact,
                  onPressed: _isSavingForm
                      ? null
                      : () {
                          provider.cancelForm();
                          widget.onClose?.call();
                        },
                ),
                const SizedBox(width: 8),
                AppButton(
                  text: 'Guardar Proveedor',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.compact,
                  isLoading: _isSavingForm,
                  onPressed: _save,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: AppTheme.accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData? icon) {
    return InputDecoration(
      isDense: true,
      labelText: label,
      labelStyle: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
      prefixIcon: icon != null
          ? Icon(icon, size: 16, color: const Color(0xFF64748B))
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.accentColor, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
    );
  }
}
