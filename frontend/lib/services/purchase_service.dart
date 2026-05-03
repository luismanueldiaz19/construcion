import 'http_service.dart';

class PurchaseService {
  final HttpService _http = HttpService();

  Future<List<dynamic>> getProveedores() async {
    return await _http.get('proveedores');
  }

  Future<void> createProveedor(Map<String, dynamic> data) async {
    await _http.post('proveedores', data);
  }

  Future<void> updateProveedor(int id, Map<String, dynamic> data) async {
    await _http.put('proveedores/$id', data);
  }

  Future<Map<String, dynamic>> createCompra(Map<String, dynamic> data) async {
    return await _http.post('compras', data);
  }

  Future<List<dynamic>> getAllCompras() async {
    return await _http.get('compras');
  }

  Future<List<dynamic>> getComprasPendientes() async {
    return await _http.get('compras-pendientes');
  }

  Future<Map<String, dynamic>> getCompra(int id) async {
    return await _http.get('compras/$id');
  }

  Future<void> registrarRecepcion(Map<String, dynamic> data) async {
    await _http.post('recepciones', data);
  }

  Future<List<dynamic>> getAllGastos() async {
    return await _http.get('gastos');
  }

  Future<Map<String, dynamic>> getGasto(int id) async {
    return await _http.get('gastos/$id');
  }
}
