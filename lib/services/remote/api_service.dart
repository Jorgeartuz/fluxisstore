import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

typedef FromJson<T> = T Function(Map<String, dynamic> json);
typedef JsonParser<T> = T Function(dynamic data);

/// Resultado HTTP. Los estados de error se devuelven sin convertir el modelo.
class ApiResponse<T> {
  final int statusCode;
  final T? data;
  final Map<String, String> headers;
  final String? message;
  final dynamic rawData;

  const ApiResponse({
    required this.statusCode,
    this.data,
    this.headers = const {},
    this.message,
    this.rawData,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException(${statusCode ?? '-'}): $message';
}

class SessionException implements Exception {
  final String message;

  const SessionException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([super.message = 'Unable to connect to the server.']);
}

class ApiTimeoutException extends ApiException {
  const ApiTimeoutException([super.message = 'The request timed out.']);
}

class ApiParseException extends ApiException {
  const ApiParseException(super.message, {super.statusCode, super.data});
}

/// Cliente JSON con conversión de modelos y manejo de errores de transporte.
///
/// Los errores HTTP se devuelven como [ApiResponse]; los fallos de red,
/// tiempo de espera o conversión se notifican mediante [ApiException].
class ApiService {
  ApiService({
    required this.baseUrl,
    http.Client? client,
    Map<String, String>? defaultHeaders,
    this.timeout = const Duration(seconds: 30),
    this.enableLogs = kDebugMode,
    this.onUnauthorized,
  }) : _client = client ?? http.Client(),
       _defaultHeaders = {
         'Content-Type': 'application/json',
         'Accept': 'application/json',
         ...?defaultHeaders,
       };

  final String baseUrl;
  final Duration timeout;
  final bool enableLogs;
  final VoidCallback? onUnauthorized;

  final http.Client _client;
  final Map<String, String> _defaultHeaders;

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    JsonParser<T>? fromJsonList,
    FromJson<T>? fromJson,
  }) => _request<T>(
    'GET',
    endpoint,
    queryParameters: queryParameters,
    headers: headers,
    parser: fromJsonList ?? _jsonParser(fromJson),
  );

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    JsonParser<T>? parser,
    FromJson<T>? fromJson,
  }) => _request<T>(
    'POST',
    endpoint,
    body: body,
    queryParameters: queryParameters,
    headers: headers,
    parser: parser ?? _jsonParser(fromJson),
  );

  /// Envía campos y archivos como `multipart/form-data`.
  /// El `Content-Type` con su boundary se establece automáticamente.
  Future<ApiResponse<T>> postMultipart<T>(
    String endpoint, {
    required List<http.MultipartFile> files,
    Map<String, String> fields = const {},
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    JsonParser<T>? parser,
    FromJson<T>? fromJson,
  }) => _request<T>(
    'POST',
    endpoint,
    queryParameters: queryParameters,
    headers: headers,
    fields: fields,
    files: files,
    parser: parser ?? _jsonParser(fromJson),
  );

  Future<ApiResponse<T>> putMultipart<T>(
    String endpoint, {
    required List<http.MultipartFile> files,
    Map<String, String> fields = const {},
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    JsonParser<T>? parser,
    FromJson<T>? fromJson,
  }) => _request<T>(
    'PUT',
    endpoint,
    queryParameters: queryParameters,
    headers: headers,
    fields: fields,
    files: files,
    parser: parser ?? _jsonParser(fromJson),
  );

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    JsonParser<T>? parser,
  }) => _request<T>(
    'PUT',
    endpoint,
    body: body,
    queryParameters: queryParameters,
    headers: headers,
    parser: parser,
  );

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    JsonParser<T>? parser,
  }) => _request<T>(
    'DELETE',
    endpoint,
    body: body,
    queryParameters: queryParameters,
    headers: headers,
    parser: parser,
  );

  JsonParser<T>? _jsonParser<T>(FromJson<T>? fromJson) {
    if (fromJson == null) return null;
    return (data) => fromJson(data as Map<String, dynamic>);
  }

  Future<ApiResponse<T>> _request<T>(
    String method,
    String endpoint, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    JsonParser<T>? parser,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);

    final requestHeaders = {..._defaultHeaders, ...?headers};
    final http.BaseRequest request;
    if (files != null) {
      requestHeaders.removeWhere(
        (name, _) => name.toLowerCase() == 'content-type',
      );
      request = http.MultipartRequest(method, uri)
        ..fields.addAll(fields ?? const {})
        ..files.addAll(files)
        ..headers.addAll(requestHeaders);
    } else {
      final jsonRequest = http.Request(method, uri)
        ..headers.addAll(requestHeaders);
      if (body != null) {
        jsonRequest.body = body is String ? body : jsonEncode(body);
      }
      request = jsonRequest;
    }

    _log('→ $method $uri');

    try {
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          // El límite incluye la recepción completa del cuerpo.
          .timeout(timeout);

      _log('← ${response.statusCode} $uri');

      return _handleResponse<T>(response, parser);
    } on TimeoutException {
      throw const ApiTimeoutException();
    } on http.ClientException {
      throw const NetworkException();
    }
  }

  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    JsonParser<T>? parser,
  ) {
    final status = response.statusCode;
    final data = _decodeBody(response.bodyBytes);

    if (status < 200 || status >= 300) {
      if (status == 401) {
        onUnauthorized?.call();
      }

      return ApiResponse<T>(
        statusCode: status,
        headers: response.headers,
        message: _extractMessage(data, status, response.reasonPhrase),
        rawData: data,
      );
    }

    try {
      return ApiResponse<T>(
        statusCode: status,
        data: data == null || T.toString() == 'void'
            ? null
            : _parse<T>(data, parser),
        headers: response.headers,
      );
    } catch (e) {
      throw ApiParseException(
        'Unable to parse the response as $T: $e',
        statusCode: status,
        data: data,
      );
    }
  }

  Object? _decodeBody(List<int> bytes) {
    if (bytes.isEmpty) return null;

    final text = utf8.decode(bytes, allowMalformed: true);
    try {
      return jsonDecode(text);
    } on FormatException {
      return text;
    }
  }

  T _parse<T>(dynamic data, JsonParser<T>? parser) {
    if (parser != null) {
      return parser(data);
    }

    if (data is T) {
      return data;
    }

    throw FormatException(
      'No parser is available for $T. '
      'Provide a parser in the request.',
    );
  }

  Uri _buildUri(String endpoint, Map<String, dynamic>? query) {
    final endpointUri = Uri.parse(endpoint);

    final params = <String, dynamic>{
      ...endpointUri.queryParametersAll,
      for (final entry in (query ?? const <String, dynamic>{}).entries)
        if (entry.value != null)
          entry.key: entry.value is Iterable
              ? (entry.value as Iterable).map((v) => v.toString()).toList()
              : entry.value.toString(),
    };

    var uri = endpointUri;
    if (!endpointUri.hasScheme) {
      final base = Uri.parse(baseUrl);
      final basePath = base.path.replaceAll(RegExp(r'/+$'), '');
      final path = endpointUri.path.replaceAll(RegExp(r'^/+'), '');
      uri = base.replace(path: '$basePath/$path');
    }

    return uri.replace(queryParameters: params.isEmpty ? null : params);
  }

  String _extractMessage(dynamic data, int status, String? reason) {
    if (data is Map) {
      final message = data['message'] ?? data['error'] ?? data['detail'];

      if (message != null) {
        return message.toString();
      }
    }

    if (data is String && data.isNotEmpty) {
      return data;
    }

    return reason?.isNotEmpty == true ? reason! : 'Server error ($status)';
  }

  void _log(String message) {
    if (enableLogs) {
      debugPrint('[ApiService] $message');
    }
  }
}
