import 'package:flutter/material.dart';
import '../empty_state.dart';

class TransactionEmptyState extends StatelessWidget {
  final VoidCallback? onAddTransaction;

  const TransactionEmptyState({
    super.key,
    this.onAddTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'No transactions yet',
      subtitle: 'Start tracking your expenses and income\nto take control of your finances.',
      actionText: 'Add Transaction',
      onAction: onAddTransaction,
    );
  }
}