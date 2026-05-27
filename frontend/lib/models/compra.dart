import 'proveedor.dart';
import 'proyecto.dart';

class Compra {
  final int id;
  final int proveedorId;
  final int proyectoId;
  final String fecha;
  final String tipoCompra;
  final double subtotal;
  final double itbis;
  final double total;
  final String? fechaVencimiento;
  final String estado;
  final String? orden;
  final String? codigo;
  final String? comprobante;
  final String? nota;
  final Proveedor? proveedor;
  final Proyecto? proyecto;
  final List<dynamic>? detalles;
  final List<dynamic>? documentos;

  Compra({
    required this.id,
    required this.proveedorId,
    required this.proyectoId,
    required this.fecha,
    required this.tipoCompra,
    required this.subtotal,
    required this.itbis,
    required this.total,
    this.fechaVencimiento,
    required this.estado,
    this.orden,
    this.codigo,
    this.comprobante,
    this.nota,
    this.proveedor,
    this.proyecto,
    this.detalles,
    this.documentos,
  });

  factory Compra.fromJson(Map<String, dynamic> json) {
    return Compra(
      id: json['id'],
      proveedorId: json['proveedor_id'] ?? 0,
      proyectoId: json['proyecto_id'] ?? 0,
      fecha: json['fecha'] ?? '',
      tipoCompra: json['tipo_compra'] ?? '',
      subtotal: double.parse(json['subtotal']?.toString() ?? '0'),
      itbis: double.parse(json['itbis']?.toString() ?? '0'),
      total: double.parse(json['total']?.toString() ?? '0'),
      fechaVencimiento: json['fecha_vencimiento'],
      estado: json['estado'] ?? 'Pendiente',
      orden: json['orden'],
      codigo: json['codigo'],
      comprobante: json['comprobante'],
      nota: json['nota'],
      proveedor: json['proveedor'] != null ? Proveedor.fromJson(json['proveedor']) : null,
      proyecto: json['proyecto'] != null ? Proyecto.fromJson(json['proyecto']) : null,
      detalles: json['detalles'] as List<dynamic>?,
      documentos: json['documentos'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'proveedor_id': proveedorId,
      'proyecto_id': proyectoId,
      'fecha': fecha,
      'tipo_compra': tipoCompra,
      'subtotal': subtotal,
      'itbis': itbis,
      'total': total,
      'fecha_vencimiento': fechaVencimiento,
      'estado': estado,
      'orden': orden,
      'codigo': codigo,
      'comprobante': comprobante,
      'nota': nota,
      'proveedor': proveedor?.toJson(),
      'proyecto': proyecto?.toJson(),
      'detalles': detalles,
      'documentos': documentos,
    };
  }
}
