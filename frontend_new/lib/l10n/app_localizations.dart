import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [
    Locale('en'),
    Locale('fr'),
  ];

  static const _en = {
    'appTitle': 'SmartSpend',
    'appTagline': 'Manage your finances with ease',
    'welcomeBack': 'Welcome Back!',
    'signInToContinue': 'Sign in to continue',
    'email': 'Email',
    'password': 'Password',
    'login': 'Login',
    'register': 'Register',
    'dontHaveAccount': "Don't have an account?",
    'continueWithGoogle': 'Continue with Google',
    'yourBalance': 'Your Balance',
    'financialSummary': 'Financial Summary',
    'income': 'Income',
    'expense': 'Expense',
    'net': 'Net',
    'topSpendingCategories': 'Top Spending Categories',
    'spendingBreakdown': 'Spending Breakdown',
    'incomeVsExpense': 'Income vs Expense',
    'recentTransactions': 'Recent Transactions',
    'quickAccess': 'Quick Access',
    'transactions': 'Transactions',
    'recurring': 'Recurring',
    'categories': 'Categories',
    'reports': 'Reports',
    'settings': 'Settings',
    'aiAssistant': 'AI Assistant',
    'language': 'Language',
    'languageSystem': 'System default',
    'languageEnglish': 'English',
    'languageFrench': 'French',
    'offlineMode': 'Offline mode',
    'retry': 'Retry',
    'cancel': 'Cancel',
    'save': 'Save',
    'delete': 'Delete',
    'refresh': 'Refresh',
    'unlockWithBiometric': 'Unlock with {biometricType}',
  };

  static const _fr = {
    'appTitle': 'SmartSpend',
    'appTagline': 'Gérez vos finances en toute simplicité',
    'welcomeBack': 'Bon retour !',
    'signInToContinue': 'Connectez-vous pour continuer',
    'email': 'E-mail',
    'password': 'Mot de passe',
    'login': 'Connexion',
    'register': 'Inscription',
    'dontHaveAccount': 'Pas encore de compte ?',
    'continueWithGoogle': 'Continuer avec Google',
    'yourBalance': 'Votre solde',
    'financialSummary': 'Résumé financier',
    'income': 'Revenus',
    'expense': 'Dépenses',
    'net': 'Net',
    'topSpendingCategories': 'Top catégories de dépenses',
    'spendingBreakdown': 'Répartition des dépenses',
    'incomeVsExpense': 'Revenus vs dépenses',
    'recentTransactions': 'Transactions récentes',
    'quickAccess': 'Accès rapide',
    'transactions': 'Transactions',
    'recurring': 'Récurrentes',
    'categories': 'Catégories',
    'reports': 'Rapports',
    'settings': 'Paramètres',
    'aiAssistant': 'Assistant IA',
    'language': 'Langue',
    'languageSystem': 'Langue du système',
    'languageEnglish': 'Anglais',
    'languageFrench': 'Français',
    'offlineMode': 'Mode hors ligne',
    'retry': 'Réessayer',
    'cancel': 'Annuler',
    'save': 'Enregistrer',
    'delete': 'Supprimer',
    'refresh': 'Actualiser',
    'unlockWithBiometric': 'Déverrouiller avec {biometricType}',
  };

  Map<String, String> get _strings =>
      locale.languageCode == 'fr' ? _fr : _en;

  String _t(String key) => _strings[key] ?? _en[key] ?? key;

  String appTitle => _t('appTitle');
  String appTagline => _t('appTagline');
  String welcomeBack => _t('welcomeBack');
  String signInToContinue => _t('signInToContinue');
  String email => _t('email');
  String password => _t('password');
  String login => _t('login');
  String register => _t('register');
  String dontHaveAccount => _t('dontHaveAccount');
  String continueWithGoogle => _t('continueWithGoogle');
  String yourBalance => _t('yourBalance');
  String financialSummary => _t('financialSummary');
  String income => _t('income');
  String expense => _t('expense');
  String net => _t('net');
  String topSpendingCategories => _t('topSpendingCategories');
  String spendingBreakdown => _t('spendingBreakdown');
  String incomeVsExpense => _t('incomeVsExpense');
  String recentTransactions => _t('recentTransactions');
  String quickAccess => _t('quickAccess');
  String transactions => _t('transactions');
  String recurring => _t('recurring');
  String categories => _t('categories');
  String reports => _t('reports');
  String settings => _t('settings');
  String aiAssistant => _t('aiAssistant');
  String language => _t('language');
  String languageSystem => _t('languageSystem');
  String languageEnglish => _t('languageEnglish');
  String languageFrench => _t('languageFrench');
  String offlineMode => _t('offlineMode');
  String retry => _t('retry');
  String cancel => _t('cancel');
  String save => _t('save');
  String delete => _t('delete');
  String refresh => _t('refresh');

  String unlockWithBiometric(String biometricType) =>
      _t('unlockWithBiometric').replaceAll('{biometricType}', biometricType);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'fr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
