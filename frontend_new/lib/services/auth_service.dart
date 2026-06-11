// lib/core/services/auth_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/api_config.dart';
import '../../models/register_request.dart';
import '../../models/login_request.dart';
import '../../models/user.dart';
import 'api_client.dart';

class AuthService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final ApiClient _apiClient = ApiClient();

  // Google Sign-In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '459725446333-8q6go1hd3lkh6amjq8j8tlmt9f5l7vcf.apps.googleusercontent.com',
    scopes: [
      'email',
      'profile',
    ],
  );

  // ===========================
  // 🧍‍♀️ AUTHENTICATION
  // ===========================

  /// Register does NOT need ApiClient (no token yet)
  Future<User> register(RegisterRequest request) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.register}');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('Register status: ${response.statusCode}');
      print('Register body: ${response.body}');

      if (response.statusCode == 201) {
        final loginReq = LoginRequest(
          email: request.email,
          password: request.password,
        );
        await login(loginReq);
        return await getUserProfile();
      } else {
        return _handleErrorResponse(response, 'Failed to register');
      }
    } on SocketException {
      throw Exception('No internet connection.');
    } on FormatException {
      throw Exception('Invalid response format.');
    }
  }

  /// Login does NOT need ApiClient (no token yet)
  Future<void> login(LoginRequest request) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('Login status: ${response.statusCode}');
      print('Login body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data.containsKey('access') && data.containsKey('refresh')) {
          await _storeTokens(data['access'], data['refresh']);
        } else {
          throw Exception('Invalid token response format');
        }
      } else {
        _handleErrorResponse(response, 'Login failed');
      }
    } on SocketException {
      throw Exception('No internet connection.');
    } on FormatException {
      throw Exception('Invalid response format.');
    }
  }

  // ===========================
  // 🔵 GOOGLE SIGN-IN
  // ===========================

  /// Sign in with Google
  Future<User> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      print('Google Sign-In successful: ${googleUser.email}');
      print('Access Token: ${googleAuth.accessToken?.substring(0, 20)}...');

      // Send Google token to your backend for verification
      final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/google/');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'access_token': googleAuth.accessToken,
          'id_token': googleAuth.idToken,
          'email': googleUser.email,
          'display_name': googleUser.displayName ?? '',
          'photo_url': googleUser.photoUrl ?? '',
        }),
      );

      print('Google auth backend status: ${response.statusCode}');
      print('Google auth backend body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data.containsKey('access') && data.containsKey('refresh')) {
          await _storeTokens(data['access'], data['refresh']);
          return await getUserProfile();
        } else {
          throw Exception('Invalid token response from server');
        }
      } else {
        return _handleErrorResponse(response, 'Google sign-in failed');
      }
    } on SocketException {
      throw Exception('No internet connection.');
    } catch (e) {
      print('Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Check if user is signed in with Google
  Future<bool> isSignedInWithGoogle() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Sign out from Google
  Future<void> signOutFromGoogle() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      print('Error signing out from Google: $e');
    }
  }

  /// Disconnect Google account completely
  Future<void> disconnectGoogle() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.disconnect();
      }
    } catch (e) {
      print('Error disconnecting Google: $e');
    }
  }

  /// Get current Google user
  GoogleSignInAccount? getCurrentGoogleUser() {
    return _googleSignIn.currentUser;
  }

  // ===========================
  // 👤 USER PROFILE
  // ===========================

  /// ✅ Uses ApiClient - auto token refresh on 401
  Future<User> getUserProfile() async {
    final response = await _apiClient.get(
      ApiConfig.fullUrl(ApiConfig.profile),
    );

    print('Profile status: ${response.statusCode}');
    print('Profile body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Profile image URL: ${data['profile_image_url']}');
      return User.fromJson(data);
    } else {
      throw Exception('Failed to get profile');
    }
  }

  /// ✅ Uses ApiClient - auto token refresh on 401
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final response = await _apiClient.post(
      '${ApiConfig.baseUrl}${ApiConfig.passwordChange}',
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );

    print('Change password status: ${response.statusCode}');
    print('Change password body: ${response.body}');

    if (response.statusCode != 200) {
      _handleErrorResponse(response, 'Failed to change password');
    }
  }

  /// ✅ Uses ApiClient - auto token refresh on 401
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? avatar,
  }) async {
    final body = <String, dynamic>{};
    if (firstName != null) body['first_name'] = firstName;
    if (lastName != null) body['last_name'] = lastName;
    if (username != null) body['username'] = username;
    if (avatar != null) body['avatar'] = avatar;

    final response = await _apiClient.patch(
      '${ApiConfig.baseUrl}${ApiConfig.profile}',
      body: body,
    );

    print('Update Profile status: ${response.statusCode}');
    print('Update Profile body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return User.fromJson(decoded);
        } else {
          throw Exception('Invalid response format');
        }
      } catch (e) {
        throw Exception('Failed to parse updated profile: $e');
      }
    } else {
      return _handleErrorResponse(response, 'Failed to update profile');
    }
  }

  /// ✅ Uses ApiClient - auto token refresh on 401
  Future<void> deleteAccount({String? password, String? confirmation}) async {
    final body = <String, dynamic>{};
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }
    if (confirmation != null && confirmation.isNotEmpty) {
      body['confirmation'] = confirmation;
    }

    final refreshToken = await getRefreshToken();
    if (refreshToken != null) {
      body['refresh'] = refreshToken;
    }

    final response = await _apiClient.post(
      ApiConfig.fullUrl(ApiConfig.deleteAccount),
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      await logout();
    } else {
      _handleErrorResponse(response, 'Failed to delete account');
    }
  }

  // ===========================
  // 🔐 TOKEN MANAGEMENT
  // ===========================

  Future<void> _storeTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: 'access_token', value: accessToken);
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<String?> getAccessToken() async =>
      await _secureStorage.read(key: 'access_token');

  Future<String?> getRefreshToken() async =>
      await _secureStorage.read(key: 'refresh_token');

  Future<bool> hasStoredSession() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null || refreshToken != null;
  }

  Future<void> logout() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken != null) {
      try {
        await _apiClient.post(
          ApiConfig.fullUrl(ApiConfig.logout),
          body: {'refresh': refreshToken},
        );
      } catch (_) {
        // Continue local logout even if server blacklist fails
      }
    }

    await signOutFromGoogle();
    await _secureStorage.deleteAll();
  }

  Future<String?> getValidAccessToken() async {
    String? accessToken = await getAccessToken();
    if (accessToken == null) return null;

    try {
      final parts = accessToken.split('.');
      if (parts.length != 3) return null;

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload['exp'];
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (exp < now) {
        final refreshed = await refreshAccessToken();
        return refreshed;
      }

      return accessToken;
    } catch (e) {
      await logout();
      return null;
    }
  }

  /// Token refresh - uses direct http (not ApiClient) to avoid circular dependency
  Future<String?> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return null;

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tokenRefresh}');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh': refreshToken}),
      );

      print('Token refresh status: ${response.statusCode}');
      print('Token refresh body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('access')) {
          final newAccess = data['access'];
          await _secureStorage.write(key: 'access_token', value: newAccess);

          // Also update refresh token if server rotates it
          if (data.containsKey('refresh')) {
            await _secureStorage.write(key: 'refresh_token', value: data['refresh']);
          }

          return newAccess;
        } else {
          throw Exception('Invalid token refresh response');
        }
      } else {
        await logout();
        return null;
      }
    } on SocketException {
      throw Exception('No internet connection.');
    } on FormatException {
      throw Exception('Invalid token refresh response format.');
    }
  }

  // ===========================
  // 🛠️ ERROR HANDLING
  // ===========================

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