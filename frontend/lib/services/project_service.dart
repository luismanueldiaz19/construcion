import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/proyecto.dart';
import '../models/partida.dart';
import '../models/subpartida.dart';
import '../models/avance_proyecto.dart';
import '../models/gasto_proyecto.dart';
import 'http_service.dart';

class ProjectService {
  final HttpService _http = HttpService();

  Future<List<Proyecto>> getProyectos({
    String? estado,
    int? year,
    String? search,
  }) async {
    final Map<String, String> queryParams = {};
    if (estado != null && estado.isNotEmpty) queryParams['estado'] = estado;
    if (year != null) queryParams['year'] = year.toString();
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final data = await _http.get('proyectos', params: queryParams);
    return (data as List).map((json) => Proyecto.fromJson(json)).toList();
  }

  Future<Proyecto> getProyecto(int id) async {
    final data = await _http.get('proyectos/$id');
    return Proyecto.fromJson(data);
  }

  Future<void> createProyecto(Proyecto proyecto) async {
    await _http.post('proyectos', proyecto.toJson());
  }

  Future<void> updateProyecto(int id, Proyecto proyecto) async {
    await _http.put('proyectos/$id', proyecto.toJson());
  }

  Future<void> deleteProyecto(int id) async {
    await _http.delete('proyectos/$id');
  }

  Future<List<Partida>> getPartidas(int proyectoId) async {
    final data = await _http.get('proyectos/$proyectoId/partidas');
    return (data as List).map((json) => Partida.fromJson(json)).toList();
  }

  Future<void> addPartida(int proyectoId, Map<String, dynamic> data) async {
    await _http.post('proyectos/$proyectoId/partidas', data);
  }

  Future<void> addSubpartida(int partidaId, Map<String, dynamic> data) async {
    await _http.post('partidas/$partidaId/subpartidas', data);
  }

  Future<void> createAvance(AvanceProyecto avance) async {
    await _http.post('avances', avance.toJson());
  }

  Future<void> createGastoProyecto(GastoProyecto gasto) async {
    await _http.post('gastos-proyecto', gasto.toJson());
  }

  Future<List<GastoProyecto>> getGastosProyecto(int proyectoId) async {
    final data = await _http.get('gastos-proyecto', params: {'proyecto_id': proyectoId.toString()});
    return (data as List).map((json) => GastoProyecto.fromJson(json)).toList();
  }

  Future<void> updateProyectoEstado(int id, String estado) async {
    await _http.patch('proyectos/$id', {'estado': estado});
  }

  Future<String> uploadLogo(int proyectoId, XFile image) async {
    final file = await http.MultipartFile.fromPath(
      'logo',
      image.path,
      contentType: MediaType('image', image.path.split('.').last),
    );

    final data = await _http.multipart(
      'proyectos/$proyectoId/logo',
      files: [file],
    );
    return data['logo_url'];
  }

  Future<void> provisionarTodo100(int proyectoId) async {
    await _http.post('proyectos/$proyectoId/provisionar-todo', {});
  }

  Future<void> removeLogo(int proyectoId) async {
    await _http.delete('proyectos/$proyectoId/logo');
  }
}
