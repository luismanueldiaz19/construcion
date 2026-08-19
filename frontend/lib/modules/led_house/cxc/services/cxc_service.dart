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
}
