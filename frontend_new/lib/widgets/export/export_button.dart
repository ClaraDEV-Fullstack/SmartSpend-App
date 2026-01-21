import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../services/export_service.dart';
import 'export_progress_dialog.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';


class ExportButton extends StatelessWidget {
  const ExportButton({Key? key}) : super(key: key);

  Future<void> _showExportDialog(BuildContext context) async {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    if (transactionProvider.transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isExporting = true;
          bool isSuccess = false;
          String? filePath;
          String? error;

          // Start the export process
          _exportData(
            transactionProvider.transactions,
            categoryProvider.categories,
          ).then((path) {
            setState(() {
              isExporting = false;
              isSuccess = true;
              filePath = path;
            });
          }).catchError((e) {
            setState(() {
              isExporting = false;
              isSuccess = false;
              error = e.toString();
            });
          });

          return ExportProgressDialog(
            isExporting: isExporting,
            isSuccess: isSuccess,
            filePath: filePath,
            error: error,
            onShare: isSuccess && filePath != null
                ? () async {
              try {
                await ExportService.shareExportedFile(filePath!);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to share file: $e')),
                );
              }
            }
                : null,
            onDismiss: () => Navigator.of(context).pop(),
          );
        },
      ),
    );
  }

  Future<String> _exportData(
      List<Transaction> transactions, List<Category> categories) async {
    return await ExportService.exportTransactionsToCSV(transactions, categories);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.file_download),
      onPressed: () => _showExportDialog(context),
      tooltip: 'Export Transactions',
    );
  }
}