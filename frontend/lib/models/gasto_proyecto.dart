import 'proveedor.dart';
import 'subpartida.dart';

class GastoProyecto {
  final int? id;
  final int proyectoId;
  final int? subpartidaId;
  final int? proveedorId;
  final int? cuentaCostoId;
  final double monto;
  final String tipoGasto;
  final String? descripcion;
  final DateTime fecha;
  final String metodoPago;
  final String estado;
  final int? bancoId;
  final Proveedor? proveedor;
  final Subpartida? subpartida;

  GastoProyecto({
    this.id,
    required this.proyectoId,
    this.subpartidaId,
    this.proveedorId,
    this.cuentaCostoId,
    required this.monto,
    required this.tipoGasto,
    this.descripcion,
    required this.fecha,
    required this.metodoPago,
    this.estado = 'PAGADO',
    this.bancoId,
    this.proveedor,
    this.subpartida,
  });

  factory GastoProyecto.fromJson(Map<String, dynamic> json) {
    return GastoProyecto(
      id: json['id'],
      proyectoId: json['proyecto_id'],
      subpartidaId: json['subpartida_id'],
      proveedorId: json['proveedor_id'],
      cuentaCostoId: json['cuenta_costo_id'],
      monto: double.tryParse(json['monto']?.toString() ?? '0') ?? 0.0,
      tipoGasto: json['tipo_gasto'] ?? '',
      descripcion: json['descripcion'],
      fecha: DateTime.parse(json['fecha']),
      metodoPago: json['metodo_pago'] ?? '',
      estado: json['estado'] ?? 'PAGADO',
      bancoId: json['banco_id'],
      proveedor: json['proveedor'] != null ? Proveedor.fromJson(json['proveedor']) : null,
      subpartida: json['subpartida'] != null ? Subpartida.fromJson(json['subpartida']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'proyecto_id': proyectoId,
      'subpartida_id': subpartidaId,
      'proveedor_id': proveedorId,
      'cuenta_costo_id': cuentaCostoId,
      'monto': monto,
      'tipo_gasto': tipoGasto,
      'descripcion': descripcion,
      'fecha': fecha.toIso8601String(),
      'metodo_pago': metodoPago,
      'estado': estado,
      'banco_id': bancoId,
      'proveedor': proveedor?.toJson(),
      'subpartida': subpartida?.toJson(),
    };
  }
}
