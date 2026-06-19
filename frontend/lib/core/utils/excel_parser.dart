import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

class ExcelParser {
  static Future<List<Map<String, dynamic>>?> parseBudgetExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true, // Need bytes for web support
      );

      if (result != null) {
        Uint8List? bytes = result.files.single.bytes;

        // If not web, bytes might be null, so we read from path
        if (bytes == null && result.files.single.path != null) {
          bytes = await File(result.files.single.path!).readAsBytes();
        }

        if (bytes == null) {
          throw Exception("No se pudo leer el archivo");
        }

        // Usar compute para mover el procesamiento pesado a un hilo en segundo plano (isolate)
        // Esto evita que la interfaz (el círculo de carga) se congele.
        return await compute(_decodeAndParseExcel, bytes);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error al leer Excel: $e");
      }
      throw Exception("Error procesando el archivo: $e");
    }
    return null;
  }

  // Función estática separada para ser ejecutada en un Isolate en segundo plano
  static List<Map<String, dynamic>> _decodeAndParseExcel(Uint8List bytes) {
    var excel = Excel.decodeBytes(bytes);

    // Get the first sheet
    var table = excel.tables[excel.tables.keys.first];

    if (table == null || table.rows.isEmpty) {
      throw Exception("El archivo de Excel está vacío");
    }

    // Validate Headers (Row 0)
    var headers = table.rows.first;
    if (headers.length < 5) {
      throw Exception(
        "El archivo no tiene el formato correcto (Mínimo 5 columnas esperadas).",
      );
    }

    List<Map<String, dynamic>> partidas = [];
    Map<String, dynamic>? currentPartida;

    // Iterate starting from row 1 (skipping header)
    for (int i = 1; i < table.rows.length; i++) {
      var row = table.rows[i];

      if (row.isEmpty || _isEmpty(row[1]?.value)) {
        continue; // Skip empty rows or rows without description
      }

      String description = row[1]?.value.toString() ?? '';

      var cantValue = row.length > 2 ? row[2]?.value : null;
      double cant = _parseDouble(cantValue);

      var unitValue = row.length > 3 ? row[3]?.value : '';
      String unit = unitValue?.toString() ?? 'GL';
      if (unit.trim().isEmpty) unit = 'GL';

      var costValue = row.length > 4 ? row[4]?.value : null;
      double cost = _parseDouble(costValue);

      // Lógica: Si cantidad es 0 o no tiene cantidad/precio, asumimos que es una Partida principal
      if (cant == 0) {
        currentPartida = {
          'descripcion': description,
          'subpartidas': <Map<String, dynamic>>[],
        };
        partidas.add(currentPartida);
      } else {
        // Es una subpartida
        if (currentPartida == null) {
          currentPartida = {
            'descripcion': 'Partida General',
            'subpartidas': <Map<String, dynamic>>[],
          };
          partidas.add(currentPartida);
        }

        (currentPartida['subpartidas'] as List).add({
          'descripcion': description,
          'unidad': unit,
          'cantidad': cant,
          'costo_unitario': cost,
        });
      }
    }

    return partidas;
  }

  static bool _isEmpty(dynamic value) {
    if (value == null) return true;
    if (value.toString().trim().isEmpty) return true;
    return false;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      // Remover símbolos de moneda y comas
      String cleanStr = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleanStr) ?? 0.0;
    }

    // El paquete excel puede devolver Formula, DateTime, TextCellValue, IntCellValue, DoubleCellValue (depende versión)
    // En excel 4.0.6, Data.value es SharedString, IntCellValue, DoubleCellValue, etc.
    // Usaremos toString y luego parseamos para simplificar compatibilidad.
    String strVal = value.toString().replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(strVal) ?? 0.0;
  }
}
