import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../screens/transactions/transaction_form_screen.dart';

class TransactionSearchDelegate extends SearchDelegate<String> {
  final List<Transaction> transactions;

  TransactionSearchDelegate(this.transactions);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final List<Transaction> suggestionList = query.isEmpty
        ? []
        : transactions.where((transaction) {
      final descriptionLower = transaction.description.toLowerCase();
      final categoryLower = transaction.category.name.toLowerCase();
      final amountLower = transaction.amount.toString().toLowerCase();
      final typeLower = transaction.type.toLowerCase();
      final currencyLower = transaction.currency.toLowerCase();
      final queryLower = query.toLowerCase();

      return descriptionLower.contains(queryLower) ||
          categoryLower.contains(queryLower) ||
          amountLower.contains(queryLower) ||
          typeLower.contains(queryLower) ||
          currencyLower.contains(queryLower);
    }).toList();

    if (suggestionList.isEmpty) {
      return const Center(
        child: Text('No transactions found'),
      );
    }

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        final transaction = suggestionList[index];
        return _buildTransactionCard(context, transaction);
      },
    );
  }

  Widget _buildTransactionCard(BuildContext context, Transaction transaction) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to transaction details
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TransactionFormScreen(transaction: transaction),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Category Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(int.parse(transaction.category.color.replaceAll('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(24),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${transaction.category.name} • ${_formatDate(transaction.date)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
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
                      fontSize: 16,
                      color: transaction.type == 'income' ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    transaction.type == 'income'
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: transaction.type == 'income' ? Colors.green : Colors.red,
                    size: 16,
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
      default:
        return Icons.category;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
}