// lib/providers/transaction_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../services/local_database_service.dart';
import '../services/sync_service.dart';
import '../services/notification_service.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _transactionService;
  final LocalDatabaseService _localDb;
  final SyncService _syncService;
  final NotificationService? _notificationService;

  static int _tempIdCounter = -1;

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  bool _isOfflineMode = false;

  TransactionProvider(
    this._transactionService,
    this._localDb,
    this._syncService, {
    NotificationService? notificationService,
  }) : _notificationService = notificationService;

  List<Transaction> get transactions => _transactions;
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

  Future<void> fetchTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await _transactionService.getTransactions();
      await _localDb.saveAllTransactions(_transactions);
      _isOfflineMode = false;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      try {
        _transactions = await _localDb.getAllTransactions();
        _isOfflineMode = true;
      } catch (_) {
        _transactions = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncPendingChanges() async {
    await _syncService.syncPendingActions();
    await fetchTransactions();
  }

  Future<void> addTransaction(Transaction transaction) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newTransaction = await _transactionService.createTransaction(transaction);
      _transactions.insert(0, newTransaction);
      await _localDb.saveTransaction(newTransaction);
      _isOfflineMode = false;

      await _notificationService?.showTransactionNotification(
        type: newTransaction.type,
        amount: newTransaction.amount,
        currency: newTransaction.currency,
        description: newTransaction.description,
      );
    } catch (e) {
      if (_isNetworkError(e)) {
        final offlineTransaction = transaction.copyWith(
          id: _nextTempId(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _transactions.insert(0, offlineTransaction);
        await _localDb.saveTransaction(offlineTransaction);
        await _syncService.queueAction('CREATE', offlineTransaction, null);
        _isOfflineMode = true;
      } else {
        _error = e.toString().replaceFirst('Exception: ', '');
        rethrow;
      }
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
      if (transaction.isPendingSync) {
        final updated = transaction.copyWith(updatedAt: DateTime.now());
        final index = _transactions.indexWhere((t) => t.id == transaction.id);
        if (index != -1) {
          _transactions[index] = updated;
        }
        await _localDb.saveTransaction(updated);
        await _syncService.replaceQueuedCreate(updated);
        return;
      }

      final updatedTransaction = await _transactionService.updateTransaction(transaction);
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = updatedTransaction;
      }
      await _localDb.saveTransaction(updatedTransaction);
      _isOfflineMode = false;
    } catch (e) {
      if (_isNetworkError(e)) {
        final index = _transactions.indexWhere((t) => t.id == transaction.id);
        if (index != -1) {
          _transactions[index] = transaction;
        }
        await _localDb.saveTransaction(transaction);
        await _syncService.queueAction('UPDATE', transaction, transaction.id);
        _isOfflineMode = true;
      } else {
        _error = e.toString().replaceFirst('Exception: ', '');
        rethrow;
      }
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
      if (id < 0) {
        _transactions.removeWhere((t) => t.id == id);
        await _localDb.deleteTransaction(id);
        await _syncService.removeQueuedActionsForTransaction(id);
        return;
      }

      await _transactionService.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      await _localDb.deleteTransaction(id);
      _isOfflineMode = false;
    } catch (e) {
      if (_isNetworkError(e)) {
        _transactions.removeWhere((t) => t.id == id);
        await _localDb.deleteTransaction(id);
        await _syncService.queueAction('DELETE', null, id);
        _isOfflineMode = true;
      } else {
        _error = e.toString().replaceFirst('Exception: ', '');
        rethrow;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double getMonthlyExpenses({String? currency}) {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == 'expense' &&
            t.date.month == now.month &&
            t.date.year == now.year &&
            (currency == null || t.currency == currency))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Future<void> checkBudgetAlert({
    required double monthlyBudget,
    required String currency,
  }) async {
    if (monthlyBudget <= 0 || _notificationService == null) return;

    await _notificationService!.showBudgetAlert(
      currentSpending: getMonthlyExpenses(currency: currency),
      budget: monthlyBudget,
      currency: currency,
    );
  }

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
