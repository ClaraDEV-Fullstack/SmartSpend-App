// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'config/routes.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';
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
import 'services/locale_service.dart';
import 'providers/ai_provider.dart';
import 'local/transaction_entity.dart';
import 'local/category_entity.dart';
import 'services/local_database_service.dart';
import 'services/sync_service.dart';
import 'services/biometric_service.dart';
import 'services/connectivity_service.dart';
import 'services/recurring_transaction_service.dart';
import 'providers/recurring_transaction_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SharedPreferences.getInstance();
  await NotificationService().initialize();

  final localeService = LocaleService();
  await localeService.initialize();

  await Hive.initFlutter();
  Hive.registerAdapter(CategoryEntityAdapter());
  Hive.registerAdapter(TransactionEntityAdapter());
  await Hive.openBox<CategoryEntity>('categories');
  await Hive.openBox<TransactionEntity>('transactions');
  await Hive.openBox('syncQueue');

  runApp(MyApp(localeService: localeService));
}

class MyApp extends StatefulWidget {
  final LocaleService localeService;

  const MyApp({super.key, required this.localeService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ConnectivityService _connectivityService = ConnectivityService();
  TransactionProvider? _transactionProvider;
  CategoryProvider? _categoryProvider;
  SyncService? _syncService;

  @override
  void initState() {
    super.initState();
    _connectivityService.initialize(onReconnect: _handleReconnect);
  }

  Future<void> _handleReconnect() async {
    await _syncService?.syncAll();
    await _transactionProvider?.fetchTransactions();
    await _categoryProvider?.fetchCategories();
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final categoryService = CategoryService();
    final transactionService = TransactionService();
    final settingsService = SettingsService();
    final reportsService = ReportsService();
    final themeService = ThemeService();
    final notificationService = NotificationService();
    final localDb = LocalDatabaseService();
    _syncService ??= SyncService(transactionService, categoryService, localDb);
    final syncService = _syncService!;
    final recurringService = RecurringTransactionService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.localeService),
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        Provider<RecurringTransactionService>(create: (_) => recurringService),
        ChangeNotifierProvider<RecurringTransactionProvider>(
          create: (_) => RecurringTransactionProvider(recurringService),
        ),
        ChangeNotifierProvider(
          create: (_) {
            _categoryProvider = CategoryProvider(
              categoryService,
              localDb,
              syncService,
            );
            return _categoryProvider!;
          },
        ),
        ChangeNotifierProvider(create: (_) => AiProvider()),
        ChangeNotifierProvider(
          create: (_) {
            _transactionProvider = TransactionProvider(
              transactionService,
              localDb,
              syncService,
              notificationService: notificationService,
            );
            return _transactionProvider!;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            settingsService,
            themeService,
            notificationService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportsProvider(reportsService),
        ),
        ChangeNotifierProvider<ThemeService>(create: (_) => themeService),
        ChangeNotifierProvider<NotificationService>(
          create: (_) => notificationService,
        ),
        ChangeNotifierProvider<BiometricService>(
          create: (_) => BiometricService(),
        ),
      ],
      child: Consumer2<ThemeService, LocaleService>(
        builder: (context, themeService, localeService, child) {
          return MaterialApp(
            title: 'SmartSpend',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            locale: localeService.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: AppRoutes.splash,
            routes: AppRoutes.getRoutes(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
