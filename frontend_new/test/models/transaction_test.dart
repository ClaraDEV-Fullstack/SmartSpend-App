import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_new/models/transaction.dart';
import 'package:frontend_new/models/category.dart';

void main() {
  group('Transaction model', () {
    final category = Category(
      id: 1,
      name: 'Food',
      icon: 'fastfood',
      color: '#FF6B6B',
      type: 'expense',
    );

    test('copyWith preserves unchanged fields', () {
      final original = Transaction(
        id: -5,
        type: 'expense',
        amount: 42.5,
        description: 'Coffee',
        date: DateTime(2026, 1, 15),
        category: category,
        currency: 'USD',
      );

      final updated = original.copyWith(description: 'Lunch');

      expect(updated.id, -5);
      expect(updated.description, 'Lunch');
      expect(updated.amount, 42.5);
      expect(updated.isPendingSync, isTrue);
    });

    test('isPendingSync is false for positive ids', () {
      final transaction = Transaction(
        id: 10,
        type: 'income',
        amount: 100,
        description: 'Salary',
        date: DateTime.now(),
        category: category,
        currency: 'USD',
      );

      expect(transaction.isPendingSync, isFalse);
    });
  });
}
