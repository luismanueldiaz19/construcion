import 'subpartida.dart';

class Partida {
  final int? id;
  final int? proyectoId;
  final String codigo;
  final String descripcion;
  final List<Subpartida> subpartidas;
  
  double get totalPresupuestado => subpartidas.fold(0, (sum, s) => sum + s.totalPresupuestado);
  double get valorEjecutado => subpartidas.fold(0, (sum, s) => sum + s.valorEjecutado);
  double get porcentajeAvance {
    final total = totalPresupuestado;
    if (total <= 0) return 0.0;
    return (valorEjecutado / total) * 100;
  }

  Partida({
    this.id,
    this.proyectoId,
    required this.codigo,
    required this.descripcion,
    this.subpartidas = const [],
  });

  factory Partida.fromJson(Map<String, dynamic> json) {
    return Partida(
      id: json['id'],
      proyectoId: json['proyecto_id'],
      codigo: json['codigo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      subpartidas: (json['subpartidas'] as List? ?? [])
          .map((s) => Subpartida.fromJson(s))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'proyecto_id': proyectoId,
      'codigo': codigo,
      'descripcion': descripcion,
      'subpartidas': subpartidas.map((s) => s.toJson()).toList(),
    };
  }
}
