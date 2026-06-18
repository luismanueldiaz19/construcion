import 'package:http/http.dart' as http;
import '../models/compra.dart';
import '../models/proveedor.dart';
import 'http_service.dart';

class PurchaseService {
  final HttpService _http = HttpService();

  Future<List<Proveedor>> getProveedores() async {
    final List<dynamic> data = await _http.get('proveedores');
    return data
        .map((json) => Proveedor.fromJson(json))
        .toList()
        .cast<Proveedor>();
  }

  Future<void> createProveedor(Proveedor proveedor) async {
    await _http.post('proveedores', proveedor.toJson());
  }

  Future<void> updateProveedor(int id, Proveedor proveedor) async {
    await _http.put('proveedores/$id', proveedor.toJson());
  }

  Future<Proveedor> toggleActiveProveedor(int id) async {
    final response = await _http.post('proveedores/$id/toggle-active', {});
    return Proveedor.fromJson(response);
  }

  Future<Map<String, dynamic>> createCompra(Map<String, dynamic> data) async {
    return await _http.post('compras', data);
  }

  Future<List<Compra>> getAllCompras() async {
    final List<dynamic> data = await _http.get('compras');
    return data.map((json) => Compra.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> getComprasReporte(
    Map<String, dynamic> filters,
    int page,
    int perPage,
  ) async {
    List<String> queryParams = ['page=$page', 'per_page=$perPage'];

    filters.forEach((key, value) {
      if (value != null &&
          value.toString().isNotEmpty &&
          value.toString() != 'Todos') {
        queryParams.add('$key=$value');
      }
    });

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.join('&')}'
        : '';
    return await _http.get('compras$queryString');
  }

  Future<List<Compra>> getComprasPendientes() async {
    final List<dynamic> data = await _http.get('compras-pendientes');
    return data.map((json) => Compra.fromJson(json)).toList();
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

  Future<dynamic> uploadDocumentoCompra(int compraId, String filePath) async {
    final file = await http.MultipartFile.fromPath('documento', filePath);
    return await _http.multipart('compras/$compraId/documentos', files: [file]);
  }

  Future<void> deleteDocumentoCompra(int documentoId) async {
    await _http.delete('compras/documentos/$documentoId');
  }
}
