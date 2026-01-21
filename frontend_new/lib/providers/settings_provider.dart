// lib/providers/settings_provider.dart

import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../models/user_setting.dart';
import '../services/theme_service.dart';
import '../services/notification_service.dart';

class SettingsProvider with ChangeNotifier {
  final SettingsService _settingsService;
  final ThemeService _themeService;
  final NotificationService _notificationService;

  SettingsProvider(
      this._settingsService,
      this._themeService,
      this._notificationService,
      );

  UserSetting? _settings;
  bool _isLoading = false;
  String? _error;

  UserSetting? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> fetchSettings() async {
    _setLoading(true);
    try {
      _settings = await _settingsService.getUserSettings();
      _applySettings();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveSettings() async {
    if (_settings == null) return;

    _setLoading(true);
    try {
      _settings = await _settingsService.updateUserSettings(_settings!);
      _applySettings();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    if (_settings == null) return;

    _setLoading(true);
    try {
      _settings = await _settingsService.updateUserSettings(_settings!, data: data);
      _applySettings();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _applySettings() {
    if (_settings == null) return;

    try {
      // Apply theme - convert string to ThemeMode
      final themeMode = _stringToThemeMode(_settings!.theme);
      _themeService.setThemeMode(themeMode);

      // Apply notification settings
      _notificationService.setNotificationsEnabled(_settings!.notificationsEnabled);

      // Apply notification time
      final timeParts = _settings!.notificationTime.split(':');
      if (timeParts.length >= 2) {
        final hour = int.tryParse(timeParts[0]) ?? 9;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        final notificationTime = TimeOfDay(hour: hour, minute: minute);
        _notificationService.setNotificationTime(notificationTime);
      }

      // Apply budget alerts
      _notificationService.setBudgetAlerts(_settings!.budgetAlerts);

      // Apply transaction notifications
      _notificationService.setTransactionNotifications(_settings!.transactionNotifications);

      // Apply weekly reports
      _notificationService.setWeeklyReports(_settings!.weeklyReports);

      // Apply monthly reports
      _notificationService.setMonthlyReports(_settings!.monthlyReports);
    } catch (e) {
      debugPrint('Error applying settings: $e');
    }
  }

  /// Helper to convert String to ThemeMode
  ThemeMode _stringToThemeMode(String value) {
    switch (value.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _setError(String error) {
    if (error.startsWith('Exception: ')) {
      error = error.substring('Exception: '.length);
    }
    _error = error;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}