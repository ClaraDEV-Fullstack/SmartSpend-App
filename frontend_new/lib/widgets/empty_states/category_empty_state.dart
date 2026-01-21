import 'package:flutter/material.dart';
import '../empty_state.dart';

class CategoryEmptyState extends StatelessWidget {
  final VoidCallback? onAddCategory;

  const CategoryEmptyState({
    super.key,
    this.onAddCategory,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.category_outlined,
      title: 'No categories yet',
      subtitle: 'Create categories to organize\nyour transactions better.',
      actionText: 'Add Category',
      onAction: onAddCategory,
    );
  }
}