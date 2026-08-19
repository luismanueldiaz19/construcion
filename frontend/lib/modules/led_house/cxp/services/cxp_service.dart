import '../../../../services/http_service.dart';
import '../models/cxp_model.dart';

class CxpService {
  final HttpService _http = HttpService();

  Future<List<CxpModel>> getCxp() async {
    final response = await _http.get('ledhouse/cxp');
    return (response as List).map((item) => CxpModel.fromJson(item)).toList();
  }

  Future<CxpModel> createCxp(Map<String, dynamic> data) async {
    final response = await _http.post('ledhouse/cxp', data);
    return CxpModel.fromJson(response);
  }

  Future<CxpModel> updateCxp(int id, Map<String, dynamic> data) async {
    final response = await _http.put('ledhouse/cxp/$id', data);
    return CxpModel.fromJson(response);
  }
}
