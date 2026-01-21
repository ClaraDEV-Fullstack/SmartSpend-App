// lib/core/services/category_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../../models/category.dart';
import 'api_client.dart';  // ✅ Import ApiClient

class CategoryService {
  final ApiClient _apiClient = ApiClient();  // ✅ Use ApiClient

  // ❌ REMOVED: _authService dependency
  // ❌ REMOVED: _getHeaders() method - ApiClient handles this

  Future<List<Category>> getCategories({String? type}) async {
    // Build URL with optional type filter
    String url = '${ApiConfig.baseUrl}${ApiConfig.categories}';
    if (type != null) {
      url += '?type=$type';
    }

    final response = await _apiClient.get(url);  // ✅ Uses ApiClient

    print('Categories status: ${response.statusCode}');
    print('Categories body: ${response.body}');

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);

      // Handle paginated response
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        final List<dynamic> results = data['results'];
        return results.map((json) => Category.fromJson(json)).toList();
      }
      // Handle direct list
      else if (data is List) {
        return data.map((json) => Category.fromJson(json)).toList();
      }
      // Handle single object
      else if (data is Map<String, dynamic>) {
        return [Category.fromJson(data)];
      }
      else {
        throw Exception('Unexpected response format');
      }
    } else {
      return _handleErrorResponse(response, 'Failed to load categories');
    }
  }

  Future<Category> createCategory(Category category) async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.categories}';

    final response = await _apiClient.post(  // ✅ Uses ApiClient
      url,
      body: category.toJson(),
    );

    print('Create category status: ${response.statusCode}');
    print('Create category body: ${response.body}');

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Category.fromJson(data);
    } else {
      return _handleErrorResponse(response, 'Failed to create category');
    }
  }

  Future<Category> updateCategory(Category category) async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.categoryDetail(category.id)}';

    final response = await _apiClient.put(  // ✅ Uses ApiClient
      url,
      body: category.toJson(),
    );

    print('Update category status: ${response.statusCode}');
    print('Update category body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Category.fromJson(data);
    } else {
      return _handleErrorResponse(response, 'Failed to update category');
    }
  }

  Future<void> deleteCategory(int categoryId) async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.categoryDetail(categoryId)}';

    final response = await _apiClient.delete(url);  // ✅ Uses ApiClient

    print('Delete category status: ${response.statusCode}');
    print('Delete category body: ${response.body}');

    if (response.statusCode != 204 && response.statusCode != 200) {
      _handleErrorResponse(response, 'Failed to delete category');
    }
  }

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