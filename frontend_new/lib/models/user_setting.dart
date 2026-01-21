// lib/models/user_setting.dart
import 'package:json_annotation/json_annotation.dart';

part 'user_setting.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserSetting {
  final String currency;
  final String theme;
  final bool notificationsEnabled;
  final bool emailReports;
  final int? defaultCategoryId;
  final String? defaultCategoryName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // New fields from backend
  final String startOfWeek;
  final String dateFormat;
  final String notificationTime;
  final bool transactionNotifications;
  final bool weeklyReports;
  final bool monthlyReports;
  final bool biometricEnabled;
  final bool budgetAlerts;
  final double monthlyBudget;
  final String reportFormat;

  UserSetting({
    required this.currency,
    required this.theme,
    required this.notificationsEnabled,
    required this.emailReports,
    this.defaultCategoryId,
    this.defaultCategoryName,
    this.createdAt,
    this.updatedAt,
    // New fields
    required this.startOfWeek,
    required this.dateFormat,
    required this.notificationTime,
    required this.transactionNotifications,
    required this.weeklyReports,
    required this.monthlyReports,
    required this.biometricEnabled,
    required this.budgetAlerts,
    required this.monthlyBudget,
    required this.reportFormat,
  });

  factory UserSetting.fromJson(Map<String, dynamic> json) {
    // Handle potential type conversion issues
    return UserSetting(
      currency: json['currency'] ?? 'USD',
      theme: json['theme'] ?? 'system',
      notificationsEnabled: json['notifications_enabled'] ?? true,
      emailReports: json['email_reports'] ?? false,
      defaultCategoryId: json['default_category_id'],
      defaultCategoryName: json['default_category_name'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      startOfWeek: json['start_of_week'] ?? 'Sunday',
      dateFormat: json['date_format'] ?? 'MM/DD/YYYY',
      notificationTime: json['notification_time'] ?? '09:00',
      transactionNotifications: json['transaction_notifications'] ?? true,
      weeklyReports: json['weekly_reports'] ?? true,
      monthlyReports: json['monthly_reports'] ?? true,
      biometricEnabled: json['biometric_enabled'] ?? false,
      budgetAlerts: json['budget_alerts'] ?? true,
      monthlyBudget: json['monthly_budget'] is String
          ? double.tryParse(json['monthly_budget']) ?? 1000.0
          : (json['monthly_budget']?.toDouble() ?? 1000.0),
      reportFormat: json['report_format'] ?? 'PDF',
    );
  }

  Map<String, dynamic> toJson() => _$UserSettingToJson(this);
}