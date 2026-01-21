// lib/services/ai_service.dart

import 'dart:convert';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../models/ai_message.dart';
import '../models/ai_action.dart';
import '../models/ai_context.dart';

class AiService {
  final ApiClient _apiClient = ApiClient();

  // Rate limiting
  static const int _maxRequestsPerMinute = 20;
  final List<DateTime> _requestTimestamps = [];

  /// Send message to AI and get response
  Future<AiMessage> sendMessage(String message, AiContext context) async {
    // Rate limiting check
    if (!_canMakeRequest()) {
      throw Exception('Too many requests. Please wait a moment.');
    }

    _recordRequest();

    final url = '${ApiConfig.baseUrl}/api/ai/assist/';

    final requestBody = {
      'message': message,
      'context': context.toJson(),
    };

    print('=== AI REQUEST ===');
    print('URL: $url');
    print('Message: $message');

    final response = await _apiClient.post(url, body: requestBody);

    print('=== AI RESPONSE ===');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      AiAction? action;
      if (data['action'] != null && data['action'] is Map<String, dynamic>) {
        action = AiAction.fromJson(data['action']);
      }

      return AiMessage.assistant(
        data['response']?.toString() ?? data['message']?.toString() ?? 'I understand.',
        action: action,
      );
    } else {
      throw _handleError(response);
    }
  }

  /// Get AI service status
  Future<Map<String, dynamic>> getStatus() async {
    final url = '${ApiConfig.baseUrl}/api/ai/status/';

    try {
      final response = await _apiClient.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'Failed to get status'};
    } catch (e) {
      return {'error': e.toString()};

    }

  }

  /// Rate limiting helpers
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