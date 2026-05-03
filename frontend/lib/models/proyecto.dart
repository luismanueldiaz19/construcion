import 'partida.dart';

class Proyecto {
  final int? id;
  final String nombre;
  final String cliente;
  final String? ubicacion;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final double presupuestoEstimado;
  final String estado;
  final double itbis;
  final double transporte;
  final double otrosCostos;
  final double supervisionTecnica;
  final String? logoPath;
  final String? notas;

  // Atributos calculados (de la respuesta JSON del backend)
  final double? totalPresupuestoConGlobales;
  final double? porcentajeAvanceTotal;
  final double? montoEjecutadoTotal;
  final double? totalCobrado;
  final double? ingresoNetoReal;

  final List<Partida> partidas;

  Proyecto({
    this.id,
    required this.nombre,
    required this.cliente,
    this.ubicacion,
    this.fechaInicio,
    this.fechaFin,
    required this.presupuestoEstimado,
    this.estado = 'PENDIENTE',
    this.itbis = 0.0,
    this.transporte = 0.0,
    this.otrosCostos = 0.0,
    this.supervisionTecnica = 0.0,
    this.logoPath,
    this.notas,
    this.totalPresupuestoConGlobales,
    this.porcentajeAvanceTotal,
    this.montoEjecutadoTotal,
    this.totalCobrado,
    this.ingresoNetoReal,
    this.partidas = const [],
  });

  factory Proyecto.fromJson(Map<String, dynamic> json) {
    return Proyecto(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      cliente: json['cliente'] ?? '',
      ubicacion: json['ubicacion'],
      fechaInicio: json['fecha_inicio'] != null
          ? DateTime.parse(json['fecha_inicio'])
          : null,
      fechaFin: json['fecha_fin'] != null
          ? DateTime.parse(json['fecha_fin'])
          : null,
      presupuestoEstimado:
          double.tryParse(json['presupuesto_estimado']?.toString() ?? '0') ??
          0.0,
      estado: json['estado'] ?? 'PENDIENTE',
      itbis: double.tryParse(json['itbis']?.toString() ?? '0') ?? 0.0,
      transporte: double.tryParse(json['transporte']?.toString() ?? '0') ?? 0.0,
      otrosCostos:
          double.tryParse(json['otros_costos']?.toString() ?? '0') ?? 0.0,
      supervisionTecnica:
          double.tryParse(json['supervision_tecnica']?.toString() ?? '0') ??
          0.0,
      logoPath: json['logo_path'],
      notas: json['notas'],
      totalPresupuestoConGlobales: double.tryParse(
        json['total_presupuesto_con_globales']?.toString() ?? '0',
      ),
      porcentajeAvanceTotal: double.tryParse(
        json['porcentaje_avance_total']?.toString() ?? '0',
      ),
      montoEjecutadoTotal: double.tryParse(
        json['monto_ejecutado_total']?.toString() ?? '0',
      ),
      totalCobrado: double.tryParse(json['total_cobrado']?.toString() ?? '0'),
      ingresoNetoReal: double.tryParse(
        json['ingreso_neto_real']?.toString() ?? '0',
      ),
      partidas: (json['partidas'] as List? ?? [])
          .map((p) => Partida.fromJson(p))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'cliente': cliente,
      'ubicacion': ubicacion,
      'fecha_inicio': fechaInicio?.toIso8601String(),
      'fecha_fin': fechaFin?.toIso8601String(),
      'presupuesto_estimado': presupuestoEstimado,
      'estado': estado,
      'itbis': itbis,
      'transporte': transporte,
      'otros_costos': otrosCostos,
      'supervision_tecnica': supervisionTecnica,
      'logo_path': logoPath,
      'notas': notas,
      'partidas': partidas.map((p) => p.toJson()).toList(),
    };
  }
}
