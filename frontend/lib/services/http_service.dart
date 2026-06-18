import 'dart:convert';
import 'dart:io';
import 'package:construccion_erp/core/constants.dart';
import 'package:http/http.dart' as http;

const timeout = Duration(seconds: 15);

class HttpService {
  final String baseUrl = "$host/api/v1";
  static String? token;

  Map<String, String> get _headers {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? params}) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/$endpoint',
      ).replace(queryParameters: params);
      final response = await http.get(uri, headers: _headers).timeout(timeout);
      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> post(String endpoint, dynamic body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/$endpoint'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(timeout);
      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> put(String endpoint, dynamic body) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/$endpoint'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(timeout);
      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> patch(String endpoint, dynamic body) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/$endpoint'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(timeout);
      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/$endpoint'), headers: _headers)
          .timeout(timeout);
      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> multipart(
    String endpoint, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    String method = 'POST',
  }) async {
    try {
      final request = http.MultipartRequest(
        method,
        Uri.parse('$baseUrl/$endpoint'),
      );
      request.headers.addAll({'Accept': 'application/json'});

      if (fields != null) request.fields.addAll(fields);
      if (files != null) request.files.addAll(files);

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      String message = 'Error ${response.statusCode}';
      try {
        final body = json.decode(response.body);
        message = body['message'] ?? body['error'] ?? message;
      } catch (_) {}
      throw message;
    }
  }

  void _handleError(dynamic e) {
    if (e is SocketException) {
      throw 'El servidor no está disponible. Verifique su conexión.';
    } else if (e is http.ClientException) {
      throw 'No se pudo conectar con el servidor.';
    } else if (e.toString().contains('TimeoutException')) {
      throw 'La conexión tardó demasiado (Timeout). Comprueba tu internet o el estado del servidor.';
    } else if (e is String) {
      throw e;
    } else {
      // Mostrar el error real para poder diagnosticarlo mejor
      throw 'Error inesperado: ${e.toString()}';
    }
  }
}
