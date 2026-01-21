// lib/services/transaction_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../../models/transaction.dart';
import 'api_client.dart';  // ✅ Import ApiClient

class TransactionService {
  final ApiClient _apiClient = ApiClient();  // ✅ Use ApiClient

  // ❌ REMOVED: _authService dependency
  // ❌ REMOVED: _getHeaders() method

  Future<List<Transaction>> getTransactions({
    int? categoryId,
    String? type,
    String? startDate,
    String? endDate,
    String? currency,
  }) async {
    String url = '${ApiConfig.baseUrl}${ApiConfig.transactions}';
    List<String> queryParams = [];

    if (categoryId != null) queryParams.add('category=$categoryId');
    if (type != null) queryParams.add('type=$type');
    if (startDate != null) queryParams.add('start_date=$startDate');
    if (endDate != null) queryParams.add('end_date=$endDate');
    if (currency != null) queryParams.add('currency=$currency');

    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    final response = await _apiClient.get(url);  // ✅ Uses ApiClient

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded.map((e) => Transaction.fromJson(e)).toList();
      }

      if (decoded is Map<String, dynamic> && decoded.containsKey('results')) {
        final List results = decoded['results'];
        return results.map((e) => Transaction.fromJson(e)).toList();
      }

      throw Exception('Unexpected transactions response format');
    } else {
      return _handleErrorResponse(response, 'Failed to load transactions');
    }
  }

  Future<Transaction> createTransaction(Transaction transaction) async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.transactions}';

    // Create a clean request body with only required fields
    final requestBody = {
      'type': transaction.type,
      'amount': transaction.amount.toString(),
      'description': transaction.description,
      'date': _formatDate(transaction.date),
      'category_id': transaction.category.id,
      'currency': transaction.currency,
    };

    print('=== CREATE TRANSACTION ===');
    print('URL: $url');
    print('Request Body: ${jsonEncode(requestBody)}');

    final response = await _apiClient.post(url, body: requestBody);  // ✅ Uses ApiClient

    print('Status: ${response.statusCode}');
    print('Response: ${response.body}');

    if (response.statusCode == 201) {
      return Transaction.fromJson(jsonDecode(response.body));
    } else {
      return _handleErrorResponse(response, 'Failed to create transaction');
    }
  }

  Future<Transaction> updateTransaction(Transaction transaction) async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.transactionDetail(transaction.id)}';

    // Create a clean request body with only required fields
    final requestBody = {
      'type': transaction.type,
      'amount': transaction.amount.toString(),
      'description': transaction.description,
      'date': _formatDate(transaction.date),
      'category_id': transaction.category.id,
      'currency': transaction.currency,
    };

    print('=== UPDATE TRANSACTION ===');
    print('URL: $url');
    print('Request Body: ${jsonEncode(requestBody)}');

    final response = await _apiClient.put(url, body: requestBody);  // ✅ Uses ApiClient

    print('Status: ${response.statusCode}');
    print('Response: ${response.body}');

    if (response.statusCode == 200) {
      return Transaction.fromJson(jsonDecode(response.body));
    } else {
      return _handleErrorResponse(response, 'Failed to update transaction');
    }
  }

  Future<void> deleteTransaction(int transactionId) async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.transactionDetail(transactionId)}';

    print('=== DELETE TRANSACTION ===');
    print('URL: $url');

    final response = await _apiClient.delete(url);  // ✅ Uses ApiClient

    print('Status: ${response.statusCode}');
    print('Response: ${response.body}');

    if (response.statusCode != 204 && response.statusCode != 200) {
      _handleErrorResponse(response, 'Failed to delete transaction');
    }
  }

  Future<Map<String, dynamic>> getTransactionSummary({
    int? categoryId,
    String? type,
    String? startDate,
    String? endDate,
    int? month,
    int? year,
    String? currency,
  }) async {
    String url = '${ApiConfig.baseUrl}${ApiConfig.transactionSummary}';
    List<String> queryParams = [];

    if (categoryId != null) queryParams.add('category=$categoryId');
    if (type != null) queryParams.add('type=$type');
    if (startDate != null) queryParams.add('start_date=$startDate');
    if (endDate != null) queryParams.add('end_date=$endDate');
    if (month != null) queryParams.add('month=$month');
    if (year != null) queryParams.add('year=$year');
    if (currency != null) queryParams.add('currency=$currency');

    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    final response = await _apiClient.get(url);  // ✅ Uses ApiClient

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return _handleErrorResponse(response, 'Failed to load transaction summary');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  dynamic _handleErrorResponse(http.Response response, String defaultMessage) {
    print('=== ERROR RESPONSE ===');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    try {
      final errorData = jsonDecode(response.body);

      if (errorData is Map<String, dynamic>) {
        // Handle different error formats
        if (errorData.containsKey('detail')) {
          throw Exception(errorData['detail']);
        }
        if (errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
        if (errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        }
        if (errorData.containsKey('non_field_errors')) {
          throw Exception(errorData['non_field_errors'][0]);
        }

        // Handle field-specific errors like {"field_name": ["error message"]}
        final errors = <String>[];
        errorData.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            errors.add('$key: ${value.join(", ")}');
          } else if (value is String) {
            errors.add('$key: $value');
          }
        });

        if (errors.isNotEmpty) {
          throw Exception(errors.join('; '));
        }
      }

      throw Exception('$defaultMessage: ${response.statusCode}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('$defaultMessage: ${response.statusCode} - ${response.body}');
    }
  }
}