class LedhouseProveedor {
  final int? id;
  final String nombre;
  final String empresa;
  final String rncCedula;
  final String whatsapp;
  final String correo;
  final String direccion;

  LedhouseProveedor({
    this.id,
    required this.nombre,
    required this.empresa,
    required this.rncCedula,
    required this.whatsapp,
    required this.correo,
    required this.direccion,
  });

  factory LedhouseProveedor.fromJson(Map<String, dynamic> json) {
    return LedhouseProveedor(
      id: json['id'] as int?,
      nombre: (json['nombre'] as String?) ?? '',
      empresa: (json['empresa'] as String?) ?? '',
      rncCedula: (json['rnc_cedula'] as String?) ?? '',
      whatsapp: (json['whatsapp'] as String?) ?? '',
      correo: (json['correo'] as String?) ?? '',
      direccion: (json['direccion'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'empresa': empresa,
      'rnc_cedula': rncCedula,
      'whatsapp': whatsapp,
      'correo': correo,
      'direccion': direccion,
    };
  }
}
