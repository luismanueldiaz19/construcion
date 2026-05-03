import 'http_service.dart';

class AccountingService {
  final HttpService _http = HttpService();

  Future<List<dynamic>> getCatalogo() async {
    return await _http.get('contabilidad/catalogo', params: {'plano': '1'});
  }

  Future<List<dynamic>> getAsientos() async {
    return await _http.get('contabilidad/asientos');
  }

  Future<List<dynamic>> getBancos() async {
    return await _http.get('contabilidad/bancos');
  }

  Future<Map<String, dynamic>> getEstadoResultados({int? proyectoId}) async {
    final Map<String, String> params = {};
    if (proyectoId != null) params['proyecto_id'] = proyectoId.toString();
    return await _http.get('contabilidad/estado-resultados', params: params);
  }

  Future<List<dynamic>> getCuentasPorCobrar() async {
    return await _http.get('cuentas-por-cobrar');
  }

  Future<List<dynamic>> getCuentasPorPagar() async {
    return await _http.get('cuentas-por-pagar');
  }

  Future<void> createPago(Map<String, dynamic> data) async {
    await _http.post('pagos', data);
  }

  Future<List<dynamic>> getAllPagosHistorial() async {
    return await _http.get('pagos-historial');
  }

  Future<void> registrarPagoCompra(Map<String, dynamic> data) async {
    await _http.post('pagos-compras', data);
  }
}
