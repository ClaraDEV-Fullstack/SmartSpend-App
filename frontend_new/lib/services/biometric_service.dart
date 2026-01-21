// lib/services/biometric_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Conditionally import local_auth only on non-web platforms
import 'package:local_auth/local_auth.dart' if (dart.library.html) 'biometric_stub.dart';

class BiometricService with ChangeNotifier {
  LocalAuthentication? _auth;

  bool _isAvailable = false;
  bool _isEnabled = false;
  List<BiometricType> _availableBiometrics = [];

  bool get isAvailable => _isAvailable;
  bool get isEnabled => _isEnabled;
  List<BiometricType> get availableBiometrics => _availableBiometrics;

  String get biometricTypeName {
    if (kIsWeb) return 'Biometric';
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris';
    }
    return 'Biometric';
  }

  /// Initialize and check biometric availability
  Future<void> initialize() async {
    // Biometrics not available on web
    if (kIsWeb) {
      _isAvailable = false;
      _isEnabled = false;
      notifyListeners();
      return;
    }

    try {
      _auth = LocalAuthentication();

      // Check if biometrics are available
      bool canCheck = await _auth!.canCheckBiometrics;
      bool isSupported = await _auth!.isDeviceSupported();
      _isAvailable = canCheck || isSupported;

      if (_isAvailable) {
        _availableBiometrics = await _auth!.getAvailableBiometrics();
      }

      // Load saved preference
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('biometric_enabled') ?? false;

      debugPrint('Biometric available: $_isAvailable');
      debugPrint('Available biometrics: $_availableBiometrics');
      debugPrint('Biometric enabled: $_isEnabled');

      notifyListeners();
    } on PlatformException catch (e) {
      debugPrint('Error checking biometrics: $e');
      _isAvailable = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking biometrics: $e');
      _isAvailable = false;
      notifyListeners();
    }
  }

  /// Enable or disable biometric authentication
  Future<bool> setBiometricEnabled(bool enabled) async {
    if (!_isAvailable || kIsWeb) return false;

    if (enabled) {
      final authenticated = await authenticate(
        reason: 'Authenticate to enable biometric login',
      );

      if (!authenticated) return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', enabled);
    _isEnabled = enabled;
    notifyListeners();

    return true;
  }

  /// Authenticate using biometrics
  Future<bool> authenticate({String reason = 'Please authenticate to continue'}) async {
    if (!_isAvailable || kIsWeb || _auth == null) return false;

    try {
      final authenticated = await _auth!.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      debugPrint('Authentication result: $authenticated');
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('Authentication error: $e');
      return false;
    } catch (e) {
      debugPrint('Authentication error: $e');
      return false;
    }
  }

  /// Check if biometric authentication should be used
  bool shouldUseBiometric() {
    return _isAvailable && _isEnabled && !kIsWeb;
  }
}