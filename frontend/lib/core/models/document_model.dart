class DocumentModel {
  final int id;
  final int proyectoId;
  final int? partidaId;
  final String nombre;
  final String tipo;
  final String? categoria;
  final String filePath;
  final String fileExtension;
  final int fileSize;
  final DateTime? createdAt;
  final dynamic partida; // Could be PartidaModel if it existed

  DocumentModel({
    required this.id,
    required this.proyectoId,
    this.partidaId,
    required this.nombre,
    required this.tipo,
    this.categoria,
    required this.filePath,
    required this.fileExtension,
    required this.fileSize,
    this.createdAt,
    this.partida,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      proyectoId: json['proyecto_id'],
      partidaId: json['partida_id'],
      nombre: json['nombre'],
      tipo: json['tipo'],
      categoria: json['categoria'],
      filePath: json['file_path'],
      fileExtension: json['file_extension'],
      fileSize: json['file_size'] is int ? json['file_size'] : int.parse(json['file_size'].toString()),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      partida: json['partida'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'proyecto_id': proyectoId,
      'partida_id': partidaId,
      'nombre': nombre,
      'tipo': tipo,
      'categoria': categoria,
      'file_path': filePath,
      'file_extension': fileExtension,
      'file_size': fileSize,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  bool get isPdf => fileExtension.toLowerCase() == 'pdf';
  bool get isImage => ['jpg', 'jpeg', 'png'].contains(fileExtension.toLowerCase());
}
