import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../models/avance_proyecto.dart';
import '../../../../models/consumo_proyecto.dart';
import '../../../../models/gasto_proyecto.dart';
import '../../../../models/partida.dart';
import '../../../../models/proyecto.dart';
import '../../../../models/subpartida.dart';
import '../../../../services/accounting_service.dart';
import '../../../../services/inventory_service.dart';
import '../../../../services/project_service.dart';
import '../../../../widgets/app_status_badge.dart';

/// Provider dedicado para la nueva vista de detalle de proyecto.
class ProjectDetailProvider extends ChangeNotifier {
  final ProjectService _projectService = ProjectService();
  final InventoryService _inventoryService = InventoryService();
  final AccountingService _accountingService = AccountingService();
  final ImagePicker _picker = ImagePicker();

  Proyecto? _proyecto;
  List<GastoProyecto> _gastos = [];
  List<ConsumoProyecto> _consumos = [];
  List<dynamic> _pagos = [];
  bool _isLoading = false;
  String? _error;
  VoidCallback? _onRefreshParent;

  Proyecto? get proyecto => _proyecto;
  List<GastoProyecto> get gastos => _gastos;
  List<ConsumoProyecto> get consumos => _consumos;
  List<dynamic> get pagos => _pagos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ProjectService get projectService => _projectService;
  InventoryService get inventoryService => _inventoryService;
  AccountingService get accountingService => _accountingService;

  double get presupuestoTotal {
    final p = _proyecto;
    if (p == null) return 0.0;
    if (p.totalPresupuestoConGlobales != null &&
        p.totalPresupuestoConGlobales! > 0) {
      return p.totalPresupuestoConGlobales!;
    }
    return p.presupuestoEstimado +
        p.itbis +
        p.transporte +
        p.supervisionTecnica +
        p.otrosCostos;
  }

  double get avanceFisico =>
      (_proyecto?.porcentajeAvanceTotal ?? 0.0).clamp(0.0, 100.0);

  double get totalCobrado => _proyecto?.totalCobrado ?? 0.0;

  double get saldoPendiente => (presupuestoTotal - totalCobrado).clamp(0.0, double.infinity);

  double get totalGastado =>
      _gastos.fold<double>(0.0, (sum, g) => sum + g.monto);

  double get gastosManoObra => _gastos
      .where((g) => g.tipoGasto.toLowerCase().contains('mano de obra'))
      .fold<double>(0.0, (sum, g) => sum + g.monto);

  double get gastosAlquiler => _gastos
      .where((g) => g.tipoGasto.toLowerCase().contains('alquiler'))
      .fold<double>(0.0, (sum, g) => sum + g.monto);

  double get gastosOtros => totalGastado - gastosManoObra - gastosAlquiler;

  Future<void> eliminarGasto(int gastoId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _projectService.deleteGastoProyecto(gastoId);
      await refresh();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  double gastosDePartida(Partida partida) {
    final ids = partida.subpartidas.map((s) => s.id).whereType<int>().toSet();
    return _gastos
        .where((g) => g.subpartidaId != null && ids.contains(g.subpartidaId))
        .fold<double>(0.0, (sum, g) => sum + g.monto);
  }

  List<ConsumoProyecto> consumosListDePartida(Partida partida) {
    final ids = partida.subpartidas.map((s) => s.id).whereType<int>().toSet();
    return _consumos
        .where((c) => c.subpartidaId != null && ids.contains(c.subpartidaId))
        .toList();
  }

  double consumosDePartida(Partida partida) =>
      consumosListDePartida(partida).fold<double>(0.0, (sum, c) => sum + c.total);

  double costoRealDePartida(Partida partida) =>
      gastosDePartida(partida) + consumosDePartida(partida);

  Future<void> registrarAvance(Subpartida sub, double porcentaje) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _projectService.createAvance(
        AvanceProyecto(
          partidaId: sub.partidaId,
          subpartidaId: sub.id!,
          fecha: DateTime.now(),
          porcentaje: porcentaje,
          valorEjecutado: (porcentaje / 100.0) * sub.totalPresupuestado,
        ),
      );
      await refresh();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> eliminarConsumo(int consumoId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _inventoryService.deleteConsumo(consumoId);
      await refresh();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  bool get isReadonly {
    final estado = _proyecto?.estado ?? '';
    return estado == 'Terminado' || estado == 'Cancelado';
  }

  List<String> get nextEstados {
    final estado = _proyecto?.estado ?? '';
    if (estado == 'Cotización') return const ['Activo', 'Cancelado'];
    if (estado == 'Activo') return const ['Terminado'];
    return const [];
  }

  AppStatusType get statusType {
    switch ((_proyecto?.estado ?? '').toLowerCase()) {
      case 'activo':
        return AppStatusType.active;
      case 'cotización':
      case 'cotizacion':
      case 'pendiente':
        return AppStatusType.pending;
      case 'terminado':
      case 'finalizado':
        return AppStatusType.info;
      case 'cancelado':
      case 'pausado':
        return AppStatusType.inactive;
      default:
        return AppStatusType.neutral;
    }
  }

  void init(Proyecto initialProyecto, {VoidCallback? onRefreshParent}) {
    _proyecto = initialProyecto;
    _onRefreshParent = onRefreshParent;
    refresh();
  }

  Future<void> initById(int proyectoId, {VoidCallback? onRefreshParent}) async {
    _onRefreshParent = onRefreshParent;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _proyecto = await _projectService.getProyecto(proyectoId);
      await refresh();
    } catch (e) {
      _error = 'Error al cargar el proyecto: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_proyecto?.id == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final id = _proyecto!.id!;
      final updatedProyecto = await _projectService.getProyecto(id);
      final gastos = await _projectService.getGastosProyecto(id);
      final consumos = await _inventoryService.getConsumosProyecto(id);

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
        debugPrint('Error fetching pagos: $e');
      }

      _proyecto = updatedProyecto;
      _gastos = gastos;
      _consumos = consumos;
      _pagos = projectPagos;
      _onRefreshParent?.call();
    } catch (e) {
      _error = 'Error al actualizar detalles: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> pickAndUploadLogo({ImageSource source = ImageSource.gallery, XFile? preselectedImage}) async {
    if (_proyecto?.id == null) return false;
    final XFile? image = preselectedImage ??
        await _picker.pickImage(
          source: source,
          imageQuality: 80,
          maxWidth: 1600,
          maxHeight: 1600,
        );
    if (image == null) return false;

    _isLoading = true;
    notifyListeners();
    try {
      await _projectService.uploadLogo(_proyecto!.id!, image);
      await refresh();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeLogo() async {
    if (_proyecto?.id == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      await _projectService.removeLogo(_proyecto!.id!);
      await refresh();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> actualizarProyectoDetalles(String nombre, String? notas) async {
    if (_proyecto?.id == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final updated = _proyecto!.copyWith(
        nombre: nombre.trim().toUpperCase(),
        notas: notas?.trim().toUpperCase(),
      );
      await _projectService.updateProyecto(_proyecto!.id!, updated);
      await refresh();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cambiarEstado(String nuevoEstado) async {
    if (_proyecto?.id == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      await _projectService.updateProyectoEstado(_proyecto!.id!, nuevoEstado);
      await refresh();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
