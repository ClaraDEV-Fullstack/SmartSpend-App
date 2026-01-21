// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportSummary _$ReportSummaryFromJson(Map<String, dynamic> json) =>
    ReportSummary(
      totalIncome: (json['total_income'] as num).toDouble(),
      totalExpense: (json['total_expense'] as num).toDouble(),
      netBalance: (json['net_balance'] as num).toDouble(),
      netStatus: json['net_status'] as String,
      categoryBreakdown: (json['category_breakdown'] as List<dynamic>)
          .map((e) => CategoryBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ReportSummaryToJson(ReportSummary instance) =>
    <String, dynamic>{
      'total_income': instance.totalIncome,
      'total_expense': instance.totalExpense,
      'net_balance': instance.netBalance,
      'net_status': instance.netStatus,
      'category_breakdown': instance.categoryBreakdown,
    };

CategoryBreakdown _$CategoryBreakdownFromJson(Map<String, dynamic> json) =>
    CategoryBreakdown(
      categoryId: (json['category_id'] as num?)?.toInt(),
      categoryName: json['category_name'] as String,
      type: json['type'] as String,
      color: json['color'] as String,
      total: (json['total'] as num).toDouble(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$CategoryBreakdownToJson(CategoryBreakdown instance) =>
    <String, dynamic>{
      'category_id': instance.categoryId,
      'category_name': instance.categoryName,
      'type': instance.type,
      'color': instance.color,
      'total': instance.total,
      'count': instance.count,
    };
