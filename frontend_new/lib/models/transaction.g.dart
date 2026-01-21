// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String,
      amount: Transaction._parseAmount(json['amount']),
      description: json['description'] as String,
      date: Transaction._parseDate(json['date']),
      category: Transaction._categoryFromJson(json['category']),
      currency: json['currency'] as String,
      isRecurring: json['is_recurring'] as bool?,
      recurrence: json['recurrence'] as String?,
      nextRunDate: Transaction._parseDateNullable(json['next_run_date']),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'amount': instance.amount,
      'description': instance.description,
      'date': instance.date.toIso8601String(),
      'category': instance.category,
      'currency': instance.currency,
      'is_recurring': instance.isRecurring,
      'recurrence': instance.recurrence,
      'next_run_date': instance.nextRunDate?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
