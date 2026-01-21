import 'package:flutter/material.dart';
import '../empty_state.dart';

class ReportEmptyState extends StatelessWidget {
  final VoidCallback? onAddTransaction;

  const ReportEmptyState({
    super.key,
    this.onAddTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.bar_chart_outlined,
      title: 'No data to display',
      subtitle: 'Add some transactions to see\nyour spending insights and reports.',
      actionText: 'Add Transaction',
      onAction: onAddTransaction,
    );
  }
}