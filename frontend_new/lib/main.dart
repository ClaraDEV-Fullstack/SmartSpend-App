// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
// Your existing imports
import 'config/routes.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'providers/auth_provider.dart';
import 'services/category_service.dart';
import 'providers/category_provider.dart';
import 'services/transaction_service.dart';
import 'providers/transaction_provider.dart';
import 'services/settings_service.dart';
import 'providers/settings_provider.dart';
import 'services/reports_service.dart';
import 'providers/reports_provider.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'providers/ai_provider.dart';

// Offline support imports
import 'local/transaction_entity.dart';
import 'local/category_entity.dart';
import 'services/local_database_service.dart';
import 'services/sync_service.dart';
import 'services/biometric_service.dart';
// Recurring transaction imports
import 'services/recurring_transaction_service.dart';
import 'providers/recurring_transaction_provider.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  await SharedPreferences.getInstance();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(CategoryEntityAdapter());
  Hive.registerAdapter(TransactionEntityAdapter());
  await Hive.openBox<CategoryEntity>('categories');
  await Hive.openBox<TransactionEntity>('transactions');
  await Hive.openBox('syncQueue');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ===== INITIALIZE SERVICES =====
    final authService = AuthService();
    final categoryService = CategoryService();
    final transactionService = TransactionService();
    final settingsService = SettingsService();
    final reportsService = ReportsService();
    final themeService = ThemeService();
    final notificationService = NotificationService();

    final localDb = LocalDatabaseService();
    final syncService = SyncService(transactionService, localDb);
    // ===============================

    // 1. Create the recurring service using authService
    final recurringService = RecurringTransactionService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),

        // 2. Provide the service directly (simplest way)
        Provider<RecurringTransactionService>(
          create: (_) => recurringService,
        ),

        // 3. Provide the Provider which uses the service
        ChangeNotifierProvider<RecurringTransactionProvider>(
          create: (_) => RecurringTransactionProvider(recurringService),
        ),

        ChangeNotifierProvider(
          create: (_) => CategoryProvider(categoryService),
        ),

        ChangeNotifierProvider(create: (_) => AiProvider()),

        ChangeNotifierProvider(
          create: (_) => TransactionProvider(transactionService, localDb, syncService),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(settingsService, themeService, notificationService),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportsProvider(reportsService),
        ),
        ChangeNotifierProvider<ThemeService>(
          create: (_) => themeService,
        ),
        ChangeNotifierProvider<NotificationService>(
          create: (_) => notificationService,
        ),

        ChangeNotifierProvider<BiometricService>(
          create: (_) => BiometricService(),
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Expense Tracker',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            initialRoute: AppRoutes.login,
            routes: AppRoutes.getRoutes(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}