// lib/services/biometric_stub.dart
// Stub file for web platform

class LocalAuthentication {
  Future<bool> get canCheckBiometrics => Future.value(false);
  Future<bool> isDeviceSupported() async => false;
  Future<List<BiometricType>> getAvailableBiometrics() async => [];
  Future<bool> authenticate({
    required String localizedReason,
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async => false;
}

class AuthenticationOptions {
  final bool stickyAuth;
  final bool biometricOnly;

  const AuthenticationOptions({
    this.stickyAuth = false,
    this.biometricOnly = false,
  });
}

enum BiometricType { face, fingerprint, iris, strong, weak }