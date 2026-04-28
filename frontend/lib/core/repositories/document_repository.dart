import '../../services/api_service.dart';
import '../models/document_model.dart';

class DocumentRepository {
  final ApiService _apiService = ApiService();

  Future<List<DocumentModel>> getDocumentsByProject(int proyectoId) async {
    final List<dynamic> data = await _apiService.getDocumentosProyecto(proyectoId);
    return data.map((json) => DocumentModel.fromJson(json)).toList();
  }

  Future<void> uploadDocument({
    required int proyectoId,
    required String nombre,
    required String tipo,
    String? categoria,
    int? partidaId,
    required String filePath,
  }) async {
    await _apiService.uploadDocumento(
      proyectoId: proyectoId,
      nombre: nombre,
      tipo: tipo,
      categoria: categoria,
      partidaId: partidaId,
      filePath: filePath,
    );
  }

  Future<void> deleteDocument(int id) async {
    await _apiService.deleteDocumento(id);
  }
}
