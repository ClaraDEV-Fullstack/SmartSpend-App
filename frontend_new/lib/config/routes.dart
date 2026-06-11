// lib/core/config/routes.dart
import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/categories/categories_screen.dart';
import '../screens/categories/category_form_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/transactions/transaction_form_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/transactions/recurring_transactions_screen.dart';
import '../screens/transactions/recurring_transaction_form_screen.dart';
import '../screens/ai/ai_assistant_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String categories = '/categories';
  static const String categoryForm = '/category-form';
  static const String transactions = '/transactions';
  static const String transactionForm = '/transaction-form';
  static const String settings = '/settings';
  static const String reports = '/reports';
  static const String recurringTransactions = '/recurring-transactions';
  static const String recurringTransactionForm = '/recurring-transaction-form';
  static const String aiAssistant = '/ai-assistant';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      dashboard: (context) => const DashboardScreen(),
      profile: (context) => const ProfileScreen(),
      categories: (context) => const CategoriesScreen(),
      categoryForm: (context) => const CategoryFormScreen(),
      transactions: (context) => const TransactionsScreen(),
      transactionForm: (context) => const TransactionFormScreen(),
      settings: (context) => const SettingsScreen(),
      reports: (context) => const ReportsScreen(),
      recurringTransactions: (context) => const RecurringTransactionsScreen(),
      recurringTransactionForm: (context) => const RecurringTransactionFormScreen(),
      aiAssistant: (context) => const AiAssistantScreen(),
    };
  }
}