import 'package:http/http.dart' as http;
import 'http_service.dart';

class DocumentService {
  final HttpService _http = HttpService();

  Future<List<dynamic>> getDocumentosProyecto(int proyectoId) async {
    return await _http.get('proyectos/$proyectoId/documentos');
  }

  Future<void> uploadDocumento({
    required int proyectoId,
    required String nombre,
    required String tipo,
    String? categoria,
    int? partidaId,
    required String filePath,
  }) async {
    final fields = {
      'proyecto_id': proyectoId.toString(),
      'nombre': nombre,
      'tipo': tipo,
    };
    if (categoria != null) fields['categoria'] = categoria;
    if (partidaId != null) fields['partida_id'] = partidaId.toString();

    await _http.multipart(
      'documentos',
      fields: fields,
      files: [await http.MultipartFile.fromPath('archivo', filePath)],
    );
  }

  Future<void> deleteDocumento(int id) async {
    await _http.delete('documentos/$id');
  }
}
