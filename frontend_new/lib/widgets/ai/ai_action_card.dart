// lib/widgets/ai/ai_action_card.dart

import 'package:flutter/material.dart';
import '../../models/ai_action.dart';

class AiActionCard extends StatelessWidget {
  final AiAction action;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isLoading;

  const AiActionCard({
    super.key,
    required this.action,
    required this.onConfirm,
    required this.onCancel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getActionColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getActionIcon(),
                    color: _getActionColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getActionTitle(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Confirm this action?',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Action Details
            _buildActionDetails(),

            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getActionColor(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Confirm',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionDetails() {
    switch (action.type) {
      case AiActionType.addTransaction:
        return _buildTransactionDetails();
      default:
        return Text(action.description);
    }
  }

  Widget _buildTransactionDetails() {
    final isExpense = action.transactionType == 'expense';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            'Type',
            action.transactionType?.toUpperCase() ?? 'N/A',
            color: isExpense ? Colors.red : Colors.green,
          ),
          _buildDetailRow(
            'Amount',
            '${action.currency ?? 'USD'} ${action.amount?.toStringAsFixed(2) ?? '0.00'}',
          ),
          _buildDetailRow(
            'Category',
            action.categoryName ?? 'Auto-detect',
          ),
          _buildDetailRow(
            'Description',
            action.description ?? 'N/A',
          ),
          _buildDetailRow(
            'Date',
            _formatDate(action.date ?? DateTime.now()),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getActionIcon() {
    switch (action.type) {
      case AiActionType.addTransaction:
        return action.transactionType == 'expense'
            ? Icons.remove_circle_outline
            : Icons.add_circle_outline;
      case AiActionType.showSummary:
        return Icons.analytics;
      case AiActionType.showCategory:
        return Icons.category;
      default:
        return Icons.smart_toy;
    }
  }

  Color _getActionColor() {
    switch (action.type) {
      case AiActionType.addTransaction:
        return action.transactionType == 'expense'
            ? Colors.red
            : Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _getActionTitle() {
    switch (action.type) {
      case AiActionType.addTransaction:
        return 'Add ${action.transactionType ?? 'Transaction'}';
      case AiActionType.showSummary:
        return 'View Summary';
      case AiActionType.showCategory:
        return 'View Category';
      default:
        return 'Action';
    }
  }
}