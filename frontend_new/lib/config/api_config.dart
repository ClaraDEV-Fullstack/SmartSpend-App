// lib/config/api_config.dart

import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Dynamic base URL based on platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  // API prefix
  static const String _apiPrefix = '/api';

  // ===========================
  // 🧍‍♀️ USER AUTHENTICATION
  // ===========================
  static const String register = '$_apiPrefix/users/register/';
  static const String login = '$_apiPrefix/users/login/';
  static const String profile = '$_apiPrefix/users/me/';
  static const String profileImage = '$_apiPrefix/users/me/image/';  // ADD THIS
  static const String tokenRefresh = '$_apiPrefix/users/token/refresh/';
  static const String passwordChange = '$_apiPrefix/settings/auth/password/change/';

  // ===========================
  // 💰 TRANSACTION & CATEGORY
  // ===========================
  static const String categories = '$_apiPrefix/categories/v1/';
  static const String transactions = '$_apiPrefix/transactions/';
  static const String transactionSummary = '$_apiPrefix/transactions/summary/';
  static const String recurringTransactions = '$_apiPrefix/recurring-transactions/';

  static String categoryDetail(dynamic id) => '$_apiPrefix/categories/v1/$id/';
  static String transactionDetail(dynamic id) => '$_apiPrefix/transactions/$id/';

  // ===========================
  // 📊 REPORTS & SETTINGS
  // ===========================
  static const String reportsSummary = '$_apiPrefix/reports/summary/';
  static const String settingsUserUpdate = '$_apiPrefix/settings/user/update/';
  static const String settingsUser = '$_apiPrefix/settings/user/';

  // ===========================
  // 🔧 HELPER
  // ===========================
  static String fullUrl(String path) => '$baseUrl$path';

  // Add to existing ApiConfig class

// ===========================
// 🤖 AI ASSISTANT
// ===========================
  static const String aiAssist = '$_apiPrefix/ai/assist/';
  static const String aiHistory = '$_apiPrefix/ai/history/';


}
