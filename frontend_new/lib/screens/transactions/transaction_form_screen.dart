// lib/screens/transactions/transaction_form_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../models/recurring_transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/recurring_transaction_provider.dart';
import '../../providers/settings_provider.dart';

class TransactionFormScreen extends StatefulWidget {
  final Transaction? transaction;

  const TransactionFormScreen({super.key, this.transaction});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'expense';
  Category? _selectedCategory;
  String _selectedCurrency = 'USD';
  bool _isLoading = false;
  bool _categoriesLoaded = false;

  // Recurring transaction state
  bool _isRecurring = false;
  RecurrenceFrequency? _selectedFrequency;
  String? _endCondition;
  DateTime? _endDate;
  int? _totalExecutions;

  bool get _isEditing => widget.transaction != null;

  final List<Map<String, dynamic>> _transactionTypes = [
    {'value': 'expense', 'label': 'Expense', 'icon': Icons.arrow_upward, 'color': Colors.red},
    {'value': 'income', 'label': 'Income', 'icon': Icons.arrow_downward, 'color': Colors.green},
  ];

  final List<Map<String, dynamic>> _currencyOptions = [
    {'value': 'USD', 'label': 'USD - US Dollar', 'symbol': '\$'},
    {'value': 'EUR', 'label': 'EUR - Euro', 'symbol': '€'},
    {'value': 'GBP', 'label': 'GBP - British Pound', 'symbol': '£'},
    {'value': 'CFA', 'label': 'CFA - West African Franc', 'symbol': 'CFA'},
    {'value': 'JPY', 'label': 'JPY - Japanese Yen', 'symbol': '¥'},
    {'value': 'CAD', 'label': 'CAD - Canadian Dollar', 'symbol': 'C\$'},
    {'value': 'AUD', 'label': 'AUD - Australian Dollar', 'symbol': 'A\$'},
    {'value': 'CHF', 'label': 'CHF - Swiss Franc', 'symbol': 'Fr'},
    {'value': 'CNY', 'label': 'CNY - Chinese Yuan', 'symbol': '¥'},
    {'value': 'INR', 'label': 'INR - Indian Rupee', 'symbol': '₹'},
    {'value': 'MXN', 'label': 'MXN - Mexican Peso', 'symbol': '\$'},
  ];

  @override
  void initState() {
    super.initState();

    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final userDefaultCurrency = settingsProvider.settings?.currency ?? 'USD';

    if (_isEditing) {
      _descriptionController.text = widget.transaction!.description;
      _amountController.text = widget.transaction!.amount.toString();
      _selectedDate = widget.transaction!.date;
      _selectedType = widget.transaction!.type;
      _selectedCurrency = widget.transaction!.currency;
      _isRecurring = widget.transaction!.isRecurring ?? false;
      // Note: We'll set _selectedCategory after categories are loaded
    } else {
      _selectedCurrency = userDefaultCurrency;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  Future<void> _loadCategories() async {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    await categoryProvider.fetchCategories();

    // After categories are loaded, match the transaction's category
    if (_isEditing && widget.transaction != null) {
      _matchSelectedCategory(categoryProvider);
    }

    setState(() {
      _categoriesLoaded = true;
    });
  }

  void _matchSelectedCategory(CategoryProvider categoryProvider) {
    final transactionCategoryId = widget.transaction!.category.id;

    // Find the category from the provider's list that matches the transaction's category id
    final allCategories = categoryProvider.categories;
    final matchedCategory = allCategories.firstWhere(
          (cat) => cat.id == transactionCategoryId,
      orElse: () => widget.transaction!.category, // Fallback to the transaction's category
    );

    setState(() {
      _selectedCategory = matchedCategory;
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        elevation: 0,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _isLoading ? null : _showDeleteConfirmation,
              tooltip: 'Delete Transaction',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTransactionTypeSelector(),
              const SizedBox(height: 16),
              _buildAmountAndCurrencyFields(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              _buildCategoryField(),
              const SizedBox(height: 16),
              _buildRecurringSection(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTypeSelector() {
    return Row(
      children: _transactionTypes.map((type) {
        final isSelected = _selectedType == type['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedType = type['value'];
              _selectedCategory = null; // Reset category when type changes
            }),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? (type['color'] as Color).withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? type['color'] as Color : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(type['icon'] as IconData, color: isSelected ? type['color'] as Color : Colors.grey),
                  const SizedBox(height: 4),
                  Text(
                    type['label'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? type['color'] as Color : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmountAndCurrencyFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedCurrency,
            decoration: const InputDecoration(labelText: 'Currency', border: InputBorder.none),
            isExpanded: true,
            items: _currencyOptions.map((c) => DropdownMenuItem(
              value: c['value'] as String,
              child: Text(c['label'] as String),
            )).toList(),
            onChanged: (value) => setState(() => _selectedCurrency = value!),
          ),
          const Divider(height: 1),
          Row(
            children: [
              Text(
                _getCurrencySymbol(_selectedCurrency),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Amount', border: InputBorder.none),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter an amount';
                    final amount = double.tryParse(value);
                    if (amount == null) return 'Please enter a valid number';
                    if (amount <= 0) return 'Amount must be greater than 0';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: _descriptionController,
        decoration: const InputDecoration(labelText: 'Description', border: InputBorder.none),
        validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.calendar_today, color: Colors.blue),
        ),
        title: const Text('Date'),
        subtitle: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2000),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) setState(() => _selectedDate = picked);
        },
      ),
    );
  }

  Widget _buildCategoryField() {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        if (categoryProvider.isLoading || !_categoriesLoaded) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (categoryProvider.error != null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text('Error: ${categoryProvider.error}', style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    categoryProvider.clearError();
                    _loadCategories();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Get categories based on selected type
        final categories = _selectedType == 'expense'
            ? categoryProvider.getExpenseCategories()
            : categoryProvider.getIncomeCategories();

        if (categories.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text('No ${_selectedType} categories found'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/categories'),
                  child: const Text('Add Category'),
                ),
              ],
            ),
          );
        }

        // ✅ FIX: Find matching category from the list if editing
        Category? dropdownValue;
        if (_selectedCategory != null) {
          // Try to find a matching category in the current list
          final match = categories.where((c) => c.id == _selectedCategory!.id).toList();
          if (match.isNotEmpty) {
            dropdownValue = match.first;
          } else {
            // Category exists but is of different type (e.g., selected expense category but viewing income)
            dropdownValue = null;
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<Category>(
            value: dropdownValue,
            decoration: const InputDecoration(labelText: 'Category', border: InputBorder.none),
            isExpanded: true,
            hint: const Text('Select a category'),
            items: categories.map((category) {
              return DropdownMenuItem<Category>(
                value: category,
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _parseColor(category.color),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(_getIconData(category.icon), size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(category.name)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedCategory = value),
            validator: (value) => value == null ? 'Please select a category' : null,
          ),
        );
      },
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  Widget _buildRecurringSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Repeat Transaction'),
          subtitle: const Text('Make this a recurring transaction'),
          contentPadding: EdgeInsets.zero,
          value: _isRecurring,
          onChanged: (value) {
            setState(() {
              _isRecurring = value;
              if (!value) _resetRecurringOptions();
            });
          },
        ),
        if (_isRecurring) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<RecurrenceFrequency>(
                  value: _selectedFrequency,
                  decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder()),
                  items: RecurrenceFrequency.values.map((freq) {
                    return DropdownMenuItem(value: freq, child: Text(freq.name.toUpperCase()));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedFrequency = value),
                ),
                const SizedBox(height: 16),
                const Text('End Condition', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('End Date'),
                        value: 'date',
                        groupValue: _endCondition,
                        onChanged: (v) => setState(() => _endCondition = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Count'),
                        value: 'count',
                        groupValue: _endCondition,
                        onChanged: (v) => setState(() => _endCondition = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                if (_endCondition == 'date')
                  ListTile(
                    title: Text(_endDate == null ? 'Select End Date' : DateFormat('yyyy-MM-dd').format(_endDate!)),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now().add(const Duration(days: 365)),
                        firstDate: _selectedDate,
                        lastDate: DateTime(2100),
                      );
                      if (date != null) setState(() => _endDate = date);
                    },
                  ),
                if (_endCondition == 'count')
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Number of Executions', border: OutlineInputBorder()),
                    onChanged: (v) => _totalExecutions = int.tryParse(v),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _resetRecurringOptions() {
    _selectedFrequency = null;
    _endCondition = null;
    _endDate = null;
    _totalExecutions = null;
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              _isEditing ? 'Update Transaction' : 'Add Transaction',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        if (_isEditing) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _isLoading ? null : _showDeleteConfirmation,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Delete Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ],
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTransaction();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction() async {
    if (widget.transaction == null) return;

    setState(() => _isLoading = true);

    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      await transactionProvider.deleteTransaction(widget.transaction!.id);
      if (mounted) Navigator.of(context).pop('deleted');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error: ${e.toString().replaceFirst("Exception: ", "")}');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showErrorSnackBar('Please select a category');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final amount = double.tryParse(_amountController.text) ?? 0.0;

      final transaction = Transaction(
        id: widget.transaction?.id ?? 0,
        type: _selectedType,
        amount: amount,
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        category: _selectedCategory!,
        currency: _selectedCurrency,
      );

      if (_isEditing) {
        await transactionProvider.updateTransaction(transaction);
      } else {
        await transactionProvider.addTransaction(transaction);
      }

      // Handle recurring transaction separately
      if (_isRecurring && _selectedFrequency != null) {
        try {
          final recurringProvider = Provider.of<RecurringTransactionProvider>(context, listen: false);
          final recurringTransaction = RecurringTransaction(
            id: 0,
            type: _selectedType,
            amount: amount,
            description: _descriptionController.text.trim(),
            categoryId: _selectedCategory!.id,
            currency: _selectedCurrency,
            frequency: _selectedFrequency!,
            nextRunDate: _calculateNextRunDate(_selectedDate, _selectedFrequency!),
            endDate: _endDate,
            totalExecutions: _totalExecutions,
            executionCount: 0,
          );
          await recurringProvider.addRecurringTransaction(recurringTransaction);
        } catch (e) {
          debugPrint('Error creating recurring transaction: $e');
        }
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error: ${e.toString().replaceFirst("Exception: ", "")}');
    }
  }

  DateTime _calculateNextRunDate(DateTime fromDate, RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily: return fromDate.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly: return fromDate.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly: return DateTime(fromDate.year, fromDate.month + 1, fromDate.day);
      case RecurrenceFrequency.yearly: return DateTime(fromDate.year + 1, fromDate.month, fromDate.day);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }

  String _getCurrencySymbol(String currency) {
    final option = _currencyOptions.firstWhere((o) => o['value'] == currency, orElse: () => {'symbol': '\$'});
    return option['symbol'] as String;
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'fastfood': return Icons.fastfood;
      case 'directions_car': return Icons.directions_car;
      case 'attach_money': return Icons.attach_money;
      case 'bolt': return Icons.bolt;
      case 'movie': return Icons.movie;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'home': return Icons.home;
      default: return Icons.category;
    }
  }
}