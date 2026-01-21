// lib/services/image_upload_service.dart

import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import '../config/api_config.dart';

class ImageUploadService {
  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  /// Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('Failed to capture image: $e');
    }
  }

  /// Generic pick image method
  Future<XFile?> pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      return pickImageFromCamera();
    } else {
      return pickImageFromGallery();
    }
  }

  /// Upload profile image to server - NOW ACCEPTS TOKEN AS PARAMETER
  Future<String?> uploadProfileImage(XFile imageFile, String token) async {
    try {
      if (token.isEmpty) {
        throw Exception('Not authenticated');
      }

      // Use ApiConfig for the URL
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/profile/image/');

      print('Uploading image to: $uri'); // Debug log
      print('Using token: ${token.substring(0, 20)}...'); // Debug log (partial token)

      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      if (kIsWeb) {
        // Web handling
        final bytes = await imageFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'profile_image',
          bytes,
          filename: imageFile.name,
        ));
      } else {
        // Mobile handling
        request.files.add(await http.MultipartFile.fromPath(
          'profile_image',
          imageFile.path,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload response status: ${response.statusCode}'); // Debug log
      print('Upload response body: ${response.body}'); // Debug log

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          return data['profile_image_url'] ?? data['profile_image'] ?? 'Success';
        } catch (_) {
          return 'Success';
        }
      } else {
        String errorMessage = 'Failed to upload image';
        try {
          final error = jsonDecode(response.body);
          errorMessage = error['detail'] ?? error['message'] ?? errorMessage;
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  /// Delete profile image - NOW ACCEPTS TOKEN AS PARAMETER
  Future<void> deleteProfileImage(String token) async {
    try {
      if (token.isEmpty) {
        throw Exception('Not authenticated');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/profile/image/');
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Delete response status: ${response.statusCode}'); // Debug log

      if (response.statusCode != 200 && response.statusCode != 204) {
        String errorMessage = 'Failed to delete image';
        try {
          final error = jsonDecode(response.body);
          errorMessage = error['detail'] ?? error['message'] ?? errorMessage;
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to delete profile image: $e');
    }
  }
}