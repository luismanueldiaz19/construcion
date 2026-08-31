import '../../../../services/http_service.dart';
import '../models/cxc_model.dart';
import '../models/cxc_soporte_model.dart';

class CxcService {
  final HttpService _http = HttpService();

  Future<List<CxcModel>> getCxc() async {
    final response = await _http.get('ledhouse/cxc');
    return (response as List).map((item) => CxcModel.fromJson(item)).toList();
  }

  Future<CxcModel> createCxc(Map<String, dynamic> data) async {
    final response = await _http.post('ledhouse/cxc', data);
    return CxcModel.fromJson(response);
  }

  Future<CxcModel> updateCxc(int id, Map<String, dynamic> data) async {
    final response = await _http.put('ledhouse/cxc/$id', data);
    return CxcModel.fromJson(response);
  }

  Future<void> deleteCxc(int id) async {
    await _http.delete('ledhouse/cxc/$id');
  }

  Future<List<CxcSoporteModel>> getSoportes(int cxcId) async {
    final response = await _http.get('ledhouse/cxc/$cxcId/soporte');
    return (response as List)
        .map((item) => CxcSoporteModel.fromJson(item))
        .toList();
  }

  Future<CxcSoporteModel> addSoporte(
    int cxcId,
    Map<String, dynamic> data,
  ) async {
    final response = await _http.post('ledhouse/cxc/$cxcId/soporte', data);
    return CxcSoporteModel.fromJson(response);
  }

  Future<List<Map<String, dynamic>>> getGroupedByCliente() async {
    final response = await _http.get('ledhouse/cxc/grouped');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> importarExcel(int clienteId, List<int> bytes, String filename) async {
    final response = await _http.uploadFile(
      'ledhouse/cxc/import-by-cliente/$clienteId',
      bytes,
      filename,
    );
    return response as Map<String, dynamic>;
  }
}
