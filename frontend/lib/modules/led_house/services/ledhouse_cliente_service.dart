import 'package:http/http.dart' as http;
import '../models/ledhouse_cliente.dart';
import '../../../services/http_service.dart';

class LedhouseClienteService {
  final HttpService _http = HttpService();

  Future<List<LedhouseCliente>> getClientes({String? search}) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _http.get('ledhouse/clientes', params: queryParams);

    if (response != null) {
      return (response as List)
          .map((item) => LedhouseCliente.fromJson(item))
          .toList();
    }
    return [];
  }

  Future<LedhouseCliente> createCliente(LedhouseCliente cliente) async {
    final response = await _http.post('ledhouse/clientes', cliente.toJson());
    return LedhouseCliente.fromJson(response);
  }

  Future<LedhouseCliente> updateCliente(LedhouseCliente cliente) async {
    final response = await _http.put(
      'ledhouse/clientes/${cliente.id}',
      cliente.toJson(),
    );
    return LedhouseCliente.fromJson(response);
  }

  Future<void> deleteCliente(int id) async {
    await _http.delete('ledhouse/clientes/$id');
  }

  Future<Map<String, dynamic>> importExcel(
    List<int> fileBytes,
    String filename,
  ) async {
    final file = http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: filename,
    );

    final response = await _http.multipart(
      'ledhouse/clientes/import',
      files: [file],
    );

    return response as Map<String, dynamic>;
  }
}
