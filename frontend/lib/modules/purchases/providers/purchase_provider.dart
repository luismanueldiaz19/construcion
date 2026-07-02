import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/project_service.dart';
import '../../../../services/inventory_service.dart';
import '../../../../services/purchase_service.dart';
import '../../../../models/proveedor.dart';

class PurchaseProvider extends ChangeNotifier {
  final ProjectService _projectService = ProjectService();
  final InventoryService _inventoryService = InventoryService();
  final PurchaseService _purchaseService = PurchaseService();

  int? selectedProveedorId;
  int? selectedProyectoId;
  String tipoCompra = 'Contado';
  DateTime fecha = DateTime.now();
  DateTime? fechaVencimiento;
  String? currentDraftId;

  List<dynamic> materiales = [];
  List<dynamic> proyectos = [];
  List<Proveedor> proveedores = [];
  List<Map<String, dynamic>> items = [];

  final TextEditingController ordenController = TextEditingController();
  final TextEditingController codigoController = TextEditingController();
  final TextEditingController comprobanteController = TextEditingController();
  final TextEditingController notaController = TextEditingController();

  bool isLoading = true;
  bool isSubmitting = false;
  String? error;

  PurchaseProvider() {
    loadData();
    addItem();
  }

  @override
  void dispose() {
    ordenController.dispose();
    codigoController.dispose();
    comprobanteController.dispose();
    notaController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final loadedMaterials = await _inventoryService.getMateriales();
      final loadedProjects = await _projectService.getProyectos(
        estado: 'Activo',
      );
      final loadedSuppliers = await _purchaseService.getProveedores();

      materiales = loadedMaterials;
      proyectos = loadedProjects.map((p) => p.toJson()).toList();
      proveedores = loadedSuppliers;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void addItem() {
    if (items.isNotEmpty) {
      final lastItem = items.last;
      if (lastItem['material_id'] == null) {
        return; // Ya hay una fila vacía, no hacemos nada ni lanzamos error
      }
    }

    items.add({'material_id': null, 'cantidad': 1.0, 'precio_unitario': 0.0});
    notifyListeners();
  }

  void removeItem(int index) {
    if (items.length > 1) {
      items.removeAt(index);
      notifyListeners();
    }
  }

  void updateItemMaterial(int index, int? materialId) {
    bool isDuplicate = items.any(
      (element) => element['material_id'] == materialId,
    );
    if (isDuplicate) {
      throw Exception('Este material ya ha sido agregado a la lista');
    }

    final item = items[index];
    item['material_id'] = materialId;

    final selectedMaterial = materiales.cast<dynamic>().firstWhere(
      (m) => m['id'] == materialId,
      orElse: () => null,
    );
    if (selectedMaterial != null) {
      item['precio_unitario'] =
          double.tryParse(
            selectedMaterial['precio_costo']?.toString() ?? '0',
          ) ??
          0.0;
    }
    notifyListeners();
  }

  void updateItemCantidad(int index, double cantidad) {
    items[index]['cantidad'] = cantidad;
    notifyListeners();
  }

  void updateItemPrecio(int index, double precio) {
    items[index]['precio_unitario'] = precio;
    notifyListeners();
  }

  void updateProveedor(int? id) {
    selectedProveedorId = id;
    notifyListeners();
  }

  void updateProyecto(int? id) {
    selectedProyectoId = id;
    notifyListeners();
  }

  void updateTipoCompra(String tipo) {
    tipoCompra = tipo;
    notifyListeners();
  }

  void updateFecha(DateTime newFecha) {
    fecha = newFecha;
    notifyListeners();
  }

  void updateFechaVencimiento(DateTime? newFecha) {
    fechaVencimiento = newFecha;
    notifyListeners();
  }

  Future<int?> submit() async {
    if (selectedProveedorId == null || selectedProyectoId == null) {
      throw Exception('Seleccione proveedor y proyecto');
    }

    final validItems = items
        .where((item) => item['material_id'] != null)
        .toList();

    if (validItems.isEmpty) {
      throw Exception('Debe agregar al menos un material a la compra');
    }

    isSubmitting = true;
    notifyListeners();

    try {
      final data = {
        'proveedor_id': selectedProveedorId,
        'proyecto_id': selectedProyectoId,
        'fecha': DateFormat('yyyy-MM-dd').format(fecha),
        'fecha_vencimiento': fechaVencimiento != null
            ? DateFormat('yyyy-MM-dd').format(fechaVencimiento!)
            : null,
        'tipo_compra': tipoCompra,
        'orden': ordenController.text,
        'codigo': codigoController.text,
        'comprobante': comprobanteController.text,
        'nota': notaController.text,
        'items': validItems
            .map(
              (item) => {
                'material_id': item['material_id'],
                'cantidad': item['cantidad'],
                'precio_unitario': item['precio_unitario'],
              },
            )
            .toList(),
      };

      final result = await _purchaseService.createCompra(data);
      await clearDraft(); // Clear draft on success
      _resetForm();
      return result['id']; // Return compra ID for PDF printing
    } catch (e) {
      throw Exception('Error al registrar compra: $e');
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void _resetForm() {
    selectedProveedorId = null;
    selectedProyectoId = null;
    tipoCompra = 'Contado';
    fecha = DateTime.now();
    fechaVencimiento = null;
    currentDraftId = null;
    ordenController.clear();
    codigoController.clear();
    comprobanteController.clear();
    notaController.clear();
    items = [
      {'material_id': null, 'cantidad': 1.0, 'precio_unitario': 0.0},
    ];
    notifyListeners();
  }

  // --- Draft functionality ---
  static const _draftsKey = 'purchase_drafts_list';

  Future<List<Map<String, dynamic>>> getDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final draftsStr = prefs.getString(_draftsKey);
    if (draftsStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(draftsStr);
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        debugPrint('Error loading drafts list: $e');
      }
    }
    return [];
  }

  Future<void> saveDraft(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final draftData = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
      'data': {
        'selectedProveedorId': selectedProveedorId,
        'selectedProyectoId': selectedProyectoId,
        'tipoCompra': tipoCompra,
        'fecha': fecha.toIso8601String(),
        'fechaVencimiento': fechaVencimiento?.toIso8601String(),
        'ordenController': ordenController.text,
        'codigoController': codigoController.text,
        'comprobanteController': comprobanteController.text,
        'notaController': notaController.text,
        'items': items,
      },
    };

    final drafts = await getDrafts();
    drafts.insert(0, draftData); // Put newest first
    await prefs.setString(_draftsKey, jsonEncode(drafts));
  }

  Future<void> loadDraft(String id) async {
    final drafts = await getDrafts();
    final draft = drafts.firstWhere((d) => d['id'] == id, orElse: () => {});
    if (draft.isEmpty) return;

    currentDraftId = id;

    final data = draft['data'] as Map<String, dynamic>;
    try {
      selectedProveedorId = data['selectedProveedorId'];
      selectedProyectoId = data['selectedProyectoId'];
      tipoCompra = data['tipoCompra'] ?? 'Contado';
      if (data['fecha'] != null) fecha = DateTime.parse(data['fecha']);
      if (data['fechaVencimiento'] != null)
        fechaVencimiento = DateTime.parse(data['fechaVencimiento']);
      ordenController.text = data['ordenController'] ?? '';
      codigoController.text = data['codigoController'] ?? '';
      comprobanteController.text = data['comprobanteController'] ?? '';
      notaController.text = data['notaController'] ?? '';

      if (data['items'] != null) {
        items = List<Map<String, dynamic>>.from(
          (data['items'] as List).map((i) => Map<String, dynamic>.from(i)),
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error applying draft data: $e');
    }
  }

  Future<void> deleteDraft(String id) async {
    final drafts = await getDrafts();
    drafts.removeWhere((d) => d['id'] == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftsKey, jsonEncode(drafts));
  }

  Future<void> clearDraft() async {
    if (currentDraftId != null) {
      await deleteDraft(currentDraftId!);
      currentDraftId = null;
    }
  }

  Future<void> quickAddMaterial(Map<String, dynamic> materialData) async {
    await _inventoryService.createMaterial(materialData);
    final updatedList = await _inventoryService.getMateriales();
    materiales = updatedList;
    notifyListeners();
  }

  Future<void> reloadProveedores() async {
    final updatedList = await _purchaseService.getProveedores();
    proveedores = updatedList;
    notifyListeners();
  }
}
