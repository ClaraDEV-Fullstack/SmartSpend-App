// lib/screens/settings/settings_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/theme_service.dart';
import '../../services/notification_service.dart';
import '../../services/biometric_service.dart';
import '../../services/export_service.dart';
import '../../models/user_setting.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  bool _isExporting = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);
  String _startOfWeek = 'Sunday';
  String _dateFormat = 'MM/DD/YYYY';
  double _monthlyBudget = 1000.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadSettings();
        _initializeServices();
      }
    });
  }

  Future<void> _initializeServices() async {
    if (!kIsWeb) {
      final biometricService = Provider.of<BiometricService>(context, listen: false);
      await biometricService.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer2<SettingsProvider, NotificationService>(
        builder: (context, settingsProvider, notificationService, child) {
          if (settingsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (settingsProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${settingsProvider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      settingsProvider.clearError();
                      _loadSettings();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final settings = settingsProvider.settings;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('General'),
                _buildGeneralSection(settings, settingsProvider),
                const SizedBox(height: 24),

                _buildSectionTitle('Data & Export'),
                _buildDataExportSection(settings),
                const SizedBox(height: 24),

                _buildSectionTitle('Notifications'),
                _buildNotificationsSection(
                  settings,
                  settingsProvider,
                  notificationService,
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Privacy & Security'),
                _buildPrivacySection(settings, settingsProvider),
                const SizedBox(height: 24),

                _buildSectionTitle('Budget'),
                _buildBudgetSection(settings, settingsProvider),
                const SizedBox(height: 24),

                _buildSectionTitle('About'),
                _buildAboutSection(),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildGeneralSection(
      UserSetting? settings,
      SettingsProvider settingsProvider,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.attach_money, color: Colors.green),
            title: const Text('Currency'),
            subtitle: Text(settings?.currency ?? 'USD'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCurrencySelector(settingsProvider),
          ),
          const Divider(),
          Consumer<ThemeService>(
            builder: (context, themeService, child) {
              return ListTile(
                leading: const Icon(Icons.palette, color: Colors.purple),
                title: const Text('Theme'),
                subtitle: Text(_formatThemeMode(themeService.themeMode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeSelector(themeService),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.calendar_today, color: Colors.blue),
            title: const Text('Start of Week'),
            subtitle: Text(settings?.startOfWeek ?? _startOfWeek),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showStartOfWeekSelector(settingsProvider),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.date_range, color: Colors.orange),
            title: const Text('Date Format'),
            subtitle: Text(settings?.dateFormat ?? _dateFormat),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDateFormatSelector(settingsProvider),
          ),
        ],
      ),
    );
  }

  // ==================== DATA EXPORT SECTION ====================

  Widget _buildDataExportSection(UserSetting? settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Export to CSV
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.table_chart, color: Colors.green),
            ),
            title: const Text('Export to CSV'),
            subtitle: Text(kIsWeb
                ? 'Download Excel-compatible file'
                : 'Share as spreadsheet'),
            trailing: _isExporting
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Icon(kIsWeb ? Icons.download : Icons.share, color: Colors.grey),
            onTap: _isExporting ? null : () => _handleExport('csv'),
          ),
          const Divider(),

          // Export to PDF
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.picture_as_pdf, color: Colors.red),
            ),
            title: const Text('Export to PDF'),
            subtitle: Text(kIsWeb
                ? 'Download printable report'
                : 'Share as report'),
            trailing: _isExporting
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Icon(kIsWeb ? Icons.download : Icons.share, color: Colors.grey),
            onTap: _isExporting ? null : () => _handleExport('pdf'),
          ),
          const Divider(),

          // Export Date Range
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.date_range, color: Colors.blue),
            ),
            title: const Text('Export Date Range'),
            subtitle: const Text('Select specific period'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: _isExporting ? null : () => _showDateRangeExportDialog(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport(String format) async {
    setState(() => _isExporting = true);

    try {
      // Get transactions
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );

      // Ensure we have data
      if (transactionProvider.transactions.isEmpty) {
        await transactionProvider.fetchTransactions();
      }

      final transactions = transactionProvider.transactions;

      if (transactions.isEmpty) {
        _showSnackBar('No transactions to export', isError: true);
        return;
      }

      // Perform export
      if (format == 'csv') {
        await ExportService.exportToCSV(transactions);
        _showSnackBar(kIsWeb
            ? 'CSV downloaded successfully!'
            : 'CSV ready to share!');
      } else {
        await ExportService.exportToPDF(transactions);
        _showSnackBar(kIsWeb
            ? 'PDF downloaded successfully!'
            : 'PDF ready to share!');
      }
    } catch (e) {
      _showSnackBar('Export failed: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _showDateRangeExportDialog() async {
    DateTimeRange? selectedRange;
    String selectedFormat = 'pdf';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Export Date Range'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Range Button
              InkWell(
                onTap: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: selectedRange,
                  );
                  if (range != null) {
                    setDialogState(() => selectedRange = range);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedRange != null
                              ? '${DateFormat('MMM dd, yyyy').format(selectedRange!.start)} - ${DateFormat('MMM dd, yyyy').format(selectedRange!.end)}'
                              : 'Tap to select date range',
                          style: TextStyle(
                            color: selectedRange != null
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Format Selection
              const Text(
                'Export Format',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('PDF'),
                      value: 'pdf',
                      groupValue: selectedFormat,
                      onChanged: (value) {
                        setDialogState(() => selectedFormat = value!);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('CSV'),
                      value: 'csv',
                      groupValue: selectedFormat,
                      onChanged: (value) {
                        setDialogState(() => selectedFormat = value!);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedRange == null
                  ? null
                  : () {
                Navigator.pop(context, {
                  'range': selectedRange,
                  'format': selectedFormat,
                });
              },
              child: const Text('Export'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _exportWithDateRange(
        result['range'] as DateTimeRange,
        result['format'] as String,
      );
    }
  }

  Future<void> _exportWithDateRange(DateTimeRange range, String format) async {
    setState(() => _isExporting = true);

    try {
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );

      await transactionProvider.fetchTransactions();

      // Filter transactions by date range
      final allTransactions = transactionProvider.transactions;
      final filteredTransactions = allTransactions.where((t) {
        return t.date.isAfter(range.start.subtract(const Duration(days: 1))) &&
            t.date.isBefore(range.end.add(const Duration(days: 1)));
      }).toList();

      if (filteredTransactions.isEmpty) {
        _showSnackBar('No transactions found in selected range', isError: true);
        return;
      }

      // Generate report title
      final reportTitle = 'Transactions ${DateFormat('MMM dd').format(range.start)} - ${DateFormat('MMM dd, yyyy').format(range.end)}';

      if (format == 'csv') {
        await ExportService.exportToCSV(filteredTransactions);
        _showSnackBar(
          '${filteredTransactions.length} transactions exported to CSV!',
        );
      } else {
        await ExportService.exportToPDF(
          filteredTransactions,
          reportTitle: reportTitle,
        );
        _showSnackBar(
          '${filteredTransactions.length} transactions exported to PDF!',
        );
      }
    } catch (e) {
      _showSnackBar('Export failed: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  // ==================== OTHER SECTIONS ====================

  Widget _buildNotificationsSection(
      UserSetting? settings,
      SettingsProvider settingsProvider,
      NotificationService notificationService,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          if (kIsWeb)
            const ListTile(
              leading: Icon(Icons.info_outline, color: Colors.orange),
              title: Text('Notifications'),
              subtitle: Text('Push notifications are not available on web'),
            )
          else ...[
            SwitchListTile(
              secondary: const Icon(Icons.notifications, color: Colors.blue),
              title: const Text('Enable Notifications'),
              subtitle: const Text('Receive app notifications'),
              value: settings?.notificationsEnabled ?? true,
              onChanged: (value) {
                settingsProvider.updateSettings({'notifications_enabled': value});
                notificationService.setNotificationsEnabled(value);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.teal),
              title: const Text('Reminder Time'),
              subtitle: Text(_notificationTime.format(context)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showNotificationTimeSelector(
                notificationService,
                settingsProvider,
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.science, color: Colors.amber),
              title: const Text('Test Notification'),
              subtitle: const Text('Send a test notification'),
              trailing: const Icon(Icons.send),
              onTap: () async {
                await notificationService.sendTestNotification();
                if (mounted) {
                  _showSnackBar('Test notification sent!');
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrivacySection(
      UserSetting? settings,
      SettingsProvider settingsProvider,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          if (!kIsWeb)
            Consumer<BiometricService>(
              builder: (context, biometricService, child) {
                if (!biometricService.isAvailable) {
                  return const ListTile(
                    leading: Icon(Icons.fingerprint, color: Colors.grey),
                    title: Text('Biometric Login'),
                    subtitle: Text('Not available on this device'),
                  );
                }

                return SwitchListTile(
                  secondary: const Icon(Icons.fingerprint, color: Colors.red),
                  title: Text('${biometricService.biometricTypeName} Login'),
                  subtitle: Text(
                    'Use ${biometricService.biometricTypeName.toLowerCase()} to unlock',
                  ),
                  value: biometricService.isEnabled,
                  onChanged: (value) async {
                    final success = await biometricService.setBiometricEnabled(value);
                    if (success) {
                      settingsProvider.updateSettings({'biometric_enabled': value});
                    }
                  },
                );
              },
            ),
          if (!kIsWeb) const Divider(),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.blue),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangePasswordDialog(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Colors.green),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPrivacyPolicy(),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSection(
      UserSetting? settings,
      SettingsProvider settingsProvider,
      ) {
    final currencySymbol = _getCurrencySymbol(settings?.currency ?? 'USD');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.warning_amber, color: Colors.orange),
            title: const Text('Budget Alerts'),
            subtitle: const Text('Notify when approaching budget limit'),
            value: settings?.budgetAlerts ?? true,
            onChanged: (value) {
              settingsProvider.updateSettings({'budget_alerts': value});
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.account_balance_wallet,
              color: Colors.green,
            ),
            title: const Text('Monthly Budget'),
            subtitle: Text(
              '$currencySymbol${NumberFormat('#,##0.00').format(settings?.monthlyBudget ?? _monthlyBudget)}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBudgetDialog(settingsProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.info, color: Colors.blue),
            title: Text('App Version'),
            subtitle: Text('1.0.0'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description, color: Colors.orange),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTermsOfService(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.support_agent, color: Colors.green),
            title: const Text('Contact Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showContactSupport(),
          ),
        ],
      ),
    );
  }

  // ============ HELPER METHODS ============

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );
      await settingsProvider.fetchSettings();

      final settings = settingsProvider.settings;
      if (settings != null) {
        setState(() {
          _startOfWeek = settings.startOfWeek;
          _dateFormat = settings.dateFormat;
          _monthlyBudget = settings.monthlyBudget;

          final timeParts = settings.notificationTime.split(':');
          if (timeParts.length >= 2) {
            _notificationTime = TimeOfDay(
              hour: int.tryParse(timeParts[0]) ?? 9,
              minute: int.tryParse(timeParts[1]) ?? 0,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error loading settings: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final notificationTimeString =
          '${_notificationTime.hour.toString().padLeft(2, '0')}:${_notificationTime.minute.toString().padLeft(2, '0')}';

      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );
      await settingsProvider.updateSettings({
        'start_of_week': _startOfWeek,
        'date_format': _dateFormat,
        'monthly_budget': _monthlyBudget,
        'notification_time': notificationTimeString,
      });

      if (mounted) {
        _showSnackBar('Settings saved successfully');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error saving settings: $e', isError: true);
      }
    }
  }

  void _showCurrencySelector(SettingsProvider settingsProvider) {
    final currencies = [
      {'value': 'USD', 'label': 'US Dollar (USD)', 'symbol': '\$'},
      {'value': 'EUR', 'label': 'Euro (EUR)', 'symbol': '€'},
      {'value': 'GBP', 'label': 'British Pound (GBP)', 'symbol': '£'},
      {'value': 'CFA', 'label': 'CFA Franc (CFA)', 'symbol': 'CFA'},
      {'value': 'JPY', 'label': 'Japanese Yen (JPY)', 'symbol': '¥'},
      {'value': 'NGN', 'label': 'Nigerian Naira (NGN)', 'symbol': '₦'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select Currency',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...currencies.map((c) => ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade100,
              child: Text(c['symbol']!, style: const TextStyle(fontSize: 14)),
            ),
            title: Text(c['label']!),
            onTap: () {
              Navigator.pop(context);
              settingsProvider.updateSettings({'currency': c['value']});
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showThemeSelector(ThemeService themeService) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select Theme',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.light_mode, color: Colors.orange),
            title: const Text('Light'),
            trailing: themeService.themeMode == ThemeMode.light
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              Navigator.pop(context);
              themeService.setThemeMode(ThemeMode.light);
            },
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode, color: Colors.indigo),
            title: const Text('Dark'),
            trailing: themeService.themeMode == ThemeMode.dark
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              Navigator.pop(context);
              themeService.setThemeMode(ThemeMode.dark);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_suggest, color: Colors.grey),
            title: const Text('System Default'),
            trailing: themeService.themeMode == ThemeMode.system
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              Navigator.pop(context);
              themeService.setThemeMode(ThemeMode.system);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showStartOfWeekSelector(SettingsProvider settingsProvider) {
    final days = ['Sunday', 'Monday'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Start of Week',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...days.map((day) => ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(day),
            trailing: _startOfWeek == day
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              Navigator.pop(context);
              setState(() => _startOfWeek = day);
              settingsProvider.updateSettings({'start_of_week': day});
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showDateFormatSelector(SettingsProvider settingsProvider) {
    final formats = ['MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Date Format',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...formats.map((f) => ListTile(
            leading: const Icon(Icons.date_range),
            title: Text(f),
            trailing: _dateFormat == f
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              Navigator.pop(context);
              setState(() => _dateFormat = f);
              settingsProvider.updateSettings({'date_format': f});
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showNotificationTimeSelector(
      NotificationService notificationService,
      SettingsProvider settingsProvider,
      ) {
    showTimePicker(context: context, initialTime: _notificationTime).then((time) {
      if (time != null) {
        setState(() => _notificationTime = time);
        final timeString =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        settingsProvider.updateSettings({'notification_time': timeString});
        notificationService.setNotificationTime(time);
      }
    });
  }

  void _showBudgetDialog(SettingsProvider settingsProvider) {
    final controller = TextEditingController(
      text: _monthlyBudget.toStringAsFixed(2),
    );
    final symbol = _getCurrencySymbol(settingsProvider.settings?.currency ?? 'USD');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Monthly Budget'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: symbol,
            hintText: 'Enter budget',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text) ?? _monthlyBudget;
              setState(() => _monthlyBudget = value);
              settingsProvider.updateSettings({'monthly_budget': value});
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureCurrent ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setDialogState(
                          () => obscureCurrent = !obscureCurrent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNew ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setDialogState(
                          () => obscureNew = !obscureNew,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirm ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setDialogState(
                          () => obscureConfirm = !obscureConfirm,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) => ElevatedButton(
                onPressed: () async {
                  if (newController.text != confirmController.text) {
                    _showSnackBar('Passwords do not match', isError: true);
                    return;
                  }
                  if (newController.text.length < 6) {
                    _showSnackBar(
                      'Password must be at least 6 characters',
                      isError: true,
                    );
                    return;
                  }
                  Navigator.pop(dialogContext);
                  try {
                    await authProvider.changePassword(
                      currentController.text,
                      newController.text,
                    );
                    _showSnackBar('Password changed successfully');
                  } catch (e) {
                    _showSnackBar('Error: $e', isError: true);
                  }
                },
                child: const Text('Change'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Your privacy is important to us.\n\n'
                '1. Data Collection: We collect minimal data necessary to provide our services.\n\n'
                '2. Data Storage: Your data is stored securely and encrypted.\n\n'
                '3. Data Sharing: We do not sell or share your personal data.\n\n'
                '4. Data Export: You can export all your data at any time.\n\n'
                '5. Account Deletion: Contact support to delete your account.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'By using SmartSpend, you agree to:\n\n'
                '1. Use the app for personal finance tracking only.\n\n'
                '2. Provide accurate information.\n\n'
                '3. Keep your credentials secure.\n\n'
                '4. Accept periodic updates to these terms.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showContactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.email, color: Colors.blue),
              title: Text('Email'),
              subtitle: Text('support@smartspend.com'),
            ),
            ListTile(
              leading: Icon(Icons.phone, color: Colors.green),
              title: Text('Phone'),
              subtitle: Text('+237 683-669-723'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'CFA':
        return 'CFA ';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'NGN':
        return '₦';
      default:
        return '$currency ';
    }
  }
}