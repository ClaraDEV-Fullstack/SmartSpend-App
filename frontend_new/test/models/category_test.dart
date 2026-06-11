import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_new/models/category.dart';

void main() {
  group('Category model', () {
    test('copyWith preserves unchanged fields', () {
      final original = Category(
        id: -3,
        name: 'Transport',
        type: 'expense',
        color: '#4ECDC4',
        icon: 'directions_car',
      );

      final updated = original.copyWith(name: 'Travel');

      expect(updated.id, -3);
      expect(updated.name, 'Travel');
      expect(updated.type, 'expense');
      expect(updated.isPendingSync, isTrue);
    });

    test('isPendingSync is false for positive ids', () {
      final category = Category(
        id: 5,
        name: 'Salary',
        type: 'income',
        color: '#95E1D3',
        icon: 'payments',
      );

      expect(category.isPendingSync, isFalse);
    });
  });
}
