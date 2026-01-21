// lib/services/export_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Conditional imports for platform-specific functionality
import 'export_service_stub.dart'
if (dart.library.io) 'export_service_mobile.dart'
if (dart.library.html) 'export_service_web.dart';



import '../models/transaction.dart';
import '../models/category.dart';

class ExportService {

  // ==================== CSV EXPORT ====================

  /// Main CSV export method
  static Future<String> exportToCSV(List<Transaction> transactions) async {
    try {
      if (transactions.isEmpty) {
        throw Exception('No transactions to export');
      }

      List<List<dynamic>> rows = [];

      // Header row
      rows.add([
        'Date',
        'Type',
        'Category',
        'Description',
        'Amount',
        'Currency',
        'Is Recurring',
        'Recurrence'
      ]);

      // Data rows
      for (var t in transactions) {
        rows.add([
          DateFormat('yyyy-MM-dd').format(t.date),
          t.type,
          t.category.name,
          _escapeCSVField(t.description),
          t.amount.toStringAsFixed(2),
          t.currency,
          t.isRecurring == true ? 'Yes' : 'No',
          t.recurrence ?? '',
        ]);
      }

      // Convert to CSV string
      String csvData = const ListToCsvConverter().convert(rows);

      // Generate filename
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'transactions_$timestamp.csv';

      // Use platform-specific export
      final filePath = await exportFile(
        Uint8List.fromList(utf8.encode(csvData)),
        fileName,
        'text/csv',
      );

      return filePath;
    } catch (e) {
      throw Exception('CSV Export failed: $e');
    }
  }

  // ==================== PDF EXPORT ====================

  /// Main PDF export method
  static Future<String> exportToPDF(
      List<Transaction> transactions, {
        String? reportTitle,
      }) async {
    try {
      if (transactions.isEmpty) {
        throw Exception('No transactions to export');
      }

      final pdf = pw.Document();
      final currency = transactions.first.currency;
      final currencySymbol = _getCurrencySymbol(currency);

      // Calculate totals
      double totalIncome = 0;
      double totalExpense = 0;
      final Map<String, double> categoryTotals = {};

      for (var t in transactions) {
        if (t.type.toLowerCase() == 'income') {
          totalIncome += t.amount;
        } else {
          totalExpense += t.amount;
          categoryTotals[t.category.name] =
              (categoryTotals[t.category.name] ?? 0) + t.amount;
        }
      }

      final netBalance = totalIncome - totalExpense;

      // Sort transactions by date (newest first)
      final sortedTransactions = List<Transaction>.from(transactions)
        ..sort((a, b) => b.date.compareTo(a.date));

      // Sort categories by amount
      final sortedCategories = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Build PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => _buildPdfHeader(reportTitle),
          footer: (context) => _buildPdfFooter(context),
          build: (pw.Context context) {
            return [
              // Summary Section
              _buildSummarySection(
                totalIncome: totalIncome,
                totalExpense: totalExpense,
                netBalance: netBalance,
                currencySymbol: currencySymbol,
              ),
              pw.SizedBox(height: 20),

              // Category Breakdown
              if (sortedCategories.isNotEmpty) ...[
                _buildCategoryBreakdown(
                  sortedCategories,
                  totalExpense,
                  currencySymbol,
                ),
                pw.SizedBox(height: 20),
              ],

              // Transactions Table
              _buildTransactionsTable(sortedTransactions, currencySymbol),
            ];
          },
        ),
      );

      // Save PDF
      final pdfBytes = await pdf.save();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'report_$timestamp.pdf';

      // Use platform-specific export
      final filePath = await exportFile(
        pdfBytes,
        fileName,
        'application/pdf',
      );

      return filePath;
    } catch (e) {
      throw Exception('PDF Export failed: $e');
    }
  }

  // ==================== PDF BUILDING HELPERS ====================

  static pw.Widget _buildPdfHeader(String? title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title ?? 'Transaction Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'SmartSpend',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey600,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Generated on',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                DateFormat('MMMM dd, yyyy').format(DateTime.now()),
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                DateFormat('hh:mm a').format(DateTime.now()),
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'SmartSpend - Personal Finance Tracker',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummarySection({
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
    required String currencySymbol,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                label: 'Total Income',
                amount: totalIncome,
                currencySymbol: currencySymbol,
                color: PdfColors.green700,
                prefix: '+',
              ),
              _buildSummaryItem(
                label: 'Total Expenses',
                amount: totalExpense,
                currencySymbol: currencySymbol,
                color: PdfColors.red700,
                prefix: '-',
              ),
              _buildSummaryItem(
                label: 'Net Balance',
                amount: netBalance,
                currencySymbol: currencySymbol,
                color: netBalance >= 0 ? PdfColors.green700 : PdfColors.red700,
                prefix: netBalance >= 0 ? '+' : '',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem({
    required String label,
    required double amount,
    required String currencySymbol,
    required PdfColor color,
    required String prefix,
  }) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '$prefix$currencySymbol${_formatNumber(amount.abs())}',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildCategoryBreakdown(
      List<MapEntry<String, double>> categories,
      double totalExpense,
      String currencySymbol,
      ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Expense Breakdown by Category',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 12),
          ...categories.take(10).map((entry) {
            final percentage = totalExpense > 0
                ? (entry.value / totalExpense * 100)
                : 0.0;
            final barWidth = totalExpense > 0
                ? (entry.value / totalExpense * 200)
                : 0.0;

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 80,
                    child: pw.Text(
                      entry.key.length > 12
                          ? '${entry.key.substring(0, 12)}...'
                          : entry.key,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Container(
                    width: 200,
                    height: 12,
                    child: pw.Stack(
                      children: [
                        pw.Container(
                          width: 200,
                          height: 12,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey200,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                        ),
                        pw.Container(
                          width: barWidth,
                          height: 12,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.blue400,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.SizedBox(
                    width: 60,
                    child: pw.Text(
                      '$currencySymbol${_formatNumber(entry.value)}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.SizedBox(width: 4),
                  pw.SizedBox(
                    width: 40,
                    child: pw.Text(
                      '(${percentage.toStringAsFixed(1)}%)',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  static pw.Widget _buildTransactionsTable(
      List<Transaction> transactions,
      String currencySymbol,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Transaction Details',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey800,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(70),
            1: const pw.FixedColumnWidth(50),
            2: const pw.FixedColumnWidth(80),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FixedColumnWidth(80),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
              children: [
                _buildTableHeaderCell('Date'),
                _buildTableHeaderCell('Type'),
                _buildTableHeaderCell('Category'),
                _buildTableHeaderCell('Description'),
                _buildTableHeaderCell('Amount'),
              ],
            ),
            // Data rows
            ...transactions.map((t) {
              final isExpense = t.type.toLowerCase() == 'expense';
              final amountPrefix = isExpense ? '-' : '+';
              final amountColor = isExpense ? PdfColors.red700 : PdfColors.green700;

              return pw.TableRow(
                children: [
                  _buildTableCell(DateFormat('MM/dd/yy').format(t.date)),
                  _buildTableCell(
                    t.type.substring(0, 1).toUpperCase() +
                        (t.type.length > 3 ? t.type.substring(1, 4) : t.type.substring(1)),
                    color: amountColor,
                  ),
                  _buildTableCell(
                    t.category.name.length > 10
                        ? '${t.category.name.substring(0, 10)}...'
                        : t.category.name,
                  ),
                  _buildTableCell(
                    t.description.length > 25
                        ? '${t.description.substring(0, 25)}...'
                        : t.description,
                  ),
                  _buildTableCell(
                    '$amountPrefix$currencySymbol${_formatNumber(t.amount)}',
                    color: amountColor,
                    alignRight: true,
                  ),
                ],
              );
            }).toList(),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Total Transactions: ${transactions.length}',
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
      String text, {
        PdfColor? color,
        bool alignRight = false,
      }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }

  // ==================== UTILITY METHODS ====================

  static String _escapeCSVField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field.replaceAll(',', ';');
  }

  static String _formatNumber(double number) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(number);
  }

  static String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
      case 'CNY':
        return '¥';
      case 'CFA':
      case 'XOF':
      case 'XAF':
        return 'CFA ';
      case 'NGN':
        return '₦';
      case 'KES':
        return 'KSh ';
      case 'ZAR':
        return 'R';
      case 'INR':
        return '₹';
      case 'BRL':
        return 'R\$';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      default:
        return '$currency ';
    }
  }

  // ==================== LEGACY METHODS (Backward Compatibility) ====================

  /// Legacy method - kept for backwards compatibility with transactions_screen.dart
  static Future<String> exportTransactionsToCSV(
      List<Transaction> transactions,
      List<Category> categories,
      ) async {
    return await exportToCSV(transactions);
  }

  /// Legacy method - kept for backwards compatibility
  static Future<void> shareExportedFile(String filePath) async {
    await shareFile(filePath);
  }
}