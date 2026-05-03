class Subpartida {
  final int? id;
  final int? partidaId;
  final String descripcion;
  final String unidad;
  final double cantidad;
  final double costoUnitario;
  final double totalPresupuestado;
  final double valorEjecutado;
  
  double get avanceActual {
    if (totalPresupuestado <= 0) return 0.0;
    return (valorEjecutado / totalPresupuestado) * 100;
  }

  Subpartida({
    this.id,
    this.partidaId,
    required this.descripcion,
    required this.unidad,
    required this.cantidad,
    required this.costoUnitario,
    required this.totalPresupuestado,
    this.valorEjecutado = 0.0,
  });

  factory Subpartida.fromJson(Map<String, dynamic> json) {
    return Subpartida(
      id: json['id'],
      partidaId: json['partida_id'],
      descripcion: json['descripcion'] ?? '',
      unidad: json['unidad'] ?? '',
      cantidad: double.tryParse(json['cantidad']?.toString() ?? '0') ?? 0.0,
      costoUnitario: double.tryParse(json['costo_unitario']?.toString() ?? '0') ?? 0.0,
      totalPresupuestado: double.tryParse(json['total_presupuestado']?.toString() ?? '0') ?? 0.0,
      valorEjecutado: double.tryParse(json['valor_ejecutado']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partida_id': partidaId,
      'descripcion': descripcion,
      'unidad': unidad,
      'cantidad': cantidad,
      'costo_unitario': costoUnitario,
      'total_presupuestado': totalPresupuestado,
      'valor_ejecutado': valorEjecutado,
    };
  }
}
