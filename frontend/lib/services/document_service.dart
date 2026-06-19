import 'package:http/http.dart' as http;
import 'http_service.dart';

import 'package:file_picker/file_picker.dart';

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
    required PlatformFile file,
  }) async {
    final fields = {
      'proyecto_id': proyectoId.toString(),
      'nombre': nombre,
      'tipo': tipo,
    };
    if (categoria != null) fields['categoria'] = categoria;
    if (partidaId != null) fields['partida_id'] = partidaId.toString();

    http.MultipartFile multipartFile;
    if (file.bytes != null) {
      multipartFile = http.MultipartFile.fromBytes(
        'archivo',
        file.bytes!,
        filename: file.name,
      );
    } else {
      multipartFile = await http.MultipartFile.fromPath('archivo', file.path!);
    }

    await _http.multipart(
      'documentos',
      fields: fields,
      files: [multipartFile],
    );
  }

  Future<void> deleteDocumento(int id) async {
    await _http.delete('documentos/$id');
  }
}
