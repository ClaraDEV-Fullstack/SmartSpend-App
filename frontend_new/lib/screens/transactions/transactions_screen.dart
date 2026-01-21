// lib/screens/transactions/transactions_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../widgets/empty_states/empty_states.dart';
import '../../services/export_service.dart';
import '../../widgets/export/export_feedback_dialog.dart';
import 'transaction_form_screen.dart';
import '../../search/transaction_search_delegate.dart';
import '../../theme/app_theme.dart';

// Conditional import for web-specific export
import '../../services/export_service_web.dart' if (dart.library.io) '../../services/export_service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

      transactionProvider.fetchTransactions();
      if (categoryProvider.categories.isEmpty) {
        categoryProvider.fetchCategories();
      }
    });
  }

  void _navigateToAddTransaction() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TransactionFormScreen(),
      ),
    );
  }

  void _exportData() {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    if (transactionProvider.transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No transactions to export'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Show export options dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.file_download,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Export Transactions'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildExportOption(
              context,
              icon: Icons.table_chart,
              iconColor: Colors.green,
              title: 'Export as CSV',
              subtitle: 'For Excel, Google Sheets',
              onTap: () {
                Navigator.pop(context);
                _performExportWithFeedback('csv', transactionProvider.transactions, categoryProvider.categories);
              },
            ),
            const SizedBox(height: 8),
            _buildExportOption(
              context,
              icon: Icons.picture_as_pdf,
              iconColor: Colors.red,
              title: 'Export as PDF',
              subtitle: 'Printable report',
              onTap: () {
                Navigator.pop(context);
                _performExportWithFeedback('pdf', transactionProvider.transactions, categoryProvider.categories);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _performExportWithFeedback(
      String format,
      List<Transaction> transactions,
      List<Category> categories,
      ) {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ExportFeedbackDialog(
        isExporting: true,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );

    // Perform export
    _performExport(format, transactions, categories).then((path) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ExportFeedbackDialog(
          isExporting: false,
          isSuccess: true,
          filePath: path,
          onDismiss: () => Navigator.of(context).pop(),
        ),
      );
    }).catchError((e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ExportFeedbackDialog(
          isExporting: false,
          isSuccess: false,
          error: e.toString(),
          onDismiss: () => Navigator.of(context).pop(),
        ),
      );
    });
  }

  Future<String?> _performExport(
      String format,
      List<Transaction> transactions,
      List<Category> categories,
      ) async {
    try {
      if (format == 'csv') {
        final path = await ExportService.exportToCSV(transactions);
        return path;
      } else {
        final path = await ExportService.exportToPDF(transactions);
        return path;
      }
    } catch (e) {
      debugPrint('Export error: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          // Export button
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportData,
            tooltip: 'Export Transactions',
          ),

          // Search button
          Consumer<TransactionProvider>(
            builder: (context, transactionProvider, child) {
              return IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: TransactionSearchDelegate(transactionProvider.transactions),
                  );
                },
                tooltip: 'Search Transactions',
              );
            },
          ),

          // Add transaction button
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddTransaction,
            tooltip: 'Add Transaction',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          Consumer<TransactionProvider>(
            builder: (context, transactionProvider, child) {
              if (transactionProvider.transactions.isEmpty) {
                return const SizedBox.shrink();
              }

              final currencies = transactionProvider.transactions
                  .map((t) => t.currency)
                  .toSet()
                  .toList();

              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Income',
                        amount: transactionProvider.getTotalIncome(),
                        currencies: currencies,
                        transactionProvider: transactionProvider,
                        isIncome: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Expense',
                        amount: transactionProvider.getTotalExpense(),
                        currencies: currencies,
                        transactionProvider: transactionProvider,
                        isIncome: false,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Balance Card
          Consumer<TransactionProvider>(
            builder: (context, transactionProvider, child) {
              if (transactionProvider.transactions.isEmpty) {
                return const SizedBox.shrink();
              }

              final currencies = transactionProvider.transactions
                  .map((t) => t.currency)
                  .toSet()
                  .toList();

              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                child: _buildBalanceCard(
                  balance: transactionProvider.getBalance(),
                  currencies: currencies,
                  transactionProvider: transactionProvider,
                ),
              );
            },
          ),

          const SizedBox(height: 6),

          // Transactions List
          Expanded(
            child: Consumer2<TransactionProvider, CategoryProvider>(
              builder: (context, transactionProvider, categoryProvider, child) {
                if (transactionProvider.isLoading && transactionProvider.transactions.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (transactionProvider.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${transactionProvider.error}',
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              transactionProvider.clearError();
                              transactionProvider.fetchTransactions();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (transactionProvider.transactions.isEmpty) {
                  return TransactionEmptyState(
                    onAddTransaction: _navigateToAddTransaction,
                  );
                }

                final sortedTransactions = List<Transaction>.from(transactionProvider.transactions)
                  ..sort((a, b) => b.date.compareTo(a.date));

                return RefreshIndicator(
                  onRefresh: () async {
                    await transactionProvider.fetchTransactions();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                    itemCount: sortedTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = sortedTransactions[index];
                      return TransactionCard(
                        transaction: transaction,
                        categoryProvider: categoryProvider,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required List<String> currencies,
    required TransactionProvider transactionProvider,
    required bool isIncome,
  }) {
    final theme = Theme.of(context);
    final color = isIncome ? Colors.green : Colors.red;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...currencies.map((currency) {
            final total = (isIncome
                ? transactionProvider.getIncomeTransactions()
                : transactionProvider.getExpenseTransactions())
                .where((t) => t.currency == currency)
                .fold(0.0, (sum, t) => sum + t.amount);

            return Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: Text(
                '$currency ${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBalanceCard({
    required double balance,
    required List<String> currencies,
    required TransactionProvider transactionProvider,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
          colors: [
            AppTheme.lightPurple.withOpacity(0.2),
            AppTheme.lightGold.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : LinearGradient(
          colors: [
            AppTheme.primaryPurple.withOpacity(0.1),
            AppTheme.deepGold.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Balance',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...currencies.map((currency) {
            final income = transactionProvider
                .getIncomeTransactions()
                .where((t) => t.currency == currency)
                .fold(0.0, (sum, t) => sum + t.amount);
            final expense = transactionProvider
                .getExpenseTransactions()
                .where((t) => t.currency == currency)
                .fold(0.0, (sum, t) => sum + t.amount);
            final currencyBalance = income - expense;

            return Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: Text(
                '$currency ${currencyBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: currencyBalance >= 0 ? Colors.green : Colors.red,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final CategoryProvider categoryProvider;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.categoryProvider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TransactionFormScreen(transaction: transaction),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              // Category Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(int.parse(transaction.category.color.replaceAll('#', '0xFF'))),
                      Color(int.parse(transaction.category.color.replaceAll('#', '0xFF')))
                          .withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Color(int.parse(transaction.category.color.replaceAll('#', '0xFF')))
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _getIconData(transaction.category.icon),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(int.parse(transaction.category.color.replaceAll('#', '0xFF')))
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            transaction.category.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(int.parse(transaction.category.color.replaceAll('#', '0xFF'))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.calendar_today,
                          size: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(transaction.date),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${transaction.currency} ${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: transaction.type == 'income' ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (transaction.type == 'income' ? Colors.green : Colors.red).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          transaction.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
                          color: transaction.type == 'income' ? Colors.green : Colors.red,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          transaction.type == 'income' ? 'In' : 'Out',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: transaction.type == 'income' ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'fastfood':
        return Icons.fastfood;
      case 'directions_car':
        return Icons.directions_car;
      case 'attach_money':
        return Icons.attach_money;
      case 'bolt':
        return Icons.bolt;
      case 'movie':
        return Icons.movie;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'home':
        return Icons.home;
      case 'medical_services':
        return Icons.medical_services;
      case 'school':
        return Icons.school;
      case 'flight':
        return Icons.flight;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_grocery_store':
        return Icons.local_grocery_store;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'pets':
        return Icons.pets;
      case 'child_care':
        return Icons.child_care;
      case 'work':
        return Icons.work;
      case 'savings':
        return Icons.savings;
      case 'card_giftcard':
        return Icons.card_giftcard;
      default:
        return Icons.category;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
}