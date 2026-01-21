import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';

part 'recurring_transaction.g.dart';

// Define the frequencies
enum RecurrenceFrequency { daily, weekly, monthly, yearly }

@JsonSerializable(fieldRename: FieldRename.snake)
class RecurringTransaction {
  final int id;
  final String type; // 'income' or 'expense'

  // ✅ FIX 1: Use custom parser to handle String ("1000.00") vs Double (1000.00)
  @JsonKey(fromJson: _parseAmount, toJson: _amountToJson)
  final double amount;

  final String description;
  final int categoryId;
  final String currency;

  // ✅ FIX 2: Handle case-insensitive enum parsing (e.g. "Monthly" vs "monthly")
  @JsonKey(fromJson: _frequencyFromJson, toJson: _frequencyToJson)
  final RecurrenceFrequency frequency;

  // ✅ FIX 3: Robust Date parsing (handles nulls gracefully if needed)
  @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime nextRunDate;

  @JsonKey(fromJson: _dateFromJsonNullable, toJson: _dateToJsonNullable)
  final DateTime? endDate;

  final int? executionCount;
  final int? totalExecutions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RecurringTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.categoryId,
    required this.currency,
    required this.frequency,
    required this.nextRunDate,
    this.endDate,
    this.executionCount = 0,
    this.totalExecutions,
    this.createdAt,
    this.updatedAt,
  });

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) =>
      _$RecurringTransactionFromJson(json);

  Map<String, dynamic> toJson() => _$RecurringTransactionToJson(this);

  // --- 🛠️ HELPER FUNCTIONS ---

  // 1. AMOUNT PARSER: Handles String, Int, Double, and Null
  static double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static String _amountToJson(double amount) => amount.toString();

  // 2. FREQUENCY PARSER: Handles case sensitivity
  static RecurrenceFrequency _frequencyFromJson(dynamic value) {
    if (value == null) return RecurrenceFrequency.monthly; // Default
    final String str = value.toString().toLowerCase();
    return RecurrenceFrequency.values.firstWhere(
          (e) => e.name == str,
      orElse: () => RecurrenceFrequency.monthly,
    );
  }

  static String _frequencyToJson(RecurrenceFrequency freq) => freq.name;

  // 3. DATE PARSER: Handles string format
  static DateTime _dateFromJson(String value) => DateTime.tryParse(value) ?? DateTime.now();
  static String _dateToJson(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  // 4. NULLABLE DATE PARSER
  static DateTime? _dateFromJsonNullable(String? value) {
    if (value == null) return null;
    return DateTime.tryParse(value);
  }
  static String? _dateToJsonNullable(DateTime? date) {
    if (date == null) return null;
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // --- LOGIC ---

  DateTime calculateNextRunDate() {
    DateTime nextDate = nextRunDate;
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return nextDate.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return nextDate.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly:
        return DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
      case RecurrenceFrequency.yearly:
        return DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
    }
  }

  bool get isActive {
    if (endDate != null && nextRunDate.isAfter(endDate!)) return false;
    if (totalExecutions != null && (executionCount ?? 0) >= totalExecutions!) return false;
    return true;
  }
}