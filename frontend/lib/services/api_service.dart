import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000/api/v1";

  Future<List<dynamic>> getProyectos() async {
    final response = await http.get(Uri.parse('$baseUrl/proyectos'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Error al cargar proyectos');
  }

  Future<List<dynamic>> getMateriales() async {
    final response = await http.get(Uri.parse('$baseUrl/materiales'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Error al cargar materiales');
  }

  Future<List<dynamic>> getPartidas(int proyectoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/proyectos/$proyectoId/partidas'),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Error al cargar partidas');
  }

  Future<void> createProyecto(Map<String, dynamic> data) async {
    print('POST Request to $baseUrl/proyectos with data: ${json.encode(data)}');
    final response = await http.post(
      Uri.parse('$baseUrl/proyectos'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(data),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      print('ERROR en createProyecto: ${response.body}');
      throw Exception('Error al crear proyecto: ${response.body}');
    }
  }

  Future<void> createAvance(Map<String, dynamic> data) async {
    print('POST Request to $baseUrl/avances with data: ${json.encode(data)}');
    final response = await http.post(
      Uri.parse('$baseUrl/avances'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(data),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      print('ERROR en createAvance: ${response.body}');
      throw Exception('Error al registrar avance: ${response.body}');
    }
  }

  Future<void> createPago(Map<String, dynamic> data) async {
    print('POST Request to $baseUrl/pagos with data: ${json.encode(data)}');
    final response = await http.post(
      Uri.parse('$baseUrl/pagos'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(data),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      print('ERROR en createPago: ${response.body}');
      throw Exception('Error al registrar pago: ${response.body}');
    }
  }

  Future<void> createGastoProyecto(Map<String, dynamic> data) async {
    print('POST Request to $baseUrl/gastos-proyecto with data: ${json.encode(data)}');
    final response = await http.post(
      Uri.parse('$baseUrl/gastos-proyecto'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(data),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      print('ERROR en createGastoProyecto: ${response.body}');
      throw Exception('Error al registrar gasto: ${response.body}');
    }
  }

  Future<List<dynamic>> getCatalogo() async {
    final response = await http.get(
      Uri.parse('$baseUrl/contabilidad/catalogo?plano=1'),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Error al cargar catálogo');
  }

  Future<List<dynamic>> getAsientos() async {
    final response = await http.get(
      Uri.parse('$baseUrl/contabilidad/asientos'),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Error al cargar asientos');
  }

  Future<List<dynamic>> getInventarioPorProyecto() async {
    final response = await http.get(Uri.parse('$baseUrl/inventario-proyectos'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Error al cargar inventario por proyecto');
  }

  Future<void> provisionarTodo100(int proyectoId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/proyectos/$proyectoId/provisionar-todo'),
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode != 200)
      throw Exception('Error al provisionar proyecto');
  }

  Future<void> updateProyectoEstado(int id, String estado) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/proyectos/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({'estado': estado}),
    );
    if (response.statusCode != 200)
      throw Exception('Error al actualizar estado');
  }

  Future<List<dynamic>> getBancos() async {
    final response = await http.get(Uri.parse('$baseUrl/contabilidad/bancos'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Error al cargar bancos');
  }

  Future<Map<String, dynamic>> getDashboardData() async {
    final response = await http.get(Uri.parse('$baseUrl/dashboard'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Error al cargar dashboard');
  }

  Future<Map<String, dynamic>> getEstadoResultados({int? proyectoId}) async {
    String url = '$baseUrl/contabilidad/estado-resultados';
    if (proyectoId != null) url += '?proyecto_id=$proyectoId';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Error al cargar estado de resultados');
  }

  // --- MÓDULO DE COMPRAS Y PROVEEDORES ---

  Future<List<dynamic>> getProveedores() async {
    final response = await http.get(Uri.parse('$baseUrl/proveedores'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Error al cargar proveedores');
  }

  Future<void> createProveedor(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/proveedores'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode != 201 && response.statusCode != 200)
      throw Exception('Error al crear proveedor');
  }

  Future<void> createCompra(Map<String, dynamic> data) async {
    print('POST Request to $baseUrl/compras with data: ${json.encode(data)}');
    final response = await http.post(
      Uri.parse('$baseUrl/compras'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      print('ERROR en createCompra: ${response.body}');
      throw Exception('Error al registrar compra: ${response.body}');
    }
  }

  Future<List<dynamic>> getComprasPendientes() async {
    final response = await http.get(Uri.parse('$baseUrl/compras'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.where((c) => c['estado'] == 'Pendiente').toList();
    }
    throw Exception('Error al cargar compras');
  }

  Future<void> registrarRecepcion(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recepciones'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      print('ERROR en registrarRecepcion: ${response.body}');
      throw Exception('Error al registrar recepción: ${response.body}');
    }
  }

  Future<void> registrarConsumo(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/consumos'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(data),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      print('ERROR en registrarConsumo: ${response.body}');
      throw Exception('Error al registrar consumo: ${response.body}');
    }
  }

  Future<List<dynamic>> getGastosProyecto(int proyectoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/gastos-proyecto?proyecto_id=$proyectoId'),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Error al cargar gastos del proyecto');
  }
}
