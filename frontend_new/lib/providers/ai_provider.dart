// lib/providers/ai_provider.dart

import 'package:flutter/material.dart';
import '../models/ai_message.dart';
import '../models/ai_action.dart';
import '../models/ai_context.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/ai_service.dart';
import 'transaction_provider.dart';
import 'category_provider.dart';
import 'settings_provider.dart';
import 'auth_provider.dart';

class AiProvider with ChangeNotifier {
  final AiService _aiService = AiService();

  // Dependencies
  TransactionProvider? _transactionProvider;
  CategoryProvider? _categoryProvider;
  SettingsProvider? _settingsProvider;
  AuthProvider? _authProvider;

  // State
  final List<AiMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  AiAction? _pendingAction;

  // Getters
  List<AiMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;
  AiAction? get pendingAction => _pendingAction;
  bool get hasPendingAction => _pendingAction != null;

  /// Inject dependencies
  void setProviders({
    required TransactionProvider transactionProvider,
    required CategoryProvider categoryProvider,
    required SettingsProvider settingsProvider,
    required AuthProvider authProvider,
  }) {
    _transactionProvider = transactionProvider;
    _categoryProvider = categoryProvider;
    _settingsProvider = settingsProvider;
    _authProvider = authProvider;
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Build context from current app state
  // lib/providers/ai_provider.dart

  AiContext _buildContext() {
    if (_transactionProvider == null || _categoryProvider == null) {
      return AiContext.empty();
    }

    final transactions = _transactionProvider!.transactions;
    final categories = _categoryProvider!.categories;
    final settings = _settingsProvider?.settings;
    final user = _authProvider?.user;

    // Get last 50 transactions
    final recentTransactions = transactions
        .take(50)
        .map((t) => TransactionSummary.fromTransaction(t))
        .toList();

    final categorySummaries = categories
        .map((c) => CategorySummary.fromCategory(c))
        .toList();

    final totalIncome = _transactionProvider!.getTotalIncome();
    final totalExpense = _transactionProvider!.getTotalExpense();

    // Build reports data
    final reports = _buildReportsData();

    return AiContext(
      recentTransactions: recentTransactions,
      categories: categorySummaries,
      totalBalance: totalIncome - totalExpense,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      currency: settings?.currency ?? 'USD',
      userName: user?.firstName ?? user?.username,
      reports: reports,
    );
  }

  Map<String, dynamic> _buildReportsData() {
    if (_transactionProvider == null) {
      return {};
    }

    final transactions = _transactionProvider!.transactions;
    final now = DateTime.now();

    // Calculate averages
    final days = 30;
    final startDate = now.subtract(Duration(days: days));

    double dailyTotal = 0;
    int dailyCount = 0;

    for (final t in transactions) {
      if (t.type == 'expense' && t.date.isAfter(startDate)) {
        dailyTotal += t.amount;
        dailyCount++;
      }
    }

    final dailyAvg = dailyCount > 0 ? dailyTotal / days : 0;
    final weeklyAvg = dailyAvg * 7;
    final monthlyAvg = dailyAvg * 30;

    // Savings rate
    final income = _transactionProvider!.getTotalIncome();
    final expense = _transactionProvider!.getTotalExpense();
    final savingsRate = income > 0 ? ((income - expense) / income * 100) : 0;

    // Biggest category
    final categoryTotals = <String, double>{};
    for (final t in transactions) {
      if (t.type == 'expense') {
        final cat = t.category.name;
        categoryTotals[cat] = (categoryTotals[cat] ?? 0) + t.amount;
      }
    }

    final biggestCategory = categoryTotals.isNotEmpty
        ? categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'N/A';

    return {
      'daily_average': dailyAvg,
      'weekly_average': weeklyAvg,
      'monthly_average': monthlyAvg,
      'savings_rate': savingsRate,
      'biggest_category': biggestCategory,
    };
  }

  /// Send a message to the AI
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message
    final userMessage = AiMessage.user(message);
    _messages.add(userMessage);
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final context = _buildContext();
      final response = await _aiService.sendMessage(message, context);

      // Update user message status
      final index = _messages.indexWhere((m) => m.id == userMessage.id);
      if (index != -1) {
        _messages[index] = userMessage.copyWith(status: MessageStatus.sent);
      }

      // Add AI response
      _messages.add(response);

      // Check for pending action
      if (response.action != null && response.action!.requiresConfirmation) {
        _pendingAction = response.action;
      } else if (response.action != null) {
        await _executeAction(response.action!);
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');

      final index = _messages.indexWhere((m) => m.id == userMessage.id);
      if (index != -1) {
        _messages[index] = userMessage.copyWith(status: MessageStatus.error);
      }

      _messages.add(AiMessage.assistant(
        'Sorry, I encountered an error. Please try again.',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Confirm pending action
  Future<bool> confirmAction() async {
    if (_pendingAction == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      final success = await _executeAction(_pendingAction!);

      if (success) {
        _pendingAction = _pendingAction!.copyWith(status: AiActionStatus.executed);
        _messages.add(AiMessage.assistant('✅ Done! Transaction added successfully.'));
      }

      _pendingAction = null;
      return success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _messages.add(AiMessage.assistant('❌ Failed: $_error'));
      _pendingAction = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cancel pending action
  void cancelAction() {
    if (_pendingAction != null) {
      _pendingAction = _pendingAction!.copyWith(status: AiActionStatus.cancelled);
      _messages.add(AiMessage.assistant('Action cancelled.'));
      _pendingAction = null;
      notifyListeners();
    }
  }

  /// Execute an AI action
  Future<bool> _executeAction(AiAction action) async {
    switch (action.type) {
      case AiActionType.addTransaction:
        return await _executeAddTransaction(action);

      case AiActionType.showSummary:
      case AiActionType.showCategory:
      case AiActionType.showTransactions:
      case AiActionType.informational:
        return true;

      default:
        print('Unknown action type: ${action.type}');
        return false;
    }
  }

  /// Execute add transaction action
  Future<bool> _executeAddTransaction(AiAction action) async {
    if (_transactionProvider == null || _categoryProvider == null) {
      throw Exception('Providers not initialized');
    }

    final categoryName = action.categoryName;
    final amount = action.amount;
    final type = action.transactionType;

    if (amount == null || type == null) {
      throw Exception('Invalid transaction data');
    }

    // Find category
    Category? category;

    // Try by ID first
    if (action.categoryId != null) {
      try {
        category = _categoryProvider!.categories.firstWhere(
              (c) => c.id == action.categoryId,
        );
      } catch (_) {}
    }

    // Try by name
    if (category == null && categoryName != null) {
      try {
        category = _categoryProvider!.categories.firstWhere(
              (c) => c.name.toLowerCase() == categoryName.toLowerCase(),
        );
      } catch (_) {}
    }

    // Try by type
    if (category == null) {
      try {
        category = _categoryProvider!.categories.firstWhere(
              (c) => c.type == type,
        );
      } catch (_) {}
    }

    // Use first available
    if (category == null && _categoryProvider!.categories.isNotEmpty) {
      category = _categoryProvider!.categories.first;
    }

    if (category == null) {
      throw Exception('No category available');
    }

    // Create transaction object
    final transaction = Transaction(
      id: 0,
      type: type,
      amount: amount,
      description: action.transactionDescription ?? 'Added via AI',
      date: action.date ?? DateTime.now(),
      category: category,
      currency: action.currency ?? _settingsProvider?.settings?.currency ?? 'USD',
    );

    // ✅ FIXED: Using correct method name 'addTransaction'
    await _transactionProvider!.addTransaction(transaction);

    return true;
  }

  /// Clear conversation
  void clearConversation() {
    _messages.clear();
    _pendingAction = null;
    _error = null;
    notifyListeners();
  }

  /// Get suggestions
  List<String> getSuggestions() {
    return [
      "Add 50 for lunch",
      "What's my balance?",
      "Spending this week?",
      "Show categories",
      "Give me tips",
    ];
  }
}