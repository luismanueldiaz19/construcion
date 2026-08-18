class LedhouseEstadoResultado {
  final int id;
  final String codigoCuenta;
  final String modulo;
  final String descripcionDeCuenta;
  final double monto;
  final String fecha;
  final String? registedBy;

  LedhouseEstadoResultado({
    required this.id,
    required this.codigoCuenta,
    required this.modulo,
    required this.descripcionDeCuenta,
    required this.monto,
    required this.fecha,
    this.registedBy,
  });

  factory LedhouseEstadoResultado.fromJson(Map<String, dynamic> json) {
    return LedhouseEstadoResultado(
      id: json['id'],
      codigoCuenta: json['codigo_cuenta'],
      modulo: json['modulo'],
      descripcionDeCuenta: json['descripcion_de_cuenta'],
      monto: double.tryParse(json['monto']?.toString() ?? '0') ?? 0.0,
      fecha: json['fecha'],
      registedBy: json['registed_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo_cuenta': codigoCuenta,
      'modulo': modulo,
      'descripcion_de_cuenta': descripcionDeCuenta,
      'monto': monto,
      'fecha': fecha,
      'registed_by': registedBy,
    };
  }
}
