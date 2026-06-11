// lib/providers/category_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/category_service.dart';
import '../services/local_database_service.dart';
import '../services/sync_service.dart';

class CategoryProvider with ChangeNotifier {
  final CategoryService _categoryService;
  final LocalDatabaseService _localDb;
  final SyncService _syncService;

  static int _tempIdCounter = -1;

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;
  bool _isOfflineMode = false;

  CategoryProvider(this._categoryService, this._localDb, this._syncService);

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOfflineMode => _isOfflineMode;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  int _nextTempId() => _tempIdCounter--;

  bool _isNetworkError(Object e) {
    if (e is SocketException) return true;
    final message = e.toString().toLowerCase();
    return message.contains('no internet') ||
        message.contains('socket') ||
        message.contains('connection') ||
        message.contains('network');
  }

  Future<void> fetchCategories({String? type}) async {
    _setLoading(true);
    try {
      _categories = await _categoryService.getCategories(type: type);
      await _localDb.saveAllCategories(_categories);
      _isOfflineMode = false;
    } catch (e) {
      _setError(e.toString());
      try {
        var localCategories = await _localDb.getAllCategories();
        if (type != null) {
          localCategories =
              localCategories.where((c) => c.type == type).toList();
        }
        _categories = localCategories;
        _isOfflineMode = true;
      } catch (_) {
        _categories = [];
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> syncPendingChanges() async {
    await _syncService.syncAll();
    await fetchCategories();
  }

  Future<Category> addCategory(Category category) async {
    _setLoading(true);
    try {
      final newCategory = await _categoryService.createCategory(category);
      _categories.add(newCategory);
      await _localDb.saveCategory(newCategory);
      _isOfflineMode = false;
      notifyListeners();
      return newCategory;
    } catch (e) {
      if (_isNetworkError(e)) {
        final offlineCategory = category.copyWith(id: _nextTempId());
        _categories.add(offlineCategory);
        await _localDb.saveCategory(offlineCategory);
        await _syncService.queueCategoryAction('CREATE', offlineCategory, null);
        _isOfflineMode = true;
        notifyListeners();
        return offlineCategory;
      }
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Category> updateCategory(Category category) async {
    _setLoading(true);
    try {
      if (category.isPendingSync) {
        final updated = category;
        final index = _categories.indexWhere((c) => c.id == category.id);
        if (index != -1) {
          _categories[index] = updated;
        }
        await _localDb.saveCategory(updated);
        await _syncService.replaceQueuedCategoryCreate(updated);
        notifyListeners();
        return updated;
      }

      final updatedCategory = await _categoryService.updateCategory(category);
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = updatedCategory;
      }
      await _localDb.saveCategory(updatedCategory);
      _isOfflineMode = false;
      notifyListeners();
      return updatedCategory;
    } catch (e) {
      if (_isNetworkError(e)) {
        final index = _categories.indexWhere((c) => c.id == category.id);
        if (index != -1) {
          _categories[index] = category;
        }
        await _localDb.saveCategory(category);
        await _syncService.queueCategoryAction('UPDATE', category, category.id);
        _isOfflineMode = true;
        notifyListeners();
        return category;
      }
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteCategory(int categoryId) async {
    _setLoading(true);
    try {
      if (categoryId < 0) {
        _categories.removeWhere((c) => c.id == categoryId);
        await _localDb.deleteCategory(categoryId);
        await _syncService.removeQueuedActionsForCategory(categoryId);
        notifyListeners();
        return;
      }

      await _categoryService.deleteCategory(categoryId);
      _categories.removeWhere((c) => c.id == categoryId);
      await _localDb.deleteCategory(categoryId);
      _isOfflineMode = false;
      notifyListeners();
    } catch (e) {
      if (_isNetworkError(e)) {
        _categories.removeWhere((c) => c.id == categoryId);
        await _localDb.deleteCategory(categoryId);
        await _syncService.queueCategoryAction('DELETE', null, categoryId);
        _isOfflineMode = true;
        notifyListeners();
      } else {
        _setError(e.toString());
        rethrow;
      }
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
