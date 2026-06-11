import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_new/config/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('auth endpoints are defined', () {
      expect(ApiConfig.login, '/api/users/login/');
      expect(ApiConfig.logout, '/api/users/logout/');
      expect(ApiConfig.deleteAccount, '/api/users/me/delete/');
      expect(ApiConfig.tokenRefresh, '/api/users/token/refresh/');
    });

    test('ai endpoints are defined', () {
      expect(ApiConfig.aiAssist, '/api/ai/assist/');
      expect(ApiConfig.aiHistory, '/api/ai/history/');
      expect(ApiConfig.aiStatus, '/api/ai/status/');
    });
  });
}
