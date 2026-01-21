// lib/providers/transaction_provider.dart

import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../services/local_database_service.dart';
import '../services/sync_service.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _transactionService;
  final LocalDatabaseService _localDb;
  final SyncService _syncService;

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  TransactionProvider(this._transactionService, this._localDb, this._syncService);

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> fetchTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await _transactionService.getTransactions();
      // Save to local database for offline access
      await _localDb.saveAllTransactions(_transactions);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      // Try to load from local database
      try {
        _transactions = await _localDb.getAllTransactions();
      } catch (_) {
        _transactions = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newTransaction = await _transactionService.createTransaction(transaction);
      _transactions.insert(0, newTransaction);
      await _localDb.saveTransaction(newTransaction);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedTransaction = await _transactionService.updateTransaction(transaction);
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = updatedTransaction;
      }
      await _localDb.saveTransaction(updatedTransaction);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _transactionService.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      await _localDb.deleteTransaction(id);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper methods
  List<Transaction> getIncomeTransactions() {
    return _transactions.where((t) => t.type == 'income').toList();
  }

  List<Transaction> getExpenseTransactions() {
    return _transactions.where((t) => t.type == 'expense').toList();
  }

  double getTotalIncome() {
    return getIncomeTransactions().fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalExpense() {
    return getExpenseTransactions().fold(0.0, (sum, t) => sum + t.amount);
  }

  double getBalance() {
    return getTotalIncome() - getTotalExpense();
  }
}