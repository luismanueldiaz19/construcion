import 'package:flutter/material.dart';
import '../../../models/client.dart';
import '../../../models/partida.dart';
import '../../../models/proyecto.dart';
import '../../../models/subpartida.dart';
import '../../../services/project_service.dart';
import '../../../widgets/app_alert.dart';

class ProjectFormProvider extends ChangeNotifier {
  final ProjectService _projectService = ProjectService();
  final formKey = GlobalKey<FormState>();

  int currentStep = 0;
  bool isLoading = false;

  final nombreController = TextEditingController();
  final ubicacionController = TextEditingController();
  DateTime? fechaInicio;
  DateTime? fechaFin;
  final itbisController = TextEditingController(text: '0');
  final transporteController = TextEditingController(text: '0');
  final supervisionController = TextEditingController(text: '0');
  final otrosCostosController = TextEditingController(text: '0');
  final notasController = TextEditingController();

  Client? selectedClient;
  String estado = 'Cotización';

  List<Map<String, dynamic>> partidas = [];

  int get totalSubpartidas => partidas.fold<int>(
        0,
        (sum, p) => sum + (p['subpartidas'] as List).length,
      );

  bool get hasUnsavedChanges =>
      nombreController.text.trim().isNotEmpty ||
      ubicacionController.text.trim().isNotEmpty ||
      notasController.text.trim().isNotEmpty ||
      selectedClient != null ||
      partidas.isNotEmpty;

  double partidaSubtotal(int pIndex) {
    if (pIndex < 0 || pIndex >= partidas.length) return 0;
    double total = 0;
    for (final s in (partidas[pIndex]['subpartidas'] as List)) {
      total += (s['cantidad'] as double) * (s['costo_unitario'] as double);
    }
    return total;
  }

  void setStep(int step) {
    if (step < 0 || step > 2 || step == currentStep) return;
    currentStep = step;
    notifyListeners();
  }

  void nextStep() {
    if (currentStep < 2) {
      currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }

  void setClient(Client? client) {
    selectedClient = client;
    notifyListeners();
  }

  void setFechaInicio(DateTime? date) {
    fechaInicio = date;
    notifyListeners();
  }

  void setFechaFin(DateTime? date) {
    fechaFin = date;
    notifyListeners();
  }

  void setEstado(String nuevoEstado) {
    estado = nuevoEstado;
    notifyListeners();
  }

  Map<String, dynamic> _normalizePartidaUppercase(
    Map<String, dynamic> partida,
  ) {
    final subs = (partida['subpartidas'] as List? ?? []).map((s) {
      final sub = Map<String, dynamic>.from(s as Map);
      sub['descripcion'] =
          (sub['descripcion']?.toString() ?? '').trim().toUpperCase();
      final ud = (sub['unidad']?.toString() ?? 'GL').trim().toUpperCase();
      sub['unidad'] = ud.isEmpty ? 'GL' : ud;
      return sub;
    }).toList();

    return {
      ...partida,
      'descripcion':
          (partida['descripcion']?.toString() ?? '').trim().toUpperCase(),
      'subpartidas': subs,
    };
  }

  void savePartidaData(Map<String, dynamic> partidaData, {int? editIndex}) {
    final normalized = _normalizePartidaUppercase(partidaData);
    if (editIndex != null && editIndex >= 0 && editIndex < partidas.length) {
      partidas[editIndex] = normalized;
    } else {
      partidas.add(normalized);
    }
    notifyListeners();
  }

  void addPartida() {
    partidas.add({
      'descripcion': '',
      'subpartidas': [
        {
          'descripcion': '',
          'unidad': 'GL',
          'cantidad': 0.0,
          'costo_unitario': 0.0,
        },
      ],
    });
    notifyListeners();
  }

  void removePartida(int index) {
    partidas.removeAt(index);
    notifyListeners();
  }

  void updatePartidaDescripcion(int pIndex, String value) {
    partidas[pIndex]['descripcion'] = value;
    notifyListeners();
  }

  Future<void> appendFromExcel(
    List<Map<String, dynamic>> importedPartidas,
  ) async {
    if (partidas.length == 1 &&
        partidas.first['descripcion'].toString().isEmpty &&
        (partidas.first['subpartidas'] as List).length == 1 &&
        (partidas.first['subpartidas'] as List).first['descripcion']
            .toString()
            .isEmpty) {
      partidas.clear();
      notifyListeners();
    }

    final normalizedImport =
        importedPartidas.map(_normalizePartidaUppercase).toList();

    const chunkSize = 5;
    for (var i = 0; i < normalizedImport.length; i += chunkSize) {
      final end = (i + chunkSize < normalizedImport.length)
          ? i + chunkSize
          : normalizedImport.length;
      partidas.addAll(normalizedImport.sublist(i, end));

      suggestItbis();
      suggestTransporte();
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 30));
    }
  }

  void clearAllPartidas() {
    partidas = [];
    suggestItbis();
    suggestTransporte();
    notifyListeners();
  }

  void addSubpartida(int pIndex) {
    (partidas[pIndex]['subpartidas'] as List).add({
      'descripcion': '',
      'unidad': 'GL',
      'cantidad': 0.0,
      'costo_unitario': 0.0,
    });
    notifyListeners();
  }

  void removeSubpartida(int pIndex, int sIndex) {
    (partidas[pIndex]['subpartidas'] as List).removeAt(sIndex);
    notifyListeners();
  }

  void updateSubpartida(int pIndex, int sIndex, String key, dynamic value) {
    (partidas[pIndex]['subpartidas'] as List)[sIndex][key] = value;
    notifyListeners();
  }

  double get subtotal {
    double total = 0;
    for (final p in partidas) {
      for (final s in (p['subpartidas'] as List)) {
        total += (s['cantidad'] as double) * (s['costo_unitario'] as double);
      }
    }
    return total;
  }

  double get totalFinal {
    return subtotal +
        (double.tryParse(itbisController.text) ?? 0) +
        (double.tryParse(transporteController.text) ?? 0) +
        (double.tryParse(supervisionController.text) ?? 0) +
        (double.tryParse(otrosCostosController.text) ?? 0);
  }

  void suggestTransporte() {
    transporteController.text = (subtotal * 0.04).toStringAsFixed(2);
    notifyListeners();
  }

  void suggestItbis() {
    itbisController.text = (subtotal * 0.18).toStringAsFixed(2);
    notifyListeners();
  }

  void forceUpdate() {
    notifyListeners();
  }

  Future<bool> saveProject(BuildContext context) async {
    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid || nombreController.text.trim().isEmpty) {
      currentStep = 0;
      notifyListeners();
      AppAlert.showToast(
        context,
        'Completa el nombre y los campos requeridos en Información.',
        type: AppAlertType.warning,
      );
      return false;
    }

    if (partidas.isEmpty) {
      currentStep = 1;
      notifyListeners();
      AppAlert.showToast(
        context,
        'Debes agregar al menos una partida en Presupuesto.',
        type: AppAlertType.warning,
      );
      return false;
    }

    isLoading = true;
    notifyListeners();

    try {
      final proyecto = Proyecto(
        nombre: nombreController.text.trim().toUpperCase(),
        cliente: selectedClient?.name ?? '',
        clientId: selectedClient?.id,
        ubicacion: ubicacionController.text.trim().toUpperCase(),
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        presupuestoEstimado: subtotal,
        itbis: double.tryParse(itbisController.text) ?? 0,
        transporte: double.tryParse(transporteController.text) ?? 0,
        supervisionTecnica: double.tryParse(supervisionController.text) ?? 0,
        otrosCostos: double.tryParse(otrosCostosController.text) ?? 0,
        estado: estado,
        notas: notasController.text.trim().toUpperCase(),
        partidas: partidas.map((p) {
          return Partida(
            codigo: '',
            descripcion: (p['descripcion']?.toString() ?? '').trim().toUpperCase(),
            subpartidas: (p['subpartidas'] as List).map((s) {
              final ud = (s['unidad']?.toString() ?? 'GL').trim().toUpperCase();
              return Subpartida(
                descripcion:
                    (s['descripcion']?.toString() ?? '').trim().toUpperCase(),
                unidad: ud.isEmpty ? 'GL' : ud,
                cantidad: s['cantidad'],
                costoUnitario: s['costo_unitario'],
                totalPresupuestado: s['cantidad'] * s['costo_unitario'],
              );
            }).toList(),
          );
        }).toList(),
      );

      await _projectService.createProyecto(proyecto);
      return true;
    } catch (e) {
      if (context.mounted) {
        AppAlert.showToast(
          context,
          'Error al guardar: $e',
          type: AppAlertType.error,
        );
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    ubicacionController.dispose();
    itbisController.dispose();
    transporteController.dispose();
    supervisionController.dispose();
    otrosCostosController.dispose();
    notasController.dispose();
    super.dispose();
  }
}
