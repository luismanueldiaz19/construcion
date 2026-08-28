class CuentaCatalogo {
  final int? id;
  final String codigo;
  final String descripcion;
  final String origen;

  CuentaCatalogo({
    this.id,
    required this.codigo,
    required this.descripcion,
    required this.origen,
  });

  factory CuentaCatalogo.fromJson(Map<String, dynamic> json) {
    return CuentaCatalogo(
      id: json['id'],
      codigo: json['codigo'],
      descripcion: json['descripcion'],
      origen: json['origen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'codigo': codigo,
      'descripcion': descripcion,
      'origen': origen,
    };
  }
}
