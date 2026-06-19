import 'package:flutter/material.dart';
import '../../../models/client.dart';
import '../../../models/partida.dart';
import '../../../models/proyecto.dart';
import '../../../models/subpartida.dart';
import '../../../services/project_service.dart';

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

  void setStep(int step) {
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
      // If the current list only has the default empty item, replace it
      partidas.clear();
      notifyListeners();
    }

    // Chunking the rendering to prevent UI freeze on very large lists
    const chunkSize = 5;
    for (var i = 0; i < importedPartidas.length; i += chunkSize) {
      final end = (i + chunkSize < importedPartidas.length)
          ? i + chunkSize
          : importedPartidas.length;
      partidas.addAll(importedPartidas.sublist(i, end));

      suggestItbis();
      suggestTransporte();
      notifyListeners();

      // Yield to the UI thread to render the chunk and keep animations smooth
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
    for (var p in partidas) {
      for (var s in (p['subpartidas'] as List)) {
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
    if (!formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos requeridos.'),
        ),
      );
      return false;
    }

    if (partidas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes agregar al menos una partida.')),
      );
      return false;
    }

    isLoading = true;
    notifyListeners();

    try {
      final proyecto = Proyecto(
        nombre: nombreController.text,
        cliente: selectedClient?.name ?? '',
        clientId: selectedClient?.id,
        ubicacion: ubicacionController.text,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        presupuestoEstimado: subtotal,
        itbis: double.tryParse(itbisController.text) ?? 0,
        transporte: double.tryParse(transporteController.text) ?? 0,
        supervisionTecnica: double.tryParse(supervisionController.text) ?? 0,
        otrosCostos: double.tryParse(otrosCostosController.text) ?? 0,
        estado: estado,
        notas: notasController.text,
        partidas: partidas.map((p) {
          return Partida(
            codigo: '',
            descripcion: p['descripcion'],
            subpartidas: (p['subpartidas'] as List).map((s) {
              return Subpartida(
                descripcion: s['descripcion'],
                unidad: s['unidad'],
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
