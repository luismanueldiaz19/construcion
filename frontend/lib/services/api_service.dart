import 'dart:convert';
import 'package:construccion_erp/core/constants.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  final String baseUrl = "$host/api/v1";

  Future<List<dynamic>> getProyectos({
    String? estado,
    int? year,
    String? search,
  }) async {
    final Map<String, String> queryParams = {};
    if (estado != null && estado.isNotEmpty) queryParams['estado'] = estado;
    if (year != null) queryParams['year'] = year.toString();
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri.parse(
      '$baseUrl/proyectos',
    ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await http.get(uri);
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
      headers: {'Accept': 'application/json'},
    );
    print('Respuesta getPartidas: ${response.body}');
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
    print(
      'POST Request to $baseUrl/gastos-proyecto with data: ${json.encode(data)}',
    );
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
    print('this is the response ${response.body}');
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Error al cargar inventario por proyecto');
  }

  Future<Map<String, dynamic>> getInventarioDetalleProyecto(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/inventario-proyectos/$id'),
      headers: {'Accept': 'application/json'},
    );
    print('this is the response ${response.body}');
    if (response.statusCode == 200) return json.decode(response.body);

    try {
      final errorData = json.decode(response.body);
      throw Exception(
        errorData['message'] ?? 'Error al cargar detalle de inventario',
      );
    } catch (_) {
      throw Exception('Error al cargar detalle de inventario del proyecto');
    }
  }

  Future<void> provisionarTodo100(int proyectoId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/proyectos/$proyectoId/provisionar-todo'),
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Error al provisionar proyecto');
    }
  }

  Future<void> updateProyecto(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/proyectos/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar proyecto: ${response.body}');
    }
  }

  Future<String> uploadLogo(int proyectoId, XFile image) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/proyectos/$proyectoId/logo'),
    );
    request.headers['Accept'] = 'application/json';

    request.files.add(
      await http.MultipartFile.fromPath(
        'logo',
        image.path,
        contentType: MediaType('image', image.path.split('.').last),
      ),
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    print('this is the file ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['logo_url'];
    } else {
      throw Exception('Error al subir logo: ${response.body}');
    }
  }

  Future<void> removeLogo(int proyectoId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/proyectos/$proyectoId/logo'),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar logo');
    }
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

  Future<List<dynamic>> getAllCompras() async {
    final response = await http.get(Uri.parse('$baseUrl/compras'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Error al cargar todas las compras');
  }

  Future<Map<String, dynamic>> getCompra(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/compras/$id'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Error al cargar detalles de la compra');
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

  Future<List<dynamic>> getConsumosProyecto(int proyectoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/consumos?proyecto_id=$proyectoId'),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Error al cargar consumos del proyecto');
  }

  Future<List<dynamic>> getAllGastos() async {
    final response = await http.get(Uri.parse('$baseUrl/gastos-proyecto'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Error al cargar todos los gastos');
  }

  Future<Map<String, dynamic>> getGasto(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/gastos-proyecto/$id'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Error al cargar detalles del gasto');
  }

  Future<void> addPartida(int proyectoId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/proyectos/$proyectoId/partidas'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al agregar partida: ${response.body}');
    }
  }

  Future<void> addSubpartida(int partidaId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/partidas/$partidaId/subpartidas'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al agregar sub-partida: ${response.body}');
    }
  }

  // --- DOCUMENTOS DE PROYECTO ---

  Future<List<dynamic>> getDocumentosProyecto(int proyectoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/proyectos/$proyectoId/documentos'),
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Error al cargar documentos');
  }

  Future<void> uploadDocumento({
    required int proyectoId,
    required String nombre,
    required String tipo,
    String? categoria,
    int? partidaId,
    required String filePath,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/documentos'));
    request.headers['Accept'] = 'application/json';
    
    request.fields['proyecto_id'] = proyectoId.toString();
    request.fields['nombre'] = nombre;
    request.fields['tipo'] = tipo;
    if (categoria != null) request.fields['categoria'] = categoria;
    if (partidaId != null) request.fields['partida_id'] = partidaId.toString();

    request.files.add(await http.MultipartFile.fromPath('archivo', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'Error al subir archivo');
    }
  }

  Future<void> deleteDocumento(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/documentos/$id'),
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) throw Exception('Error al eliminar documento');
  }
}
