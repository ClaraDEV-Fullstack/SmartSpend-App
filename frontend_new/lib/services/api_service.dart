import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class ApiService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final AuthService _authService = AuthService();

  // --------- Get headers with valid access token ---------
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getValidAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // --------- Helper function: Retry if unauthorized ---------
  Future<http.Response> _retryIfUnauthorized(
      Future<http.Response> Function() request,
      ) async {
    http.Response response = await request();

    if (response.statusCode == 401) {
      // Try refreshing the access token
      final newToken = await _authService.refreshAccessToken();

      if (newToken != null) {
        response = await request(); // Retry once with refreshed token
      } else {
        // If refresh fails, clear tokens and logout user
        await _secureStorage.deleteAll();
        throw HttpException('Session expired. Please log in again.');
      }
    }
    return response;
  }

  // --------- Handle API errors gracefully ---------
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (statusCode >= 200 && statusCode < 300) {
      return body;
    } else if (statusCode == 400) {
      throw HttpException('Bad Request: ${body['detail'] ?? 'Invalid input'}');
    } else if (statusCode == 401) {
      throw HttpException('Unauthorized: ${body['detail'] ?? 'Token invalid'}');
    } else if (statusCode == 404) {
      throw HttpException('Not Found: ${body['detail'] ?? 'Resource missing'}');
    } else if (statusCode == 500) {
      throw HttpException('Server Error: ${body['detail'] ?? 'Try again later'}');
    } else {
      throw HttpException('Unexpected error: ${body.toString()}');
    }
  }

  // --------- GET request ---------
  Future<dynamic> get(String endpoint) async {
    try {
      return _retryIfUnauthorized(() async {
        final headers = await _getHeaders();
        final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
        final response = await http
            .get(url, headers: headers)
            .timeout(const Duration(seconds: 15));
        return response;
      }).then(_handleResponse);
    } on SocketException {
      throw HttpException('No internet connection.');
    } on HttpException catch (e) {
      rethrow;
    } on FormatException {
      throw HttpException('Invalid response format.');
    }
  }

  // --------- POST request ---------
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      return _retryIfUnauthorized(() async {
        final headers = await _getHeaders();
        final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
        final response = await http
            .post(url, headers: headers, body: jsonEncode(data))
            .timeout(const Duration(seconds: 15));
        return response;
      }).then(_handleResponse);
    } on SocketException {
      throw HttpException('No internet connection.');
    } on HttpException catch (e) {
      rethrow;
    } on FormatException {
      throw HttpException('Invalid response format.');
    }
  }

  // --------- PUT request ---------
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      return _retryIfUnauthorized(() async {
        final headers = await _getHeaders();
        final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
        final response = await http
            .put(url, headers: headers, body: jsonEncode(data))
            .timeout(const Duration(seconds: 15));
        return response;
      }).then(_handleResponse);
    } on SocketException {
      throw HttpException('No internet connection.');
    } on FormatException {
      throw HttpException('Invalid response format.');
    }
  }

  // --------- DELETE request ---------
  Future<dynamic> delete(String endpoint) async {
    try {
      return _retryIfUnauthorized(() async {
        final headers = await _getHeaders();
        final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
        final response = await http
            .delete(url, headers: headers)
            .timeout(const Duration(seconds: 15));
        return response;
      }).then(_handleResponse);
    } on SocketException {
      throw HttpException('No internet connection.');
    } on FormatException {
      throw HttpException('Invalid response format.');
    }
  }
}
