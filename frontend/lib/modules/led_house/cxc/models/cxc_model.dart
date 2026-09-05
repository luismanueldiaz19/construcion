import '../../models/ledhouse_cliente.dart';

class CxcModel {
  final int? id;
  final String documento;
  final int clienteId;
  final LedhouseCliente? clienteObj;
  final double montoFactura;
  final double montoPagado;
  final double montoPendiente;
  final String? fechaFactura;
  final String fechaVencimiento;
  final String estado;
  final int totalIntervenciones;
  final String? ultimaFechaVisita;

  CxcModel({
    this.id,
    required this.documento,
    required this.clienteId,
    this.clienteObj,
    required this.montoFactura,
    this.montoPagado = 0.0,
    required this.montoPendiente,
    this.fechaFactura,
    required this.fechaVencimiento,
    this.estado = 'pendiente',
    this.totalIntervenciones = 0,
    this.ultimaFechaVisita,
  });

  String get cliente => clienteObj?.nombre ?? 'Desconocido';

  factory CxcModel.fromJson(Map<String, dynamic> json) {
    return CxcModel(
      id: json['id'],
      documento: json['documento'] ?? '',
      clienteId: json['cliente_id'] ?? 0,
      clienteObj: json['cliente'] != null ? LedhouseCliente.fromJson(json['cliente']) : null,
      montoFactura: double.tryParse(json['monto_factura']?.toString() ?? '0') ?? 0.0,
      montoPagado: double.tryParse(json['monto_pagado']?.toString() ?? '0') ?? 0.0,
      montoPendiente: double.tryParse(json['monto_pendiente']?.toString() ?? '0') ?? 0.0,
      fechaFactura: json['fecha_factura'],
      fechaVencimiento: json['fecha_vencimiento'] ?? '',
      estado: json['estado'] ?? 'pendiente',
      totalIntervenciones: json['total_intervenciones'] ?? 0,
      ultimaFechaVisita: json['ultima_fecha_visita'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documento': documento,
      'cliente_id': clienteId,
      'monto_factura': montoFactura,
      'monto_pagado': montoPagado,
      if (fechaFactura != null) 'fecha_factura': fechaFactura,
      'fecha_vencimiento': fechaVencimiento,
      'estado': estado,
    };
  }
}
