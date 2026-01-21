// lib/providers/category_provider.dart
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class CategoryProvider with ChangeNotifier {
  final CategoryService _categoryService;
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  CategoryProvider(this._categoryService);

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> fetchCategories({String? type}) async {
    _setLoading(true);
    try {
      _categories = await _categoryService.getCategories(type: type);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<Category> addCategory(Category category) async {
    _setLoading(true);
    try {
      final newCategory = await _categoryService.createCategory(category);
      _categories.add(newCategory);
      notifyListeners();
      return newCategory;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Category> updateCategory(Category category) async {
    _setLoading(true);
    try {
      final updatedCategory = await _categoryService.updateCategory(category);
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = updatedCategory;
        notifyListeners();
      }
      return updatedCategory;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteCategory(int categoryId) async {
    _setLoading(true);
    try {
      await _categoryService.deleteCategory(categoryId);
      _categories.removeWhere((c) => c.id == categoryId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  List<Category> getExpenseCategories() {
    return _categories.where((c) => c.type == 'expense').toList();
  }

  List<Category> getIncomeCategories() {
    return _categories.where((c) => c.type == 'income').toList();
  }

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