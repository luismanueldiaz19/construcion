import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import 'http_service.dart';

/// NominaExportService — Descarga de reportes Excel del módulo de nómina.
/// En web: abre en nueva pestaña del navegador.
/// En mobile/desktop: descarga el archivo.
class NominaExportService {
  final String _baseUrl = '$host/api/v1/nomina/export';

  /// Construye la URL del reporte con los parámetros dados
  /// y la abre en el navegador (compatible con Flutter Web y móvil).
  Future<void> _openExport(String endpoint, Map<String, String> params) async {
    final token = HttpService.token;
    final uri = Uri.parse('$_baseUrl/$endpoint').replace(
      queryParameters: {
        ...params,
        // Pasamos el token en query param solo si no podemos usar headers
        // En web se abre en el navegador directamente
      },
    );

    // Para web: lanzar URL con el token en header no funciona desde browser.
    // Alternativa: guardar token en cookie session o usar url_launcher.
    // Por ahora abrimos la URL y el backend no requiere auth en exports.
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'No se pudo abrir el reporte. URL: $uri';
    }
  }

  /// 1. Nómina Consolidada por Periodo
  Future<void> downloadNominaConsolidada(int payrollId) async {
    await _openExport('nomina-consolidada', {
      'payroll_id': payrollId.toString(),
    });
  }

  /// 2. Planilla TSS (formato Tesorería Seguridad Social)
  Future<void> downloadPlanillaTSS(int payrollId) async {
    await _openExport('planilla-tss', {'payroll_id': payrollId.toString()});
  }

  /// 3. Historial de Salarios
  Future<void> downloadHistorialSalarios({
    int? employeeId,
    String? from,
    String? to,
  }) async {
    await _openExport('historial-salarios', {
      if (employeeId != null) 'employee_id': employeeId.toString(),
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
  }

  /// 4. Retenciones ISR (para declaración DGII)
  Future<void> downloadRetencionesISR(int payrollId) async {
    await _openExport('retenciones-isr', {'payroll_id': payrollId.toString()});
  }

  /// 5. Provisiones Acumuladas (regalía, vacaciones, cesantía)
  Future<void> downloadProvisiones({
    required String from,
    required String to,
  }) async {
    await _openExport('provisiones', {'from': from, 'to': to});
  }

  /// 6. Kardex / Libro de Nómina del Empleado
  Future<void> downloadKardex({
    required int employeeId,
    required String from,
    required String to,
  }) async {
    await _openExport('kardex', {
      'employee_id': employeeId.toString(),
      'from': from,
      'to': to,
    });
  }
}
