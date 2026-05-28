import 'http_service.dart';
import '../models/consumo_proyecto.dart';

class InventoryService {
  final HttpService _http = HttpService();

  Future<List<dynamic>> getMateriales() async {
    return await _http.get('materiales');
  }

  Future<void> createMaterial(Map<String, dynamic> data) async {
    await _http.post('materiales', data);
  }

  Future<void> updateMaterial(int id, Map<String, dynamic> data) async {
    await _http.put('materiales/$id', data);
  }

  Future<void> toggleMaterialEstado(int id) async {
    await _http.post('materiales/$id/toggle-estado', {});
  }

  Future<List<dynamic>> getCategorias() async {
    return await _http.get('categorias');
  }

  Future<Map<String, dynamic>> createCategoria(
    Map<String, dynamic> data,
  ) async {
    return await _http.post('categorias', data);
  }

  Future<List<dynamic>> getInventarioPorProyecto() async {
    return await _http.get('inventario-proyectos');
  }

  Future<Map<String, dynamic>> getInventarioDetalleProyecto(int id) async {
    return await _http.get('inventario-proyectos/$id');
  }

  Future<void> registrarConsumo(Map<String, dynamic> data) async {
    await _http.post('consumos', data);
  }

  Future<void> registrarTransferencia(Map<String, dynamic> data) async {
    await _http.post('transferencias', data);
  }

  Future<List<ConsumoProyecto>> getConsumosProyecto(int proyectoId) async {
    final data = await _http.get(
      'consumos',
      params: {'proyecto_id': proyectoId.toString()},
    );
    return (data as List)
        .map((json) => ConsumoProyecto.fromJson(json))
        .toList();
  }
}
