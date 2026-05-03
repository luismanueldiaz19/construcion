import 'http_service.dart';

class DashboardService {
  final HttpService _http = HttpService();

  Future<Map<String, dynamic>> getDashboardData() async {
    return await _http.get('dashboard');
  }
}
