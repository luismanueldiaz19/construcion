class CxpModel {
  final int? id;
  final String documento;
  final String proveedor;
  final double montoFactura;
  final double montoPagado;
  final double montoPendiente;
  final String fechaVencimiento;
  final String estado;

  CxpModel({
    this.id,
    required this.documento,
    required this.proveedor,
    required this.montoFactura,
    this.montoPagado = 0.0,
    required this.montoPendiente,
    required this.fechaVencimiento,
    this.estado = 'pendiente',
  });

  factory CxpModel.fromJson(Map<String, dynamic> json) {
    return CxpModel(
      id: json['id'],
      documento: json['documento'] ?? '',
      proveedor: json['proveedor'] ?? '',
      montoFactura: double.tryParse(json['monto_factura']?.toString() ?? '0') ?? 0.0,
      montoPagado: double.tryParse(json['monto_pagado']?.toString() ?? '0') ?? 0.0,
      montoPendiente: double.tryParse(json['monto_pendiente']?.toString() ?? '0') ?? 0.0,
      fechaVencimiento: json['fecha_vencimiento'] ?? '',
      estado: json['estado'] ?? 'pendiente',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documento': documento,
      'proveedor': proveedor,
      'monto_factura': montoFactura,
      'monto_pagado': montoPagado,
      'fecha_vencimiento': fechaVencimiento,
      'estado': estado,
    };
  }
}
