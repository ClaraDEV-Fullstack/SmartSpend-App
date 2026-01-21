import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../screens/transactions/transaction_form_screen.dart';

class TransactionSearchDelegate extends SearchDelegate {
  final List<Transaction> transactions;

  TransactionSearchDelegate(this.transactions);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final input = query.toLowerCase();
    final results = transactions.where((tx) {
      final description = tx.description.toLowerCase();
      final category = tx.category.name.toLowerCase();
      final amount = tx.amount.toString();

      return description.contains(input) ||
          category.contains(input) ||
          amount.contains(input);
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              query.isEmpty ? 'Search your history' : 'No results found',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final tx = results[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Color(int.parse(tx.category.color.replaceAll('#', '0xFF'))),
            child: Icon(_getIconData(tx.category.icon), color: Colors.white, size: 20),
          ),
          title: Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${tx.category.name} • ${_formatDate(tx.date)}'),
          trailing: Text(
            '${tx.currency} ${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: tx.type == 'income' ? Colors.green : Colors.red,
            ),
          ),
          onTap: () {
            close(context, null); // Close search
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TransactionFormScreen(transaction: tx),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'fastfood': return Icons.fastfood;
      case 'directions_car': return Icons.directions_car;
      case 'attach_money': return Icons.attach_money;
      case 'bolt': return Icons.bolt;
      case 'movie': return Icons.movie;
      default: return Icons.category;
    }
  }
}