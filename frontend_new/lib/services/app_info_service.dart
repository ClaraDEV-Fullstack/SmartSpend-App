// lib/services/app_info_service.dart

import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  static AppInfoService? _instance;
  static AppInfoService get instance => _instance ??= AppInfoService._();

  AppInfoService._();

  PackageInfo? _packageInfo;

  Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  String get appName => _packageInfo?.appName ?? 'SmartSpend';
  String get packageName => _packageInfo?.packageName ?? '';
  String get version => _packageInfo?.version ?? '1.0.0';
  String get buildNumber => _packageInfo?.buildNumber ?? '1';

  String get fullVersion => '$version ($buildNumber)';
}