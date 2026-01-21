// lib/models/transaction.dart

import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';
import 'category.dart';

part 'transaction.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Transaction {
  final int id;
  final String type;

  @JsonKey(fromJson: _parseAmount)
  final double amount;

  final String description;

  @JsonKey(fromJson: _parseDate)
  final DateTime date;

  @JsonKey(fromJson: _categoryFromJson)
  final Category category;

  final String currency;

  // Optional fields
  final bool? isRecurring;
  final String? recurrence;

  @JsonKey(fromJson: _parseDateNullable)
  final DateTime? nextRunDate;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    required this.category,
    required this.currency,
    this.isRecurring,
    this.recurrence,
    this.nextRunDate,
    this.createdAt,
    this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  // NOTE: This toJson is for display/debug purposes only
  // The actual API request body is created in TransactionService
  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  // --- PARSING HELPERS ---

  static double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _parseDateNullable(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static Category _categoryFromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return Category.fromJson(json);
    }
    return Category(
      id: json is int ? json : 0,
      name: 'Unknown',
      icon: 'help_outline',
      color: '#9E9E9E',
      type: 'expense',
    );
  }
}