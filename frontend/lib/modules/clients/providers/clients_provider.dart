import 'package:flutter/material.dart';
import '../../../../models/client.dart';
import '../../../../services/client_service.dart';

class ClientsProvider extends ChangeNotifier {
  final ClientService _clientService = ClientService();

  List<Client> _clients = [];
  List<Client> _filteredClients = [];
  bool _isLoading = true;
  String? _error;

  // Filter states
  String _searchQuery = '';
  String _selectedType = 'Todos';
  String _selectedClassification = 'Todos';
  String _selectedStatus = 'Todos'; // 'Todos', 'Activos', 'Inactivos'

  // Selection for edit
  Client? _editingClient;
  bool _isAddingClient = false;

  // Getters
  List<Client> get clients => _clients;
  List<Client> get filteredClients => _filteredClients;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get searchQuery => _searchQuery;
  String get selectedType => _selectedType;
  String get selectedClassification => _selectedClassification;
  String get selectedStatus => _selectedStatus;

  Client? get editingClient => _editingClient;
  bool get isAddingClient => _isAddingClient;

  bool get isFilterActive =>
      _searchQuery.isNotEmpty ||
      _selectedType != 'Todos' ||
      _selectedClassification != 'Todos' ||
      _selectedStatus != 'Todos';

  ClientsProvider() {
    loadClients();
  }

  Future<void> loadClients() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _clients = await _clientService.getClients();
      _applyFilters();

      // Sync form if we are currently editing
      if (_editingClient != null) {
        _editingClient = _clients.firstWhere(
          (c) => c.id == _editingClient!.id,
          orElse: () => _editingClient!,
        );
      }
    } catch (e) {
      _error = 'Error al cargar clientes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setFilters({String? type, String? classification, String? status}) {
    if (type != null) _selectedType = type;
    if (classification != null) _selectedClassification = classification;
    if (status != null) _selectedStatus = status;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedType = 'Todos';
    _selectedClassification = 'Todos';
    _selectedStatus = 'Todos';
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredClients = _clients.where((client) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          client.name.toLowerCase().contains(query) ||
          client.code.toLowerCase().contains(query) ||
          (client.commercialName?.toLowerCase().contains(query) ?? false) ||
          (client.documentNumber?.toLowerCase().contains(query) ?? false);

      final matchesType =
          _selectedType == 'Todos' || client.type == _selectedType;

      final matchesClassification =
          _selectedClassification == 'Todos' ||
          client.classification == _selectedClassification;

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

  void selectClientForEdit(Client client) {
    _editingClient = client;
    _isAddingClient = false;
    notifyListeners();
  }

  void startAddingClient() {
    _editingClient = null;
    _isAddingClient = true;
    notifyListeners();
  }

  void cancelForm() {
    _editingClient = null;
    _isAddingClient = false;
    notifyListeners();
  }

  Future<void> toggleClientStatus(Client client) async {
    try {
      final updated = await _clientService.toggleActive(client.id!);
      final index = _clients.indexWhere((c) => c.id == client.id);
      if (index != -1) {
        _clients[index] = updated;
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveClient(Client client, bool isEdit) async {
    try {
      if (isEdit && _editingClient?.id != null) {
        await _clientService.updateClient(_editingClient!.id!, client);
      } else {
        await _clientService.createClient(client);
      }
      await loadClients();
      cancelForm();
    } catch (e) {
      rethrow;
    }
  }
}
