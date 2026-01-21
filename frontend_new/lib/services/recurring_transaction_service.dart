// lib/services/recurring_transaction_service.dart

import 'dart:convert';
import '../config/api_config.dart';
import '../models/recurring_transaction.dart';
import 'api_client.dart';  // ✅ Import ApiClient

class RecurringTransactionService {
  final ApiClient _apiClient = ApiClient();  // ✅ Use ApiClient

  // ❌ REMOVED: _authService dependency
  // ❌ REMOVED: _getHeaders() method

  Future<List<RecurringTransaction>> getRecurringTransactions() async {
    final url = ApiConfig.fullUrl(ApiConfig.recurringTransactions);

    final response = await _apiClient.get(url);  // ✅ Uses ApiClient

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => RecurringTransaction.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load recurring transactions: ${response.body}');
    }
  }

  Future<RecurringTransaction> createRecurringTransaction(RecurringTransaction transaction) async {
    final url = ApiConfig.fullUrl(ApiConfig.recurringTransactions);

    final body = {
      'type': transaction.type,
      'amount': transaction.amount,
      'description': transaction.description,
      'category_id': transaction.categoryId,
      'currency': transaction.currency,
      'frequency': transaction.frequency.name,
      'next_run_date': transaction.nextRunDate.toIso8601String().split('T')[0],
      'end_date': transaction.endDate?.toIso8601String().split('T')[0],
      'total_executions': transaction.totalExecutions,
    };

    final response = await _apiClient.post(url, body: body);  // ✅ Uses ApiClient

    if (response.statusCode == 201) {
      return RecurringTransaction.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create recurring transaction: ${response.body}');
    }
  }

  Future<RecurringTransaction> updateRecurringTransaction(RecurringTransaction transaction) async {
    final url = ApiConfig.fullUrl('${ApiConfig.recurringTransactions}${transaction.id}/');

    final body = {
      'type': transaction.type,
      'amount': transaction.amount,
      'description': transaction.description,
      'category_id': transaction.categoryId,
      'currency': transaction.currency,
      'frequency': transaction.frequency.name,
      'next_run_date': transaction.nextRunDate.toIso8601String().split('T')[0],
      'end_date': transaction.endDate?.toIso8601String().split('T')[0],
      'total_executions': transaction.totalExecutions,
    };

    final response = await _apiClient.put(url, body: body);  // ✅ Uses ApiClient

    if (response.statusCode == 200) {
      return RecurringTransaction.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update recurring transaction: ${response.body}');
    }
  }

  Future<void> deleteRecurringTransaction(int id) async {
    final url = ApiConfig.fullUrl('${ApiConfig.recurringTransactions}$id/');

    final response = await _apiClient.delete(url);  // ✅ Uses ApiClient

    if (response.statusCode != 204) {
      throw Exception('Failed to delete recurring transaction: ${response.body}');
    }
  }
}