// lib/services/notification_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Only import these on non-web platforms
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
if (dart.library.html) 'notification_stub.dart';

class NotificationService with ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FlutterLocalNotificationsPlugin? _notifications;

  bool _isInitialized = false;
  bool _notificationsEnabled = true;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);
  bool _transactionNotifications = true;
  bool _budgetAlerts = true;
  bool _weeklyReports = true;
  bool _monthlyReports = true;

  bool get notificationsEnabled => _notificationsEnabled;
  TimeOfDay get notificationTime => _notificationTime;
  bool get transactionNotifications => _transactionNotifications;
  bool get budgetAlerts => _budgetAlerts;
  bool get weeklyReports => _weeklyReports;
  bool get monthlyReports => _monthlyReports;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Skip initialization on web
    if (kIsWeb) {
      _isInitialized = true;
      debugPrint('NotificationService: Web platform - notifications limited');
      return;
    }

    _notifications = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications?.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    final android = _notifications?.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iOS = _notifications?.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    if (iOS != null) {
      final granted = await iOS.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  /// Show an immediate notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    if (!_notificationsEnabled) return;

    // On web, just log the notification
    if (kIsWeb) {
      debugPrint('📱 Notification (Web): $title - $body');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'smartspend_channel',
      'SmartSpend Notifications',
      channelDescription: 'Notifications for SmartSpend app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications?.show(id, title, body, details, payload: payload);
    debugPrint('Notification shown: $title');
  }

  /// Show transaction notification
  Future<void> showTransactionNotification({
    required String type,
    required double amount,
    required String currency,
    required String description,
  }) async {
    if (!_transactionNotifications) return;

    final title = type == 'income' ? '💰 Income Added' : '💸 Expense Recorded';
    final body = '$description: $currency ${amount.toStringAsFixed(2)}';

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: 'transaction',
    );
  }

  /// Show budget alert notification
  Future<void> showBudgetAlert({
    required double currentSpending,
    required double budget,
    required String currency,
  }) async {
    if (!_budgetAlerts) return;

    final percentage = (currentSpending / budget * 100).toInt();
    String title;
    String body;

    if (percentage >= 100) {
      title = '🚨 Budget Exceeded!';
      body = 'You\'ve spent $currency ${currentSpending.toStringAsFixed(2)} of your $currency ${budget.toStringAsFixed(2)} budget.';
    } else if (percentage >= 90) {
      title = '⚠️ Budget Warning';
      body = 'You\'ve used $percentage% of your monthly budget.';
    } else if (percentage >= 75) {
      title = '📊 Budget Update';
      body = 'You\'ve used $percentage% of your monthly budget.';
    } else {
      return;
    }

    await showNotification(
      id: 1001,
      title: title,
      body: body,
      payload: 'budget',
    );
  }

  /// Schedule daily reminder notification
  Future<void> scheduleDailyReminder() async {
    if (!_notificationsEnabled || kIsWeb) return;

    await _notifications?.cancelAll();

    // Note: For proper scheduling, you'd need timezone package
    // This is a simplified version
    debugPrint('Daily reminder scheduled for ${_notificationTime.hour}:${_notificationTime.minute}');
  }

  /// Set notification time
  void setNotificationTime(TimeOfDay time) {
    _notificationTime = time;
    scheduleDailyReminder();
    notifyListeners();
  }

  /// Enable/disable notifications
  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    if (enabled) {
      scheduleDailyReminder();
    } else if (!kIsWeb) {
      _notifications?.cancelAll();
    }
    notifyListeners();
  }

  /// Set transaction notifications
  void setTransactionNotifications(bool enabled) {
    _transactionNotifications = enabled;
    notifyListeners();
  }

  /// Set budget alerts
  void setBudgetAlerts(bool enabled) {
    _budgetAlerts = enabled;
    notifyListeners();
  }

  /// Set weekly reports
  void setWeeklyReports(bool enabled) {
    _weeklyReports = enabled;
    notifyListeners();
  }

  /// Set monthly reports
  void setMonthlyReports(bool enabled) {
    _monthlyReports = enabled;
    notifyListeners();
  }

  /// Send a test notification
  Future<void> sendTestNotification() async {
    await showNotification(
      id: 9999,
      title: '🔔 Test Notification',
      body: 'Notifications are working correctly!',
      payload: 'test',
    );
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!kIsWeb) {
      await _notifications?.cancelAll();
    }
  }
}