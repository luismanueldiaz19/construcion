class CxcSoporteModel {
  final int? id;
  final int ledhouseCxcId;
  final String nota;
  final String fecha;
  final String? fechaVisita;

  CxcSoporteModel({
    this.id,
    required this.ledhouseCxcId,
    required this.nota,
    required this.fecha,
    this.fechaVisita,
  });

  factory CxcSoporteModel.fromJson(Map<String, dynamic> json) {
    return CxcSoporteModel(
      id: json['id'],
      ledhouseCxcId: json['ledhouse_cxc_id'],
      nota: json['nota'] ?? '',
      fecha: json['fecha'] ?? '',
      fechaVisita: json['fecha_visita'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ledhouse_cxc_id': ledhouseCxcId,
      'nota': nota,
      'fecha': fecha,
      'fecha_visita': fechaVisita,
    };
  }
}
