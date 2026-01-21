import 'package:flutter/material.dart';
import '../empty_state.dart';

class DashboardEmptyState extends StatelessWidget {
  final VoidCallback? onAddTransaction;

  const DashboardEmptyState({
    super.key,
    this.onAddTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Welcome to ExpenseTracker!',
      subtitle: 'Add your first transaction to start\ntracking your financial journey.',
      actionText: 'Add First Transaction',
      onAction: onAddTransaction,
    );
  }
}