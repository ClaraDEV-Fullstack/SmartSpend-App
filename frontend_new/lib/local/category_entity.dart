// lib/local/category_entity.dart

import 'package:hive/hive.dart';

part 'category_entity.g.dart';

@HiveType(typeId: 0)
class CategoryEntity extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String icon;

  @HiveField(3)
  final String color;

  // Add this missing field
  @HiveField(4) // Use the next available typeId
  final String type; // e.g., 'expense' or 'income'

  CategoryEntity({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type, // Add it to the constructor
  });
}