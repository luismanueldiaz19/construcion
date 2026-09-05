class LedhouseCliente {
  final int? id;
  final String nombre;
  final String? whatsapp;
  final String? direccion;
  final String? tipoDocumento;
  final String? documento;
  final double? limiteCredito;
  final int? diasCredito;

  LedhouseCliente({
    this.id,
    required this.nombre,
    this.whatsapp,
    this.direccion,
    this.tipoDocumento,
    this.documento,
    this.limiteCredito,
    this.diasCredito,
  });

  factory LedhouseCliente.fromJson(Map<String, dynamic> json) {
    return LedhouseCliente(
      id: json['id'] as int?,
      nombre: (json['nombre'] as String?) ?? '',
      whatsapp: json['whatsapp'] as String?,
      direccion: json['direccion'] as String?,
      tipoDocumento: json['tipo_documento'] as String?,
      documento: json['documento'] as String?,
      limiteCredito: json['limite_credito'] != null 
          ? double.tryParse(json['limite_credito'].toString()) 
          : null,
      diasCredito: json['dias_credito'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'whatsapp': whatsapp,
      'direccion': direccion,
      'tipo_documento': tipoDocumento,
      'documento': documento,
      'limite_credito': limiteCredito,
      'dias_credito': diasCredito,
    };
  }
}
