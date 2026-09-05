import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiService {
  final http.Client _client = http.Client();
  String? _authToken;

  void setToken(String token) {
    _authToken = token;
  }

  void clearToken() {
    _authToken = null;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  String _buildUrl(String endpoint) => '${ApiConfig.baseUrl}$endpoint';

  Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      var uri = Uri.parse(_buildUrl(endpoint));
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: 0,
        message: 'সংযোগ ত্রুটি: $e',
      );
    }
  }

  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(_buildUrl(endpoint)),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 8));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: 0,
        message: 'সংযোগ ত্রুটি: $e',
      );
    }
  }

  Future<ApiResponse> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await _client
          .put(
            Uri.parse(_buildUrl(endpoint)),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 8));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: 0,
        message: 'সংযোগ ত্রুটি: $e',
      );
    }
  }

  Future<ApiResponse> delete(String endpoint) async {
    try {
      final response = await _client
          .delete(Uri.parse(_buildUrl(endpoint)), headers: _headers)
          .timeout(const Duration(seconds: 8));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: 0,
        message: 'সংযোগ ত্রুটি: $e',
      );
    }
  }

  ApiResponse _handleResponse(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse(
        success: true,
        statusCode: response.statusCode,
        data: data,
        message: data is Map ? data['message'] as String? : null,
      );
    } else {
      return ApiResponse(
        success: false,
        statusCode: response.statusCode,
        data: data,
        message: data is Map
            ? (data['message'] as String? ?? 'কিছু একটা সমস্যা হয়েছে')
            : 'কিছু একটা সমস্যা হয়েছে',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

class ApiResponse {
  final bool success;
  final int statusCode;
  final dynamic data;
  final String? message;

  ApiResponse({
    required this.success,
    required this.statusCode,
    this.data,
    this.message,
  });
}
