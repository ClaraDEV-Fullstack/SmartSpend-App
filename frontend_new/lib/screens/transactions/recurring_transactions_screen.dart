import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/recurring_transaction.dart';
import '../../providers/recurring_transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../theme/app_theme.dart';
import 'recurring_transaction_form_screen.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
      context.read<RecurringTransactionProvider>().fetchRecurringTransactions();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<CategoryProvider>().fetchCategories(),
      context.read<RecurringTransactionProvider>().fetchRecurringTransactions(),
    ]);
  }

  Future<void> _openForm({RecurringTransaction? item}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecurringTransactionFormScreen(
          recurringTransaction: item,
        ),
      ),
    );
    if (result == true) _refresh();
  }

  String _categoryName(int categoryId, CategoryProvider categoryProvider) {
    try {
      return categoryProvider.categories
          .firstWhere((c) => c.id == categoryId)
          .name;
    } catch (_) {
      return 'Category #$categoryId';
    }
  }

  Future<void> _confirmDelete(RecurringTransaction item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete recurring transaction?'),
        content: Text(
          'Stop repeating "${item.description}"? This will not delete past transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context
          .read<RecurringTransactionProvider>()
          .deleteRecurringTransaction(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recurring transaction deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('New'),
        backgroundColor: AppTheme.primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<RecurringTransactionProvider, CategoryProvider>(
        builder: (context, provider, categoryProvider, _) {
          if (provider.isLoading && provider.recurringTransactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.recurringTransactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            );
          }

          if (provider.recurringTransactions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.repeat,
                      size: 64,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No recurring transactions yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create one manually or enable "Repeat Transaction" when adding a transaction.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: provider.recurringTransactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = provider.recurringTransactions[index];
                final isExpense = item.type == 'expense';
                final color = isExpense ? Colors.red : Colors.green;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openForm(item: item),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withOpacity(0.15),
                            child: Icon(
                              isExpense
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.currency} ${item.amount.toStringAsFixed(2)} • ${item.frequency.name}',
                                ),
                                Text(
                                  'Next: ${DateFormat.yMMMd().format(item.nextRunDate)}',
                                ),
                                Text(
                                  _categoryName(item.categoryId, categoryProvider),
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                                if (!item.isActive)
                                  const Text(
                                    'Inactive',
                                    style: TextStyle(color: Colors.orange),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _openForm(item: item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _confirmDelete(item),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
