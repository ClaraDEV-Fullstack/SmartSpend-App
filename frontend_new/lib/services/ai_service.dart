// lib/services/ai_service.dart

import 'dart:convert';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../models/ai_message.dart';
import '../models/ai_action.dart';
import '../models/ai_context.dart';
import '../utils/app_logger.dart';

class AiService {
  final ApiClient _apiClient = ApiClient();

  static const int _maxRequestsPerMinute = 20;
  final List<DateTime> _requestTimestamps = [];

  Future<AiMessage> sendMessage(String message, AiContext context) async {
    if (!_canMakeRequest()) {
      throw Exception('Too many requests. Please wait a moment.');
    }

    _recordRequest();

    final url = ApiConfig.fullUrl(ApiConfig.aiAssist);
    final response = await _apiClient.post(
      url,
      body: {
        'message': message,
        'context': context.toJson(),
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      AiAction? action;
      if (data['action'] != null && data['action'] is Map<String, dynamic>) {
        action = AiAction.fromJson(data['action']);
      }

      return AiMessage.assistant(
        data['response']?.toString() ??
            data['message']?.toString() ??
            'I understand.',
        action: action,
      );
    }

    throw _handleError(response);
  }

  Future<List<Map<String, dynamic>>> getHistory({int limit = 50}) async {
    final url = '${ApiConfig.fullUrl(ApiConfig.aiHistory)}?limit=$limit';
    final response = await _apiClient.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
    }

    throw _handleError(response);
  }

  Future<void> clearHistory() async {
    final response = await _apiClient.delete(ApiConfig.fullUrl(ApiConfig.aiHistory));
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw _handleError(response);
    }
  }

  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await _apiClient.get(ApiConfig.fullUrl(ApiConfig.aiStatus));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'Failed to get status'};
    } catch (e) {
      appLogger.w('AI status check failed', error: e);
      return {'error': e.toString()};
    }
  }

  bool _canMakeRequest() {
    final now = DateTime.now();
    _requestTimestamps.removeWhere(
      (timestamp) => now.difference(timestamp).inMinutes >= 1,
    );
    return _requestTimestamps.length < _maxRequestsPerMinute;
  }

  void _recordRequest() {
    _requestTimestamps.add(DateTime.now());
  }

  Exception _handleError(dynamic response) {
    try {
      final data = jsonDecode(response.body);
      final message = data['detail'] ?? data['error'] ?? data['message'];
      return Exception(message ?? 'AI request failed');
    } catch (_) {
      return Exception('AI request failed: ${response.statusCode}');
    }
  }
}
