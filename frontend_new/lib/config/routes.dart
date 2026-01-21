// lib/core/config/routes.dart
import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/categories/categories_screen.dart';
import '../screens/categories/category_form_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/transactions/transaction_form_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/reports/reports_screen.dart';

class AppRoutes {
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

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => LoginScreen(),
      register: (context) => RegisterScreen(),
      dashboard: (context) => DashboardScreen(),
      profile: (context) => ProfileScreen(),
      categories: (context) => CategoriesScreen(),
      categoryForm: (context) => CategoryFormScreen(),
      transactions: (context) => TransactionsScreen(),
      transactionForm: (context) => TransactionFormScreen(),
      settings: (context) => SettingsScreen(),
      reports: (context) => ReportsScreen(),
    };
  }
}