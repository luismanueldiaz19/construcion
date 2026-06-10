import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../models/client.dart';
import '../../services/client_service.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final ClientService _clientService = ClientService();
  List<Client> _clients = [];
  List<Client> _filteredClients = [];
  bool _isLoading = true;

  // Search and Filter controllers/states
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'Todos';
  String _selectedClassification = 'Todos';
  String _selectedStatus = 'Todos'; // 'Todos', 'Activos', 'Inactivos'

  // Form controllers and states
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _commercialNameController =
      TextEditingController();
  final TextEditingController _documentNumberController =
      TextEditingController();
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
  final TextEditingController _creditLimitController = TextEditingController(
    text: '0.00',
  );
  final TextEditingController _creditDaysController = TextEditingController(
    text: '0',
  );
  final TextEditingController _notesController = TextEditingController();

  String _formType = 'persona_fisica';
  String _formClassification = 'bueno';
  bool _formActive = true;

  Client? _editingClient;
  bool _isAddingClient = false;
  bool _isSavingForm = false;

  bool get _isFilterActive =>
      _searchController.text.isNotEmpty ||
      _selectedType != 'Todos' ||
      _selectedClassification != 'Todos' ||
      _selectedStatus != 'Todos';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onFilterChanged);
    _searchController.dispose();
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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _clientService.getClients();
      setState(() {
        _clients = data;
        _isLoading = false;
        _applyFilters();

        // Sync form if we are currently editing
        if (_editingClient != null) {
          final fresh = _clients.firstWhere(
            (c) => c.id == _editingClient!.id,
            orElse: () => _editingClient!,
          );
          _selectClientForEdit(fresh);
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar clientes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onFilterChanged() {
    setState(() {
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filteredClients = _clients.where((client) {
      // Search filter
      final query = _searchController.text.toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          client.name.toLowerCase().contains(query) ||
          client.code.toLowerCase().contains(query) ||
          (client.commercialName?.toLowerCase().contains(query) ?? false) ||
          (client.documentNumber?.toLowerCase().contains(query) ?? false);

      // Type filter
      final matchesType =
          _selectedType == 'Todos' || client.type == _selectedType;

      // Classification filter
      final matchesClassification =
          _selectedClassification == 'Todos' ||
          client.classification == _selectedClassification;

      // Status filter
      bool matchesStatus = true;
      if (_selectedStatus == 'Activos') {
        matchesStatus = client.active;
      } else if (_selectedStatus == 'Inactivos') {
        matchesStatus = !client.active;
      }

      return matchesSearch &&
          matchesType &&
          matchesClassification &&
          matchesStatus;
    }).toList();
  }

  void _selectClientForEdit(Client client) {
    setState(() {
      _editingClient = client;
      _isAddingClient = false;
      _codeController.text = client.code;
      _nameController.text = client.name;
      _commercialNameController.text = client.commercialName ?? '';
      _documentNumberController.text = client.documentNumber ?? '';
      _contactNameController.text = client.contactName ?? '';
      _contactPositionController.text = client.contactPosition ?? '';
      _phoneController.text = client.phone ?? '';
      _mobileController.text = client.mobile ?? '';
      _whatsappController.text = client.whatsapp ?? '';
      _emailController.text = client.email ?? '';
      _countryController.text = client.country ?? '';
      _provinceController.text = client.province ?? '';
      _cityController.text = client.city ?? '';
      _sectorController.text = client.sector ?? '';
      _addressController.text = client.address ?? '';
      _creditLimitController.text = client.creditLimit.toStringAsFixed(2);
      _creditDaysController.text = client.creditDays.toString();
      _notesController.text = client.notes ?? '';
      _formType = client.type;
      _formClassification = client.classification;
      _formActive = client.active;
    });
  }

  void _startAddingClient() {
    setState(() {
      _editingClient = null;
      _isAddingClient = true;
      // Auto-generate a sequential-looking unique client code
      _codeController.text =
          'CLI-${DateTime.now().millisecondsSinceEpoch % 1000000}';
      _nameController.clear();
      _commercialNameController.clear();
      _documentNumberController.clear();
      _contactNameController.clear();
      _contactPositionController.clear();
      _phoneController.clear();
      _mobileController.clear();
      _whatsappController.clear();
      _emailController.clear();
      _countryController.clear();
      _provinceController.clear();
      _cityController.clear();
      _sectorController.clear();
      _addressController.clear();
      _creditLimitController.text = '0.00';
      _creditDaysController.text = '0';
      _notesController.clear();
      _formType = 'persona_fisica';
      _formClassification = 'bueno';
      _formActive = true;
    });
  }

  void _cancelForm() {
    setState(() {
      _editingClient = null;
      _isAddingClient = false;
      _codeController.clear();
      _nameController.clear();
      _commercialNameController.clear();
      _documentNumberController.clear();
      _contactNameController.clear();
      _contactPositionController.clear();
      _phoneController.clear();
      _mobileController.clear();
      _whatsappController.clear();
      _emailController.clear();
      _countryController.clear();
      _provinceController.clear();
      _cityController.clear();
      _sectorController.clear();
      _addressController.clear();
      _creditLimitController.text = '0.00';
      _creditDaysController.text = '0';
      _notesController.clear();
      _formType = 'persona_fisica';
      _formClassification = 'bueno';
      _formActive = true;
    });
  }

  void _onEditClientPressed(Client client, bool isLargeScreen) {
    _selectClientForEdit(client);
    if (!isLargeScreen) {
      _showFormBottomSheet();
    }
  }

  void _onCreateClientPressed(bool isLargeScreen) {
    _startAddingClient();
    if (!isLargeScreen) {
      _showFormBottomSheet();
    }
  }

  Future<void> _toggleClientStatus(Client client) async {
    try {
      final updated = await _clientService.toggleActive(client.id!);
      setState(() {
        final index = _clients.indexWhere((c) => c.id == client.id);
        if (index != -1) {
          _clients[index] = updated;
          _applyFilters();
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updated.active
                  ? 'Cliente "${updated.name}" activado correctamente.'
                  : 'Cliente "${updated.name}" inactivado correctamente.',
            ),
            backgroundColor: updated.active ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estado del cliente: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFormBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 700),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: _buildClientForm(
                      isBottomSheet: true,
                      onStateChanged: () {
                        setModalState(() {});
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        _cancelForm();
      }
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtros de Clientes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar por nombre, código o RNC...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'Tipo de Cliente',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Todos',
                        child: Text('Todos los tipos'),
                      ),
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
                    onChanged: (val) {
                      setModalState(() => _selectedType = val!);
                      _onFilterChanged();
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedClassification,
                    decoration: InputDecoration(
                      labelText: 'Clasificación',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Todos',
                        child: Text('Todas las clasificaciones'),
                      ),
                      DropdownMenuItem(
                        value: 'excelente',
                        child: Text('Excelente'),
                      ),
                      DropdownMenuItem(value: 'bueno', child: Text('Bueno')),
                      DropdownMenuItem(
                        value: 'regular',
                        child: Text('Regular'),
                      ),
                      DropdownMenuItem(
                        value: 'riesgoso',
                        child: Text('Riesgoso'),
                      ),
                    ],
                    onChanged: (val) {
                      setModalState(() => _selectedClassification = val!);
                      _onFilterChanged();
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Estado de Actividad',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Todos',
                        child: Text('Todos los estados'),
                      ),
                      DropdownMenuItem(
                        value: 'Activos',
                        child: Text('Solo Activos'),
                      ),
                      DropdownMenuItem(
                        value: 'Inactivos',
                        child: Text('Solo Inactivos'),
                      ),
                    ],
                    onChanged: (val) {
                      setModalState(() => _selectedStatus = val!);
                      _onFilterChanged();
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _searchController.clear();
                              _selectedType = 'Todos';
                              _selectedClassification = 'Todos';
                              _selectedStatus = 'Todos';
                            });
                            _onFilterChanged();
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('LIMPIAR'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('APLICAR'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChips() {
    if (!_isFilterActive) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: [
          const Text(
            'Filtros activos: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                if (_searchController.text.isNotEmpty)
                  Chip(
                    label: Text('Buscar: "${_searchController.text}"'),
                    onDeleted: () {
                      _searchController.clear();
                      _onFilterChanged();
                    },
                    backgroundColor: Colors.blue[50],
                  ),
                if (_selectedType != 'Todos')
                  Chip(
                    label: Text('Tipo: ${_translateType(_selectedType)}'),
                    onDeleted: () {
                      setState(() => _selectedType = 'Todos');
                      _onFilterChanged();
                    },
                    backgroundColor: Colors.orange[50],
                  ),
                if (_selectedClassification != 'Todos')
                  Chip(
                    label: Text(
                      'Clasificación: ${_translateClassification(_selectedClassification)}',
                    ),
                    onDeleted: () {
                      setState(() => _selectedClassification = 'Todos');
                      _onFilterChanged();
                    },
                    backgroundColor: Colors.purple[50],
                  ),
                if (_selectedStatus != 'Todos')
                  Chip(
                    label: Text('Estado: $_selectedStatus'),
                    onDeleted: () {
                      setState(() => _selectedStatus = 'Todos');
                      _onFilterChanged();
                    },
                    backgroundColor: Colors.teal[50],
                  ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _selectedType = 'Todos';
                      _selectedClassification = 'Todos';
                      _selectedStatus = 'Todos';
                    });
                    _onFilterChanged();
                  },
                  child: const Text('Limpiar todo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCards() {
    final int total = _clients.length;
    final int activos = _clients.where((c) => c.active).length;
    final int inactivos = total - activos;
    final int conCredito = _clients.where((c) => c.creditLimit > 0).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double cardWidth = (constraints.maxWidth - 48) / 4;
          final bool useGrid = constraints.maxWidth < 750;

          if (useGrid) {
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                _buildMetricCard(
                  'Clientes Totales',
                  total.toString(),
                  Icons.people,
                  Colors.blue,
                ),
                _buildMetricCard(
                  'Activos',
                  activos.toString(),
                  Icons.check_circle_outline,
                  Colors.green,
                ),
                _buildMetricCard(
                  'Inactivos',
                  inactivos.toString(),
                  Icons.block_outlined,
                  Colors.red,
                ),
                _buildMetricCard(
                  'Con Crédito',
                  conCredito.toString(),
                  Icons.credit_card_outlined,
                  Colors.orange,
                ),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: cardWidth,
                child: _buildMetricCard(
                  'Clientes Totales',
                  total.toString(),
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: cardWidth,
                child: _buildMetricCard(
                  'Activos',
                  activos.toString(),
                  Icons.check_circle_outline,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: cardWidth,
                child: _buildMetricCard(
                  'Inactivos',
                  inactivos.toString(),
                  Icons.block_outlined,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: cardWidth,
                child: _buildMetricCard(
                  'Con Crédito',
                  conCredito.toString(),
                  Icons.credit_card_outlined,
                  Colors.orange,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, color.withValues(alpha: 0.03)],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conditionalExpanded({
    required bool isBottomSheet,
    required Widget child,
  }) {
    return isBottomSheet ? child : Expanded(child: child);
  }

  Widget _buildClientForm({
    required bool isBottomSheet,
    VoidCallback? onStateChanged,
  }) {
    final bool isEdit = _editingClient != null;

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
                if (isBottomSheet)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _cancelForm,
                    tooltip: 'Cancelar',
                  ),
              ],
            ),
            const Divider(height: 32),
            _conditionalExpanded(
              isBottomSheet: isBottomSheet,
              child: ListView(
                shrinkWrap: true,
                physics: isBottomSheet
                    ? const NeverScrollableScrollPhysics()
                    : null,
                children: [
                  const Text(
                    'INFORMACIÓN GENERAL',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _codeController,
                          decoration: InputDecoration(
                            labelText: 'Código *',
                            prefixIcon: const Icon(Icons.tag, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Código requerido'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          initialValue: _formType,
                          decoration: InputDecoration(
                            labelText: 'Tipo de Cliente *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                          onChanged: (val) {
                            setState(() => _formType = val!);
                            if (onStateChanged != null) onStateChanged();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre / Razón Social *',
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Nombre requerido'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _commercialNameController,
                          decoration: InputDecoration(
                            labelText: 'Nombre Comercial',
                            prefixIcon: const Icon(Icons.storefront, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _documentNumberController,
                          decoration: InputDecoration(
                            labelText: 'RNC / Cédula',
                            prefixIcon: const Icon(
                              Icons.badge_outlined,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'DATOS DE CONTACTO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _contactNameController,
                          decoration: InputDecoration(
                            labelText: 'Nombre Contacto',
                            prefixIcon: const Icon(
                              Icons.contact_mail_outlined,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _contactPositionController,
                          decoration: InputDecoration(
                            labelText: 'Cargo / Puesto',
                            prefixIcon: const Icon(
                              Icons.work_outline,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
                          decoration: InputDecoration(
                            labelText: 'Teléfono',
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Celular',
                            prefixIcon: const Icon(
                              Icons.phone_android_outlined,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
                          decoration: InputDecoration(
                            labelText: 'WhatsApp',
                            prefixIcon: const Icon(
                              Icons.chat_bubble_outline,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Correo Electrónico',
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'CRÉDITO Y CLASIFICACIÓN',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _creditLimitController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Límite de Crédito RD\$',
                            prefixIcon: const Icon(
                              Icons.attach_money,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _creditDaysController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Días de Crédito',
                            prefixIcon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _formClassification,
                    decoration: InputDecoration(
                      labelText: 'Clasificación Comercial *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'excelente',
                        child: Text('Excelente'),
                      ),
                      DropdownMenuItem(value: 'bueno', child: Text('Bueno')),
                      DropdownMenuItem(
                        value: 'regular',
                        child: Text('Regular'),
                      ),
                      DropdownMenuItem(
                        value: 'riesgoso',
                        child: Text('Riesgoso'),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() => _formClassification = val!);
                      if (onStateChanged != null) onStateChanged();
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'DIRECCIÓN Y UBICACIÓN',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _countryController,
                          decoration: InputDecoration(
                            labelText: 'País',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _provinceController,
                          decoration: InputDecoration(
                            labelText: 'Provincia',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
                          decoration: InputDecoration(
                            labelText: 'Ciudad',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _sectorController,
                          decoration: InputDecoration(
                            labelText: 'Sector',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Dirección Completa',
                      prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Notas Adicionales',
                      prefixIcon: const Icon(Icons.notes_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    value: _formActive,
                    title: const Text('Cliente Activo'),
                    subtitle: const Text(
                      'Alterna si este cliente puede ser utilizado en transacciones contables.',
                    ),
                    activeThumbColor: AppTheme.accentColor,
                    onChanged: (val) {
                      setState(() => _formActive = val);
                      if (onStateChanged != null) onStateChanged();
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isBottomSheet) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancelForm,
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
                  flex: isBottomSheet ? 1 : 2,
                  child: ElevatedButton(
                    onPressed: _isSavingForm
                        ? null
                        : () => _saveClient(isBottomSheet),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSavingForm
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
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

  Future<void> _saveClient(bool isBottomSheet) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSavingForm = true);

    final client = Client(
      id: _editingClient?.id,
      code: _codeController.text.trim(),
      type: _formType,
      name: _nameController.text.trim(),
      commercialName: _commercialNameController.text.trim().isEmpty
          ? null
          : _commercialNameController.text.trim(),
      documentNumber: _documentNumberController.text.trim().isEmpty
          ? null
          : _documentNumberController.text.trim(),
      contactName: _contactNameController.text.trim().isEmpty
          ? null
          : _contactNameController.text.trim(),
      contactPosition: _contactPositionController.text.trim().isEmpty
          ? null
          : _contactPositionController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      mobile: _mobileController.text.trim().isEmpty
          ? null
          : _mobileController.text.trim(),
      whatsapp: _whatsappController.text.trim().isEmpty
          ? null
          : _whatsappController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      country: _countryController.text.trim().isEmpty
          ? null
          : _countryController.text.trim(),
      province: _provinceController.text.trim().isEmpty
          ? null
          : _provinceController.text.trim(),
      city: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      sector: _sectorController.text.trim().isEmpty
          ? null
          : _sectorController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      creditLimit: double.tryParse(_creditLimitController.text) ?? 0.0,
      creditDays: int.tryParse(_creditDaysController.text) ?? 0,
      classification: _formClassification,
      active: _formActive,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    try {
      if (_editingClient != null) {
        await _clientService.updateClient(_editingClient!.id!, client);
      } else {
        await _clientService.createClient(client);
      }
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingClient != null
                  ? 'Cliente actualizado con éxito.'
                  : 'Cliente registrado con éxito.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      if (isBottomSheet && mounted) {
        Navigator.pop(context);
      }
      _cancelForm();
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
      if (mounted) {
        setState(() => _isSavingForm = false);
      }
    }
  }

  Widget _buildPlaceholderForm(bool isLargeScreen) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Detalles del Cliente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Seleccione un cliente de la lista para ver o editar sus datos, o presione "Nuevo Cliente" para registrar uno.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _onCreateClientPressed(isLargeScreen),
            icon: const Icon(Icons.person_add, size: 20),
            label: const Text('Registrar Cliente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _translateType(String type) {
    switch (type) {
      case 'persona_fisica':
        return 'Persona Física';
      case 'empresa':
        return 'Empresa';
      case 'gobierno':
        return 'Gobierno';
      case 'institucion':
        return 'Institución';
      default:
        return type;
    }
  }

  String _translateClassification(String classification) {
    switch (classification) {
      case 'excelente':
        return 'Excelente';
      case 'bueno':
        return 'Bueno';
      case 'regular':
        return 'Regular';
      case 'riesgoso':
        return 'Riesgoso';
      default:
        return classification;
    }
  }

  Color _getClassificationColor(String classification) {
    switch (classification) {
      case 'excelente':
        return Colors.green;
      case 'bueno':
        return Colors.blue;
      case 'regular':
        return Colors.orange;
      case 'riesgoso':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isLargeScreen = width > 1150;
    final f = NumberFormat.currency(symbol: '\$ ');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Directorio de Clientes'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          OutlinedButton.icon(
            onPressed: () => _showFilterBottomSheet(),
            icon: Icon(
              _isFilterActive ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _isFilterActive
                  ? AppTheme.accentColor
                  : AppTheme.textSecondary,
              size: 20,
            ),
            label: Text(
              'Filtrar',
              style: TextStyle(
                color: _isFilterActive
                    ? AppTheme.accentColor
                    : AppTheme.textSecondary,
                fontWeight: _isFilterActive
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _isFilterActive
                    ? AppTheme.accentColor
                    : Colors.grey[300]!,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _onCreateClientPressed(isLargeScreen),
            icon: const Icon(Icons.person_add),
            label: const Text('Nuevo Cliente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildMetricsCards(),
                _buildFilterChips(),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // List container
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _filteredClients.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No se encontraron clientes.',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 16,
                                        ),
                                      ),
                                    )
                                  : LayoutBuilder(
                                      builder: (context, constraints) {
                                        return SingleChildScrollView(
                                          scrollDirection: Axis.vertical,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                minWidth: constraints.maxWidth,
                                              ),
                                              child: DataTable(
                                                showCheckboxColumn: false,
                                                headingRowColor:
                                                    WidgetStateProperty.all(
                                                      Colors.grey[50],
                                                    ),
                                                columns: const [
                                                  DataColumn(
                                                    label: Text(
                                                      'Código',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'Nombre / Razón Social',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'RNC / Cédula',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'Tipo',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'Clasificación',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'Límite Crédito',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'Activo',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'Editar',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                rows: _filteredClients.map((
                                                  client,
                                                ) {
                                                  final bool isSelected =
                                                      _editingClient != null &&
                                                      _editingClient!.id ==
                                                          client.id;
                                                  return DataRow(
                                                    selected: isSelected,
                                                    onSelectChanged: (selected) {
                                                      if (selected != null &&
                                                          selected) {
                                                        _onEditClientPressed(
                                                          client,
                                                          isLargeScreen,
                                                        );
                                                      }
                                                    },
                                                    cells: [
                                                      DataCell(
                                                        Text(
                                                          client.code,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(client.name),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          client.documentNumber ??
                                                              'N/A',
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          _translateType(
                                                            client.type,
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                _getClassificationColor(
                                                                  client
                                                                      .classification,
                                                                ).withValues(
                                                                  alpha: 0.1,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            _translateClassification(
                                                              client
                                                                  .classification,
                                                            ),
                                                            style: TextStyle(
                                                              color: _getClassificationColor(
                                                                client
                                                                    .classification,
                                                              ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          f.format(
                                                            client.creditLimit,
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Switch(
                                                          value: client.active,
                                                          activeThumbColor:
                                                              AppTheme
                                                                  .accentColor,
                                                          onChanged: (val) {
                                                            _toggleClientStatus(
                                                              client,
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      DataCell(
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.edit_outlined,
                                                            color: Colors.blue,
                                                          ),
                                                          onPressed: () =>
                                                              _onEditClientPressed(
                                                                client,
                                                                isLargeScreen,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ),
                      ),
                      // Form container (split screen for large layouts)
                      if (isLargeScreen)
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 24.0,
                              bottom: 24.0,
                              right: 24.0,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: (_isAddingClient || _editingClient != null)
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.02,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: _buildClientForm(
                                        isBottomSheet: false,
                                      ),
                                    )
                                  : _buildPlaceholderForm(isLargeScreen),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
