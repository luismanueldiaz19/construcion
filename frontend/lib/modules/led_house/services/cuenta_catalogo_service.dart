import 'package:http/http.dart' as http;
import '../models/cuenta_catalogo_model.dart';
import '../../../services/http_service.dart';

class CuentaCatalogoService {
  final HttpService _http = HttpService();

  Future<List<CuentaCatalogo>> fetchCuentas({String? search}) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _http.get(
      'ledhouse/cuentas-catalogo',
      params: queryParams,
    );

    if (response != null) {
      return (response as List)
          .map((item) => CuentaCatalogo.fromJson(item))
          .toList();
    }
    return [];
  }

  Future<CuentaCatalogo> storeCuenta(Map<String, dynamic> data) async {
    final response = await _http.post('ledhouse/cuentas-catalogo', data);
    return CuentaCatalogo.fromJson(response);
  }

  Future<CuentaCatalogo> updateCuenta(int id, Map<String, dynamic> data) async {
    final response = await _http.put('ledhouse/cuentas-catalogo/$id', data);
    return CuentaCatalogo.fromJson(response);
  }

  Future<void> deleteCuenta(int id) async {
    await _http.delete('ledhouse/cuentas-catalogo/$id');
  }

  Future<Map<String, dynamic>> importCuentas(
    List<int> fileBytes,
    String filename,
  ) async {
    final file = http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: filename,
    );

    final response = await _http.multipart(
      'ledhouse/cuentas-catalogo/import',
      files: [file],
    );

    return response as Map<String, dynamic>;
  }
}
