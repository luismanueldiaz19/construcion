import 'package:http/http.dart' as http;
import '../models/ledhouse_estado_resultado_model.dart';
import '../../../services/http_service.dart';

class LedhouseService {
  final HttpService _http = HttpService();

  Future<List<LedhouseEstadoResultado>> fetchEstadoResultados({
    String? startDate,
    String? endDate,
    String? modulo,
    String? codigoCuenta,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (modulo != null) queryParams['modulo'] = modulo;
    if (codigoCuenta != null) queryParams['codigo_cuenta'] = codigoCuenta;

    final response = await _http.get(
      'ledhouse/estado-resultado',
      params: queryParams,
    );

    if (response != null && response['data'] != null) {
      return (response['data'] as List)
          .map((item) => LedhouseEstadoResultado.fromJson(item))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchSummary({
    String? startDate,
    String? endDate,
    String? modulo,
    String? codigoCuenta,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (modulo != null) queryParams['modulo'] = modulo;
    if (codigoCuenta != null) queryParams['codigo_cuenta'] = codigoCuenta;

    final response = await _http.get(
      'ledhouse/estado-resultado/summary',
      params: queryParams,
    );

    if (response != null) {
      return response as Map<String, dynamic>;
    }
    return {};
  }

  Future<Map<String, dynamic>> fetchMatrizAnual({int? year}) async {
    final queryParams = <String, String>{};
    if (year != null) queryParams['year'] = year.toString();

    final response = await _http.get(
      'ledhouse/estado-resultado/matriz',
      params: queryParams,
    );

    if (response != null) {
      return response as Map<String, dynamic>;
    }
    return {};
  }

  Future<LedhouseEstadoResultado> storeEstadoResultado(
    Map<String, dynamic> data,
  ) async {
    final response = await _http.post('ledhouse/estado-resultado', data);
    return LedhouseEstadoResultado.fromJson(response);
  }

  Future<LedhouseEstadoResultado> updateEstadoResultado(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _http.put('ledhouse/estado-resultado/$id', data);
    return LedhouseEstadoResultado.fromJson(response);
  }

  Future<void> deleteEstadoResultado(int id) async {
    await _http.delete('ledhouse/estado-resultado/$id');
  }

  Future<Map<String, dynamic>> importEstadoResultado(
    List<int> fileBytes,
    String filename,
    String fecha,
  ) async {
    final file = http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: filename,
    );

    final response = await _http.multipart(
      'ledhouse/estado-resultado/import',
      fields: {'fecha': fecha},
      files: [file],
    );

    return response as Map<String, dynamic>;
  }
}
