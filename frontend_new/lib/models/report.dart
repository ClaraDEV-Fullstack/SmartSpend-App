// lib/models/report.dart
import 'package:json_annotation/json_annotation.dart';

part 'report.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ReportSummary {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final String netStatus;
  final List<CategoryBreakdown> categoryBreakdown;

  ReportSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.netStatus,
    required this.categoryBreakdown,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) => _$ReportSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$ReportSummaryToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CategoryBreakdown {
  final int? categoryId;
  final String categoryName;
  final String type;
  final String color;
  final double total;
  final int count;

  CategoryBreakdown({
    this.categoryId,
    required this.categoryName,
    required this.type,
    required this.color,
    required this.total,
    required this.count,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) => _$CategoryBreakdownFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryBreakdownToJson(this);
}