import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
}

class ApiClient {
  final String baseUrl;
  final Duration timeout;

  ApiClient({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 10),
  });

  Uri _buildUri(String path, [Map<String, String>? params]) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse(
      '$normalizedBase$normalizedPath',
    ).replace(queryParameters: params);
  }

  Map<String, String> _defaultHeaders() {
    return {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };
  }

  Future<dynamic> get(String path, {Map<String, String>? params}) async {
    final uri = _buildUri(path, params);
    try {
      final response = await http
          .get(uri, headers: _defaultHeaders())
          .timeout(timeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Нет подключения к сети');
    } on HttpException {
      throw ApiException('HTTP‑ошибка при запросе');
    } on FormatException {
      throw ApiException('Ошибка парсинга ответа сервера');
    }
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    try {
      final response = await http
          .post(uri, headers: _defaultHeaders(), body: jsonEncode(body ?? {}))
          .timeout(timeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Нет подключения к сети');
    } on HttpException {
      throw ApiException('HTTP‑ошибка при запросе');
    } on FormatException {
      throw ApiException('Ошибка парсинга ответа сервера');
    }
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    try {
      final response = await http
          .put(uri, headers: _defaultHeaders(), body: jsonEncode(body ?? {}))
          .timeout(timeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Нет подключения к сети');
    } on HttpException {
      throw ApiException('HTTP‑ошибка при запросе');
    } on FormatException {
      throw ApiException('Ошибка парсинга ответа сервера');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) {
        return null;
      }
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic> ||
          decoded is List<dynamic> ||
          decoded is String ||
          decoded is num ||
          decoded is bool) {
        return decoded;
      }

      throw ApiException('Неожиданный формат ответа', statusCode: statusCode);
    } else {
      String message = 'Ошибка сервера ($statusCode)';
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
          message = decoded['detail'].toString();
        }
      } catch (_) {}
      throw ApiException(message, statusCode: statusCode);
    }
  }
}
