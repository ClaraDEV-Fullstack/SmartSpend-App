// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecurringTransaction _$RecurringTransactionFromJson(
        Map<String, dynamic> json) =>
    RecurringTransaction(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String,
      amount: RecurringTransaction._parseAmount(json['amount']),
      description: json['description'] as String,
      categoryId: (json['category_id'] as num).toInt(),
      currency: json['currency'] as String,
      frequency: RecurringTransaction._frequencyFromJson(json['frequency']),
      nextRunDate:
          RecurringTransaction._dateFromJson(json['next_run_date'] as String),
      endDate: RecurringTransaction._dateFromJsonNullable(
          json['end_date'] as String?),
      executionCount: (json['execution_count'] as num?)?.toInt() ?? 0,
      totalExecutions: (json['total_executions'] as num?)?.toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$RecurringTransactionToJson(
        RecurringTransaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'amount': RecurringTransaction._amountToJson(instance.amount),
      'description': instance.description,
      'category_id': instance.categoryId,
      'currency': instance.currency,
      'frequency': RecurringTransaction._frequencyToJson(instance.frequency),
      'next_run_date': RecurringTransaction._dateToJson(instance.nextRunDate),
      'end_date': RecurringTransaction._dateToJsonNullable(instance.endDate),
      'execution_count': instance.executionCount,
      'total_executions': instance.totalExecutions,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
