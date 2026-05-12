class AvanceProyecto {
  final int? id;
  final int subpartidaId;
  final DateTime fecha;
  final double porcentaje;
  final double valorEjecutado;
  final String? evidenciasUrl;

  AvanceProyecto({
    this.id,
    required this.subpartidaId,
    required this.fecha,
    required this.porcentaje,
    required this.valorEjecutado,
    this.evidenciasUrl,
    int? partidaId,
  });

  factory AvanceProyecto.fromJson(Map<String, dynamic> json) {
    return AvanceProyecto(
      id: json['id'],
      subpartidaId: json['subpartida_id'],
      fecha: DateTime.parse(json['fecha']),
      porcentaje: double.tryParse(json['porcentaje']?.toString() ?? '0') ?? 0.0,
      valorEjecutado: double.tryParse(json['valor_ejecutado']?.toString() ?? '0') ?? 0.0,
      evidenciasUrl: json['evidencias_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subpartida_id': subpartidaId,
      'fecha': fecha.toIso8601String(),
      'porcentaje': porcentaje,
      'valor_ejecutado': valorEjecutado,
      'evidencias_url': evidenciasUrl,
    };
  }
}
