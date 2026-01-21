// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../models/register_request.dart';
import '../models/login_request.dart';
import '../services/auth_service.dart';
import '../services/image_upload_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final ImageUploadService _imageUploadService = ImageUploadService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._authService);

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;

  Future<String?> getToken() => _authService.getAccessToken();

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ===========================
  // 🧍‍♀️ EXISTING AUTH METHODS
  // ===========================

  Future<void> register(RegisterRequest request) async {
    _setLoading(true);
    try {
      _user = await _authService.register(request);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login(LoginRequest request) async {
    _setLoading(true);
    try {
      await _authService.login(request);
      _user = await _authService.getUserProfile();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> getUserProfile() async {
    _setLoading(true);
    try {
      _user = await _authService.getUserProfile();
    } catch (e) {
      _setError(e.toString());
      _user = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    try {
      await _authService.changePassword(currentPassword, newPassword);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _user = null;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ===========================
  // 🔵 GOOGLE SIGN-IN METHODS
  // ===========================

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    _setLoading(true);
    clearError();

    try {
      _user = await _authService.signInWithGoogle();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Check if signed in with Google
  Future<bool> isSignedInWithGoogle() async {
    return await _authService.isSignedInWithGoogle();
  }

  // ===========================
  // 🖼️ PROFILE IMAGE METHODS
  // ===========================

  /// Upload profile image from XFile
  Future<void> uploadProfileImage(XFile imageFile) async {
    try {
      _setLoading(true);
      clearError();

      // Get token from AuthService (the correct way!)
      final token = await _authService.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated. Please login again.');
      }

      print('Got token for upload: ${token.substring(0, 20)}...'); // Debug

      // Upload image with token
      await _imageUploadService.uploadProfileImage(imageFile, token);

      // Refresh user profile to get updated data
      await getUserProfile();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Pick and upload profile image from source
  Future<void> uploadProfilePicture(ImageSource source) async {
    try {
      final XFile? image = await _imageUploadService.pickImage(source);
      if (image == null) return; // User cancelled

      _setLoading(true);
      clearError();

      // Get token from AuthService
      final token = await _authService.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated. Please login again.');
      }

      // Upload with token
      await _imageUploadService.uploadProfileImage(image, token);

      // Refresh User Profile to get the new URL
      await getUserProfile();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete profile image
  Future<void> deleteProfileImage() async {
    try {
      _setLoading(true);
      clearError();

      // Get token from AuthService
      final token = await _authService.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated. Please login again.');
      }

      await _imageUploadService.deleteProfileImage(token);

      // Refresh user profile
      await getUserProfile();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ===========================
  // 🔧 PRIVATE HELPERS
  // ===========================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    if (error.startsWith('Exception: ')) {
      error = error.substring('Exception: '.length);
    }
    _error = error;
    notifyListeners();
  }
}