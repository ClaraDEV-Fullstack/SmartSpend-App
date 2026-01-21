// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_setting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSetting _$UserSettingFromJson(Map<String, dynamic> json) => UserSetting(
      currency: json['currency'] as String,
      theme: json['theme'] as String,
      notificationsEnabled: json['notifications_enabled'] as bool,
      emailReports: json['email_reports'] as bool,
      defaultCategoryId: (json['default_category_id'] as num?)?.toInt(),
      defaultCategoryName: json['default_category_name'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      startOfWeek: json['start_of_week'] as String,
      dateFormat: json['date_format'] as String,
      notificationTime: json['notification_time'] as String,
      transactionNotifications: json['transaction_notifications'] as bool,
      weeklyReports: json['weekly_reports'] as bool,
      monthlyReports: json['monthly_reports'] as bool,
      biometricEnabled: json['biometric_enabled'] as bool,
      budgetAlerts: json['budget_alerts'] as bool,
      monthlyBudget: (json['monthly_budget'] as num).toDouble(),
      reportFormat: json['report_format'] as String,
    );

Map<String, dynamic> _$UserSettingToJson(UserSetting instance) =>
    <String, dynamic>{
      'currency': instance.currency,
      'theme': instance.theme,
      'notifications_enabled': instance.notificationsEnabled,
      'email_reports': instance.emailReports,
      'default_category_id': instance.defaultCategoryId,
      'default_category_name': instance.defaultCategoryName,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'start_of_week': instance.startOfWeek,
      'date_format': instance.dateFormat,
      'notification_time': instance.notificationTime,
      'transaction_notifications': instance.transactionNotifications,
      'weekly_reports': instance.weeklyReports,
      'monthly_reports': instance.monthlyReports,
      'biometric_enabled': instance.biometricEnabled,
      'budget_alerts': instance.budgetAlerts,
      'monthly_budget': instance.monthlyBudget,
      'report_format': instance.reportFormat,
    };
