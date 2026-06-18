import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/proyecto.dart';
import '../../../models/gasto_proyecto.dart';
import '../../../models/consumo_proyecto.dart';
import '../../../services/project_service.dart';
import '../../../services/inventory_service.dart';
import '../../../services/accounting_service.dart';

class ProjectDetailsProvider extends ChangeNotifier {
  final ProjectService _projectService = ProjectService();
  final InventoryService _inventoryService = InventoryService();
  final AccountingService _accountingService = AccountingService();
  final ImagePicker _picker = ImagePicker();

  Proyecto? _proyecto;
  List<GastoProyecto> _gastos = [];
  List<ConsumoProyecto> _consumos = [];
  List<dynamic> _pagos = [];
  bool _isLoading = true;
  String? _error;
  VoidCallback? _onRefreshCallback;

  Proyecto? get proyecto => _proyecto;
  List<GastoProyecto> get gastos => _gastos;
  List<ConsumoProyecto> get consumos => _consumos;
  List<dynamic> get pagos => _pagos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void init(Proyecto initialProyecto, {VoidCallback? onRefresh}) {
    _proyecto = initialProyecto;
    _onRefreshCallback = onRefresh;
    refresh();
  }

  Future<void> refresh() async {
    if (_proyecto == null) return;
    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      final updatedProyecto = await _projectService.getProyecto(_proyecto!.id!);
      final gastos = await _projectService.getGastosProyecto(_proyecto!.id!);
      final consumos = await _inventoryService.getConsumosProyecto(
        _proyecto!.id!,
      );

      List<dynamic> projectPagos = [];
      try {
        final allPagos = await _accountingService.getAllPagosHistorial();
        projectPagos = allPagos
            .where(
              (item) =>
                  item['proyecto'] == updatedProyecto.nombre &&
                  item['tipo'] == 'Cobro',
            )
            .toList();
      } catch (e) {
        debugPrint("Error fetching pagos: $e");
      }

      _proyecto = updatedProyecto;
      _gastos = gastos;
      _consumos = consumos;
      _pagos = projectPagos;

      if (_onRefreshCallback != null) {
        _onRefreshCallback!();
      }
    } catch (e) {
      debugPrint("Error refreshing project: $e");
      _error = 'Error al cargar detalles: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> provisionarTodo100() async {
    if (_proyecto == null) return;
    _setLoading(true);
    try {
      await _projectService.provisionarTodo100(_proyecto!.id!);
      await refresh();
    } catch (e) {
      _error = 'Error al provisionar: $e';
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> pickAndUploadLogo() async {
    if (_proyecto == null) return;
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      _setLoading(true);
      try {
        await _projectService.uploadLogo(_proyecto!.id!, image);
        await refresh();
      } catch (e) {
        _error = 'Error al subir logo: $e';
        _setLoading(false);
        rethrow;
      }
    }
  }

  Future<void> removeLogo() async {
    if (_proyecto == null) return;
    _setLoading(true);
    try {
      await _projectService.removeLogo(_proyecto!.id!);
      await refresh();
    } catch (e) {
      _error = 'Error al eliminar logo: $e';
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> cambiarEstado(String nuevoEstado) async {
    if (_proyecto == null) return;
    _setLoading(true);
    try {
      await _projectService.updateProyectoEstado(_proyecto!.id!, nuevoEstado);
      await refresh();
    } catch (e) {
      _error = 'Error al cambiar estado: $e';
      _setLoading(false);
      rethrow;
    }
  }

  // Agregamos getters para los servicios en caso de que algún diálogo los necesite directamente
  // (Aunque idealmente todo debería pasar por el provider)
  AccountingService get accountingService => _accountingService;
  ProjectService get projectService => _projectService;
  InventoryService get inventoryService => _inventoryService;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
