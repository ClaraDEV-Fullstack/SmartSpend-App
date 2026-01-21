// lib/local/transaction_entity.dart

import 'package:hive/hive.dart';

part 'transaction_entity.g.dart'; // This will be generated

@HiveType(typeId: 1) // Unique typeId for each model
class TransactionEntity extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String type;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final int categoryId; // We'll store the ID, not the object itself

  @HiveField(6)
  final String currency;

  @HiveField(7)
  final DateTime? createdAt;

  @HiveField(8)
  final DateTime? updatedAt;

  TransactionEntity({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    required this.categoryId,
    required this.currency,
    this.createdAt,
    this.updatedAt,
  });
}