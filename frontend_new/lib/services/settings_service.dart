// lib/core/services/settings_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../../models/user_setting.dart';
import 'api_client.dart';  // ✅ Import ApiClient

class SettingsService {
  final ApiClient _apiClient = ApiClient();  // ✅ Use ApiClient

  // ❌ REMOVED: _authService dependency
  // ❌ REMOVED: _getHeaders() method

  Future<UserSetting> getUserSettings() async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.settingsUser}';

    final response = await _apiClient.get(url);  // ✅ Uses ApiClient

    print('User settings status: ${response.statusCode}');
    print('User settings body: ${response.body}');

    if (response.statusCode == 200) {
      return UserSetting.fromJson(jsonDecode(response.body));
    } else {
      return _handleErrorResponse(response, 'Failed to load user settings');
    }
  }

  Future<UserSetting> updateUserSettings(UserSetting settings, {Map<String, dynamic>? data}) async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.settingsUserUpdate}';

    Map<String, dynamic> requestData = data ?? settings.toJson();

    // Convert to snake_case for API
    if (requestData.containsKey('notificationsEnabled')) {
      requestData['notifications_enabled'] = requestData['notificationsEnabled'];
      requestData.remove('notificationsEnabled');
    }

    if (requestData.containsKey('emailReports')) {
      requestData['email_reports'] = requestData['emailReports'];
      requestData.remove('emailReports');
    }

    final response = await _apiClient.put(url, body: requestData);  // ✅ Uses ApiClient

    print('Update user settings status: ${response.statusCode}');
    print('Update user settings body: ${response.body}');

    if (response.statusCode == 200) {
      return UserSetting.fromJson(jsonDecode(response.body));
    } else {
      return _handleErrorResponse(response, 'Failed to update user settings');
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