// lib/models/ai_context.dart

import 'transaction.dart';
import 'category.dart';

class AiContext {
  final List<TransactionSummary> recentTransactions;
  final List<CategorySummary> categories;
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final String currency;
  final String? userName;
  final Map<String, dynamic> reports;

  AiContext({
    required this.recentTransactions,
    required this.categories,
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.currency,
    this.userName,
    required this.reports,
  });

  Map<String, dynamic> toJson() {
    return {
      'recent_transactions': recentTransactions.map((t) => t.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'total_balance': totalBalance,
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'currency': currency,
      'user_name': userName,
      'reports': reports,
    };
  }

  factory AiContext.empty() {
    return AiContext(
      recentTransactions: [],
      categories: [],
      totalBalance: 0,
      totalIncome: 0,
      totalExpense: 0,
      currency: 'USD',
      reports: {},
    );
  }
}

class TransactionSummary {
  final int id;
  final String type;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final String currency;

  TransactionSummary({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.currency,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.toIso8601String().split('T')[0],
      'currency': currency,
    };
  }

  factory TransactionSummary.fromTransaction(Transaction t) {
    return TransactionSummary(
      id: t.id,
      type: t.type,
      amount: t.amount,
      category: t.category.name,
      description: t.description,
      date: t.date,
      currency: t.currency,
    );
  }
}

class CategorySummary {
  final int id;
  final String name;
  final String type;

  CategorySummary({
    required this.id,
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
    };
  }

  factory CategorySummary.fromCategory(Category c) {
    return CategorySummary(
      id: c.id,
      name: c.name,
      type: c.type,
    );
  }
}