class LedhouseCliente {
  final int? id;
  final String nombre;
  final String? whatsapp;
  final String? direccion;

  LedhouseCliente({
    this.id,
    required this.nombre,
    this.whatsapp,
    this.direccion,
  });

  factory LedhouseCliente.fromJson(Map<String, dynamic> json) {
    return LedhouseCliente(
      id: json['id'] as int?,
      nombre: (json['nombre'] as String?) ?? '',
      whatsapp: json['whatsapp'] as String?,
      direccion: json['direccion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'whatsapp': whatsapp,
      'direccion': direccion,
    };
  }
}
