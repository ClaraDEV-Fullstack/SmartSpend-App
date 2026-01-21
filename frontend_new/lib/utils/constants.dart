import 'dart:io';

class AppConstants {
  // App Info
  static const String appName = 'Smart Spend';
  static const String appVersion = '1.0.0';

  // --- API CONFIGURATION ---

  // Use 10.0.2.2 for Android Emulator, 127.0.0.1 for Windows/Web
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    } else {
      return 'http://127.0.0.1:8000/api';
    }
  }

  // Endpoints
  static const String loginEndpoint = '/auth/login/';
  static const String registerEndpoint = '/auth/register/';
  static const String expensesEndpoint = '/expenses/';
}