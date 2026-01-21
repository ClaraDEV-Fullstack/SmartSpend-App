// lib/core/services/api_client.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

/// A centralized HTTP client that automatically handles:
/// - Adding Authorization headers
/// - Token refresh on 401 responses
/// - Retrying failed requests after refresh
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isRefreshing = false;

  // ===========================
  // 🌐 HTTP METHODS
  // ===========================

  Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    return _executeWithAuth(() async {
      final authHeaders = await _getAuthHeaders(headers);
      return http.get(Uri.parse(url), headers: authHeaders);
    });
  }

  Future<http.Response> post(
      String url, {
        Map<String, String>? headers,
        Object? body,
      }) async {
    return _executeWithAuth(() async {
      final authHeaders = await _getAuthHeaders(headers);
      return http.post(
        Uri.parse(url),
        headers: authHeaders,
        body: body is String ? body : jsonEncode(body),
      );
    });
  }

  Future<http.Response> put(
      String url, {
        Map<String, String>? headers,
        Object? body,
      }) async {
    return _executeWithAuth(() async {
      final authHeaders = await _getAuthHeaders(headers);
      return http.put(
        Uri.parse(url),
        headers: authHeaders,
        body: body is String ? body : jsonEncode(body),
      );
    });
  }

  Future<http.Response> patch(
      String url, {
        Map<String, String>? headers,
        Object? body,
      }) async {
    return _executeWithAuth(() async {
      final authHeaders = await _getAuthHeaders(headers);
      return http.patch(
        Uri.parse(url),
        headers: authHeaders,
        body: body is String ? body : jsonEncode(body),
      );
    });
  }

  Future<http.Response> delete(String url, {Map<String, String>? headers}) async {
    return _executeWithAuth(() async {
      final authHeaders = await _getAuthHeaders(headers);
      return http.delete(Uri.parse(url), headers: authHeaders);
    });
  }

  // ===========================
  // 🔐 AUTH LOGIC
  // ===========================

  /// Executes request with automatic token refresh on 401
  Future<http.Response> _executeWithAuth(
      Future<http.Response> Function() requestFn,
      ) async {
    try {
      var response = await requestFn();

      // If 401 and not already refreshing, try to refresh token
      if (response.statusCode == 401 && !_isRefreshing) {
        print('⚠️ Got 401, attempting token refresh...');

        final refreshed = await _refreshToken();

        if (refreshed) {
          print('✅ Token refreshed, retrying request...');
          response = await requestFn();
        } else {
          print('❌ Token refresh failed');
          throw Exception('Session expired. Please login again.');
        }
      }

      return response;
    } on SocketException {
      throw Exception('No internet connection.');
    }
  }

  /// Get headers with current access token
  Future<Map<String, String>> _getAuthHeaders(Map<String, String>? extraHeaders) async {
    final token = await _secureStorage.read(key: 'access_token');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  /// Refresh the access token
  Future<bool> _refreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) {
        print('❌ No refresh token available');
        return false;
      }

      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tokenRefresh}');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh': refreshToken}),
      );

      print('🔄 Token refresh status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('access')) {
          await _secureStorage.write(key: 'access_token', value: data['access']);

          // Update refresh token if rotated
          if (data.containsKey('refresh')) {
            await _secureStorage.write(key: 'refresh_token', value: data['refresh']);
          }

          print('✅ New access token saved');
          return true;
        }
      }

      // Refresh failed - clear tokens
      await _secureStorage.deleteAll();
      return false;
    } catch (e) {
      print('❌ Token refresh error: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }
}