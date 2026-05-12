class ConsumoProyecto {
  final int? id;
  final int proyectoId;
  final int? subpartidaId;
  final int materialId;
  final double cantidad;
  final double total;
  final DateTime fecha;

  ConsumoProyecto({
    this.id,
    required this.proyectoId,
    this.subpartidaId,
    required this.materialId,
    required this.cantidad,
    required this.total,
    required this.fecha,
  });

  factory ConsumoProyecto.fromJson(Map<String, dynamic> json) {
    return ConsumoProyecto(
      id: json['id'],
      proyectoId: json['proyecto_id'],
      subpartidaId: json['subpartida_id'],
      materialId: json['material_id'],
      cantidad: double.tryParse(json['cantidad']?.toString() ?? '0') ?? 0.0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      fecha: DateTime.parse(json['fecha']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'proyecto_id': proyectoId,
      'subpartida_id': subpartidaId,
      'material_id': materialId,
      'cantidad': cantidad,
      'total': total,
      'fecha': fecha.toIso8601String(),
    };
  }
}
