import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ChangeNotifier {
  static const _localeKey = 'app_locale';

  Locale? _locale;

  Locale? get locale => _locale;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code == null || code == 'system') {
      _locale = null;
    } else {
      _locale = Locale(code);
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.setString(_localeKey, 'system');
    } else {
      await prefs.setString(_localeKey, locale.languageCode);
    }
    notifyListeners();
  }

  String get currentLanguageCode => _locale?.languageCode ?? 'system';
}
