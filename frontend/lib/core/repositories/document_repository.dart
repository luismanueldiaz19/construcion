import '../../services/document_service.dart';
import '../models/document_model.dart';

class DocumentRepository {
  final DocumentService _documentService = DocumentService();

  Future<List<DocumentModel>> getDocumentsByProject(int proyectoId) async {
    final List<dynamic> data = await _documentService.getDocumentosProyecto(proyectoId);
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
    await _documentService.uploadDocumento(
      proyectoId: proyectoId,
      nombre: nombre,
      tipo: tipo,
      categoria: categoria,
      partidaId: partidaId,
      filePath: filePath,
    );
  }

  Future<void> deleteDocument(int id) async {
    await _documentService.deleteDocumento(id);
  }
}
