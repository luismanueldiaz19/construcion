class CxcModel {
  final int? id;
  final String documento;
  final String cliente;
  final double montoFactura;
  final double montoPagado;
  final double montoPendiente;
  final String fechaVencimiento;
  final String estado;
  final int totalIntervenciones;
  final String? ultimaFechaVisita;

  CxcModel({
    this.id,
    required this.documento,
    required this.cliente,
    required this.montoFactura,
    this.montoPagado = 0.0,
    required this.montoPendiente,
    required this.fechaVencimiento,
    this.estado = 'pendiente',
    this.totalIntervenciones = 0,
    this.ultimaFechaVisita,
  });

  factory CxcModel.fromJson(Map<String, dynamic> json) {
    return CxcModel(
      id: json['id'],
      documento: json['documento'] ?? '',
      cliente: json['cliente'] ?? '',
      montoFactura: double.tryParse(json['monto_factura']?.toString() ?? '0') ?? 0.0,
      montoPagado: double.tryParse(json['monto_pagado']?.toString() ?? '0') ?? 0.0,
      montoPendiente: double.tryParse(json['monto_pendiente']?.toString() ?? '0') ?? 0.0,
      fechaVencimiento: json['fecha_vencimiento'] ?? '',
      estado: json['estado'] ?? 'pendiente',
      totalIntervenciones: json['total_intervenciones'] ?? 0,
      ultimaFechaVisita: json['ultima_fecha_visita'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documento': documento,
      'cliente': cliente,
      'monto_factura': montoFactura,
      'monto_pagado': montoPagado,
      'fecha_vencimiento': fechaVencimiento,
      'estado': estado,
    };
  }
}
