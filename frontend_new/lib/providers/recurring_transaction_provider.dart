// lib/providers/recurring_transaction_provider.dart

import 'package:flutter/material.dart';
import '../models/recurring_transaction.dart';
import '../services/recurring_transaction_service.dart';

class RecurringTransactionProvider with ChangeNotifier {
  final RecurringTransactionService _service;

  RecurringTransactionProvider(this._service);

  List<RecurringTransaction> _recurringTransactions = [];
  bool _isLoading = false;
  String? _error;

  List<RecurringTransaction> get recurringTransactions => _recurringTransactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> fetchRecurringTransactions() async {
    _setLoading(true);
    _error = null;
    try {
      _recurringTransactions = await _service.getRecurringTransactions();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<RecurringTransaction> addRecurringTransaction(RecurringTransaction transaction) async {
    _setLoading(true);
    _error = null;
    try {
      final newTransaction = await _service.createRecurringTransaction(transaction);
      _recurringTransactions.add(newTransaction);
      notifyListeners();
      return newTransaction;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<RecurringTransaction> updateRecurringTransaction(RecurringTransaction transaction) async {
    _setLoading(true);
    _error = null;
    try {
      final updatedTransaction = await _service.updateRecurringTransaction(transaction);
      final index = _recurringTransactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _recurringTransactions[index] = updatedTransaction;
        notifyListeners();
      }
      return updatedTransaction;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteRecurringTransaction(int id) async {
    _setLoading(true);
    _error = null;
    try {
      await _service.deleteRecurringTransaction(id);
      _recurringTransactions.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
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