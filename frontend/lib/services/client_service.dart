import '../models/client.dart';
import 'http_service.dart';

class ClientService {
  final HttpService _http = HttpService();

  Future<List<Client>> getClients({
    String? search,
    String? type,
    String? classification,
    bool? active,
  }) async {
    final Map<String, String> queryParams = {};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (type != null && type.isNotEmpty) queryParams['type'] = type;
    if (classification != null && classification.isNotEmpty) {
      queryParams['classification'] = classification;
    }
    if (active != null) queryParams['active'] = active.toString();

    final data = await _http.get('clients', params: queryParams);
    return (data as List).map((json) => Client.fromJson(json)).toList();
  }

  Future<Client> getClient(int id) async {
    final data = await _http.get('clients/$id');
    return Client.fromJson(data);
  }

  Future<Client> createClient(Client client) async {
    final data = await _http.post('clients', client.toJson());
    return Client.fromJson(data);
  }

  Future<Client> updateClient(int id, Client client) async {
    final data = await _http.put('clients/$id', client.toJson());
    return Client.fromJson(data);
  }

  Future<Client> toggleActive(int id) async {
    final data = await _http.post('clients/$id/toggle-active', {});
    return Client.fromJson(data['client']);
  }
}
