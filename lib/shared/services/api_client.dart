import 'dart:convert';
import 'package:http/http.dart' as http;

/// API Client for Hiking Assistant Backend
class ApiClient {
  ApiClient._();

  static ApiClient get instance => ApiClient._();

  // TODO: Configure base URL for production
  static const String _baseUrl = 'http://localhost:8000';

  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Map<String, String> _headers({Map<String, String>? extra}) {
    final headers = {
      'Content-Type': 'application/json',
      ...?extra,
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  /// GET request
  Future<ApiResponse> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final response = await http.get(uri, headers: _headers()).timeout(
      const Duration(seconds: 10),
    );
    return ApiResponse.fromHttp(response);
  }

  /// POST request
  Future<ApiResponse> post(String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http
        .post(
          uri,
          headers: _headers(),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 10));
    return ApiResponse.fromHttp(response);
  }

  /// PUT request
  Future<ApiResponse> put(String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http
        .put(
          uri,
          headers: _headers(),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 10));
    return ApiResponse.fromHttp(response);
  }

  /// DELETE request
  Future<ApiResponse> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.delete(uri, headers: _headers()).timeout(
      const Duration(seconds: 10),
    );
    return ApiResponse.fromHttp(response);
  }

  String get baseUrl => _baseUrl;
}

/// API Response wrapper
class ApiResponse {
  final int statusCode;
  final Map<String, dynamic>? data;
  final List<dynamic>? listData;
  final String? error;

  ApiResponse({
    required this.statusCode,
    this.data,
    this.listData,
    this.error,
  });

  factory ApiResponse.fromHttp(http.Response response) {
    if (response.body.isEmpty) {
      return ApiResponse(statusCode: response.statusCode);
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return ApiResponse(
          statusCode: response.statusCode,
          data: decoded,
          error: decoded['detail'] as String?,
        );
      }
      if (decoded is List) {
        return ApiResponse(
          statusCode: response.statusCode,
          listData: decoded,
        );
      }
      return ApiResponse(statusCode: response.statusCode);
    } catch (_) {
      return ApiResponse(
        statusCode: response.statusCode,
        error: response.body,
      );
    }
  }

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  T? getData<T>(String key) {
    if (data == null) return null;
    final value = data![key];
    if (value is T) return value;
    return null;
  }
}