class Proveedor {
  final int? id;
  final String nombre;
  final String? rnc;
  final String? telefono;
  final String? direccion;

  Proveedor({
    this.id,
    required this.nombre,
    this.rnc,
    this.telefono,
    this.direccion,
  });

  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      rnc: json['rnc'],
      telefono: json['telefono'],
      direccion: json['direccion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'rnc': rnc,
      'telefono': telefono,
      'direccion': direccion,
    };
  }
}
