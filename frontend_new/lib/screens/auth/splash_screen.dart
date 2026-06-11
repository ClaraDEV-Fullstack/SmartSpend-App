import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/biometric_service.dart';
import '../../theme/app_theme.dart';
import '../../config/routes.dart';

/// Checks stored session and routes to dashboard or login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final authProvider = context.read<AuthProvider>();
    final biometricService = context.read<BiometricService>();

    await biometricService.initialize();

    final hasSession = await authProvider.hasStoredSession();
    if (!hasSession) {
      _goToLogin();
      return;
    }

    if (biometricService.shouldUseBiometric()) {
      final authenticated = await biometricService.authenticate(
        reason: 'Unlock SmartSpend',
      );
      if (!authenticated) {
        _goToLogin();
        return;
      }
    }

    await authProvider.restoreSession();

    if (!mounted) return;

    if (authProvider.isLoggedIn) {
      await context.read<TransactionProvider>().syncPendingChanges();
      await context.read<CategoryProvider>().syncPendingChanges();
      await context.read<SettingsProvider>().fetchSettings();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.purpleGoldGradientDark
              : AppTheme.purpleGoldGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)?.appTitle ?? 'SmartSpend',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
