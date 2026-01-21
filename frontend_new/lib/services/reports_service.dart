// lib/services/reports_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_client.dart';  // ✅ Import ApiClient

class ReportsService {
  final ApiClient _apiClient = ApiClient();  // ✅ Use ApiClient

  // ❌ REMOVED: _authService dependency

  Future<Map<String, dynamic>> getReportSummary({
    String? startDate,
    String? endDate,
    int? categoryId,
  }) async {
    // Build URL with optional filters
    String url = '${ApiConfig.baseUrl}/api/reports/summary/';
    List<String> queryParams = [];

    if (startDate != null) {
      queryParams.add('start_date=$startDate');
    }
    if (endDate != null) {
      queryParams.add('end_date=$endDate');
    }
    if (categoryId != null) {
      queryParams.add('category_id=$categoryId');
    }

    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    final response = await _apiClient.get(url);  // ✅ Uses ApiClient

    print('Report summary status: ${response.statusCode}');
    print('Report summary body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return _handleErrorResponse(response, 'Failed to load report summary');
    }
  }

  dynamic _handleErrorResponse(http.Response response, String defaultMessage) {
    try {
      final errorData = jsonDecode(response.body);
      if (errorData is Map<String, dynamic>) {
        if (errorData.containsKey('detail')) {
          throw Exception(errorData['detail']);
        } else if (errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        } else if (errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        }
      }
      throw Exception('$defaultMessage: ${response.statusCode}');
    } catch (e) {
      if (e is Exception) throw e;
      throw Exception('$defaultMessage: ${response.statusCode} - ${response.body}');
    }
  }
}