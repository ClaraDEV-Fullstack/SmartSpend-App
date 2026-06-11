import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/recurring_transaction.dart';
import '../../models/category.dart';
import '../../providers/recurring_transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';

class RecurringTransactionFormScreen extends StatefulWidget {
  final RecurringTransaction? recurringTransaction;

  const RecurringTransactionFormScreen({super.key, this.recurringTransaction});

  @override
  State<RecurringTransactionFormScreen> createState() =>
      _RecurringTransactionFormScreenState();
}

class _RecurringTransactionFormScreenState
    extends State<RecurringTransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _type = 'expense';
  Category? _selectedCategory;
  String _currency = 'USD';
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  DateTime _nextRunDate = DateTime.now();
  DateTime? _endDate;
  int? _totalExecutions;
  String _endCondition = 'date';
  bool _isSaving = false;

  bool get _isEditing => widget.recurringTransaction != null;

  @override
  void initState() {
    super.initState();
    final item = widget.recurringTransaction;
    if (item != null) {
      _type = item.type;
      _amountController.text = item.amount.toString();
      _descriptionController.text = item.description;
      _currency = item.currency;
      _frequency = item.frequency;
      _nextRunDate = item.nextRunDate;
      _endDate = item.endDate;
      _totalExecutions = item.totalExecutions;
      _endCondition = item.endDate != null ? 'date' : 'count';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories(type: _type);
      final settings = context.read<SettingsProvider>().settings;
      if (!_isEditing && settings != null) {
        setState(() => _currency = settings.currency);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final provider = context.read<RecurringTransactionProvider>();
    final payload = RecurringTransaction(
      id: widget.recurringTransaction?.id ?? 0,
      type: _type,
      amount: double.parse(_amountController.text.trim()),
      description: _descriptionController.text.trim(),
      categoryId: _selectedCategory!.id,
      currency: _currency,
      frequency: _frequency,
      nextRunDate: _nextRunDate,
      endDate: _endCondition == 'date' ? _endDate : null,
      totalExecutions: _endCondition == 'count' ? _totalExecutions : null,
      executionCount: widget.recurringTransaction?.executionCount ?? 0,
    );

    try {
      if (_isEditing) {
        await provider.updateRecurringTransaction(payload);
      } else {
        await provider.addRecurringTransaction(payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Recurring' : 'New Recurring'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Expense')),
                ButtonSegment(value: 'income', label: Text('Income')),
              ],
              selected: {_type},
              onSelectionChanged: (value) {
                setState(() {
                  _type = value.first;
                  _selectedCategory = null;
                });
                context.read<CategoryProvider>().fetchCategories(type: _type);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount ($_currency)',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Amount is required';
                }
                if (double.tryParse(value.trim()) == null) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildCategoryDropdown(),
            const SizedBox(height: 16),
            DropdownButtonFormField<RecurrenceFrequency>(
              value: _frequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              items: RecurrenceFrequency.values
                  .map(
                    (freq) => DropdownMenuItem(
                      value: freq,
                      child: Text(freq.name.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _frequency = value);
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Next run date'),
              subtitle: Text(DateFormat.yMMMd().format(_nextRunDate)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _nextRunDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (date != null) setState(() => _nextRunDate = date);
              },
            ),
            const SizedBox(height: 8),
            Text('End condition', style: theme.textTheme.titleSmall),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('End date'),
                    value: 'date',
                    groupValue: _endCondition,
                    onChanged: (v) => setState(() => _endCondition = v!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Count'),
                    value: 'count',
                    groupValue: _endCondition,
                    onChanged: (v) => setState(() => _endCondition = v!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            if (_endCondition == 'date')
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _endDate == null
                      ? 'Select end date (optional)'
                      : DateFormat.yMMMd().format(_endDate!),
                ),
                trailing: const Icon(Icons.event),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? _nextRunDate.add(const Duration(days: 365)),
                    firstDate: _nextRunDate,
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => _endDate = date);
                },
              ),
            if (_endCondition == 'count')
              TextFormField(
                keyboardType: TextInputType.number,
                initialValue: _totalExecutions?.toString(),
                decoration: const InputDecoration(
                  labelText: 'Number of executions',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _totalExecutions = int.tryParse(v),
              ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isEditing ? 'Save Changes' : 'Create Recurring'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Consumer<CategoryProvider>(
      builder: (context, provider, _) {
        final categories = _type == 'expense'
            ? provider.getExpenseCategories()
            : provider.getIncomeCategories();

        if (_selectedCategory == null && widget.recurringTransaction != null) {
          try {
            _selectedCategory = categories.firstWhere(
              (c) => c.id == widget.recurringTransaction!.categoryId,
            );
          } catch (_) {}
        }

        return DropdownButtonFormField<Category>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
          ),
          items: categories
              .map(
                (category) => DropdownMenuItem(
                  value: category,
                  child: Text(category.name),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedCategory = value),
        );
      },
    );
  }
}
