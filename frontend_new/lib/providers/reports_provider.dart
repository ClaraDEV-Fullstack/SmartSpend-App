// lib/providers/reports_provider.dart
import 'package:flutter/material.dart';
import '../services/reports_service.dart';

class ReportsProvider with ChangeNotifier {
  final ReportsService _reportsService;

  ReportsProvider(this._reportsService);

  Map<String, dynamic>? _reportSummary;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get reportSummary => _reportSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    // Use addPostFrameCallback to avoid notifyListeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> fetchReportSummary({
    String? startDate,
    String? endDate,
    int? categoryId,
  }) async {
    _setLoading(true);
    try {
      _reportSummary = await _reportsService.getReportSummary(
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
      );
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    // Use addPostFrameCallback to avoid notifyListeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _setError(String error) {
    if (error.startsWith('Exception: ')) {
      error = error.substring('Exception: '.length);
    }
    _error = error;
    // Use addPostFrameCallback to avoid notifyListeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}