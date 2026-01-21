// lib/screens/home/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/reports_provider.dart';
import '../../providers/settings_provider.dart';

import '../../models/transaction.dart';
import '../../models/user.dart';

import '../transactions/transactions_screen.dart';
import '../transactions/transaction_form_screen.dart';
import '../categories/categories_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../reports/reports_screen.dart';

import '../../widgets/ai_speed_dial.dart';
import '../../widgets/empty_states/empty_states.dart';
import '../../search/transaction_search_delegate.dart';
import '../../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
      _refreshUserProfile();
    });
  }

  /// Refresh user profile to get latest profile image
  Future<void> _refreshUserProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.getUserProfile();
  }

  /// Get user initials for avatar fallback
  String _getInitials(User? user) {
    if (user == null) return 'U';

    if (user.firstName != null &&
        user.firstName!.isNotEmpty &&
        user.lastName != null &&
        user.lastName!.isNotEmpty) {
      return '${user.firstName![0]}${user.lastName![0]}'.toUpperCase();
    }
    if (user.firstName != null && user.firstName!.isNotEmpty) {
      return user.firstName![0].toUpperCase();
    }
    if (user.username.isNotEmpty) {
      return user.username[0].toUpperCase();
    }
    return 'U';
  }

  // ✅ Navigate to form and handle result
  Future<void> _navigateToTransactionForm({Transaction? transaction}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransactionFormScreen(transaction: transaction),
      ),
    );

    // If result is true, show success snackbar and refresh data
    if (result == true) {
      if (!mounted) return;

      final message = transaction == null
          ? 'Transaction added successfully!'
          : 'Transaction updated successfully!';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartSpend'),
        actions: [
          // 👤 Profile with actual image
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.user;
              final hasProfileImage = user?.profileImageUrl != null &&
                  user!.profileImageUrl!.isNotEmpty;

              return IconButton(
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
                  child: ClipOval(
                    child: hasProfileImage
                        ? CachedNetworkImage(
                      imageUrl: user!.profileImageUrl!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 32,
                        height: 32,
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 32,
                        height: 32,
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        child: Center(
                          child: Text(
                            _getInitials(user),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    )
                        : Container(
                      width: 32,
                      height: 32,
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      child: Center(
                        child: user != null
                            ? Text(
                          _getInitials(user),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        )
                            : Icon(
                          Icons.person,
                          size: 18,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
                tooltip: 'Profile',
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                  if (mounted) {
                    _refreshUserProfile();
                  }
                },
              );
            },
          ),

          // 🔍 Search
          Consumer<TransactionProvider>(
            builder: (context, transactionProvider, child) {
              return IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: TransactionSearchDelegate(
                      transactionProvider.transactions,
                    ),
                  );
                },
              );
            },
          ),

          // 🔄 Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _refreshData();
              _refreshUserProfile();
            },
          ),
        ],
      ),
      floatingActionButton: AiSpeedDial(),
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshData();
          await _refreshUserProfile();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroSection(),
              const SizedBox(height: 16),

              // Balance Overview
              Consumer<TransactionProvider>(
                builder: (context, transactionProvider, child) {
                  final currencies = transactionProvider.transactions
                      .map((t) => t.currency)
                      .toSet()
                      .toList();

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                          AppTheme.lightPurple.withOpacity(0.2),
                          AppTheme.lightGold.withOpacity(0.1),
                        ]
                            : [
                          AppTheme.primaryPurple.withOpacity(0.1),
                          AppTheme.deepGold.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Your Balance',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (currencies.isEmpty)
                          Text(
                            '0.00',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ...currencies.map((currency) {
                          final income = transactionProvider
                              .getIncomeTransactions()
                              .where((t) => t.currency == currency)
                              .fold(0.0, (sum, t) => sum + t.amount);
                          final expense = transactionProvider
                              .getExpenseTransactions()
                              .where((t) => t.currency == currency)
                              .fold(0.0, (sum, t) => sum + t.amount);
                          final balance = income - expense;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              '$currency ${balance.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: balance >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Financial Summary
              Consumer2<TransactionProvider, SettingsProvider>(
                builder: (context, transactionProvider, settingsProvider, child) {
                  if (transactionProvider.transactions.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final totalIncome = transactionProvider.getTotalIncome();
                  final totalExpense = transactionProvider.getTotalExpense();
                  final difference = totalIncome - totalExpense;

                  final currencyCode = settingsProvider.settings?.currency ?? 'USD';
                  final symbol = _getCurrencySymbol(currencyCode);

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 20,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Financial Summary',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(Icons.arrow_downward,
                                            color: Colors.green, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          'Income',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$symbol${totalIncome.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(Icons.arrow_upward,
                                            color: Colors.red, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          'Expense',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$symbol${totalExpense.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: difference >= 0
                                  ? [
                                Colors.green.withOpacity(0.2),
                                Colors.green.withOpacity(0.1),
                              ]
                                  : [
                                Colors.red.withOpacity(0.2),
                                Colors.red.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: difference >= 0
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                difference >= 0
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                color: difference >= 0 ? Colors.green : Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Net: $symbol${difference.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: difference >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Top Spending Categories
              Consumer<TransactionProvider>(
                builder: (context, transactionProvider, child) {
                  if (transactionProvider.transactions.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final Map<String, double> categorySpending = {};
                  for (final transaction in transactionProvider.getExpenseTransactions()) {
                    final categoryName = transaction.category.name;
                    categorySpending[categoryName] =
                        (categorySpending[categoryName] ?? 0) + transaction.amount;
                  }

                  final sortedCategories = categorySpending.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  final topCategories = sortedCategories.take(3).toList();

                  if (topCategories.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.pie_chart_outline,
                              size: 20,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Top Spending Categories',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...topCategories.asMap().entries.map((entry) {
                          final index = entry.key;
                          final categoryEntry = entry.value;
                          final color = _getCategoryColor(categoryEntry.key);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    categoryEntry.key,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Text(
                                  '\$${categoryEntry.value.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Recent Transactions Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                    Icon(
                      Icons.history,
                      size: 20,
                      color: theme.colorScheme.secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Recent Transactions List
              Consumer<TransactionProvider>(
                builder: (context, transactionProvider, child) {
                  if (transactionProvider.isLoading &&
                      transactionProvider.transactions.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (transactionProvider.error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Error loading transactions',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    );
                  }

                  if (transactionProvider.transactions.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: DashboardEmptyState(
                        onAddTransaction: () => _navigateToTransactionForm(),
                      ),
                    );
                  }

                  final sortedTransactions =
                  List<Transaction>.from(transactionProvider.transactions)
                    ..sort((a, b) => b.date.compareTo(a.date));

                  return Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedTransactions.length > 3 ? 3 : sortedTransactions.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 1,
                        color: theme.colorScheme.primary.withOpacity(0.05),
                      ),
                      itemBuilder: (context, index) {
                        final transaction = sortedTransactions[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(int.parse(transaction.category.color
                                      .replaceAll('#', '0xFF'))),
                                  Color(int.parse(transaction.category.color
                                      .replaceAll('#', '0xFF')))
                                      .withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getIconData(transaction.category.icon),
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            transaction.description,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${transaction.category.name} • ${_formatDate(transaction.date)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${transaction.currency} ${transaction.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: transaction.type == 'income'
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: (transaction.type == 'income'
                                      ? Colors.green
                                      : Colors.red)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  transaction.type == 'income'
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: transaction.type == 'income'
                                      ? Colors.green
                                      : Colors.red,
                                  size: 12,
                                ),
                              ),
                            ],
                          ),
                          onTap: () =>
                              _navigateToTransactionForm(transaction: transaction),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // View All Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TransactionsScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('View All Transactions'),
                ),
              ),
              const SizedBox(height: 16),

              // Features Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quick Access',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                    Icon(
                      Icons.dashboard_customize,
                      size: 20,
                      color: theme.colorScheme.secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Features Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _FeatureItem(
                    title: 'Transactions',
                    icon: Icons.receipt_long,
                    color: isDark ? AppTheme.lightPurple : AppTheme.primaryPurple,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TransactionsScreen(),
                      ),
                    ),
                  ),
                  _FeatureItem(
                    title: 'Categories',
                    icon: Icons.category,
                    color: isDark ? AppTheme.lightGold : AppTheme.deepGold,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CategoriesScreen(),
                      ),
                    ),
                  ),
                  _FeatureItem(
                    title: 'Reports',
                    icon: Icons.bar_chart,
                    color: isDark ? AppTheme.lightPurple : AppTheme.darkPurple,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ReportsScreen(),
                      ),
                    ),
                  ),
                  _FeatureItem(
                    title: 'Settings',
                    icon: Icons.settings,
                    color: isDark ? AppTheme.lightGold : AppTheme.darkGold,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Background Image
                CachedNetworkImage(
                  imageUrl: 'https://images.unsplash.com/photo-1554224155-6726b3ff858f?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 220,
                  placeholder: (context, url) => Container(
                    width: double.infinity,
                    height: 220,
                    color: AppTheme.primaryPurple,
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: double.infinity,
                    height: 220,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                // Gradient Overlay
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Smiley Emoji
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.emoji_emotions,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Welcome Message
                      Text(
                        'Welcome, ${authProvider.user?.fullName ?? authProvider.user?.username ?? 'User'}!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(1, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      Text(
                        'Manage your finances efficiently and with ease.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 14,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      // Tagline
                      Text(
                        'Track expenses, save better, and achieve your goals.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _refreshData() async {
    final transactionProvider =
    Provider.of<TransactionProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    await transactionProvider.fetchTransactions();
    await settingsProvider.fetchSettings();
    if (categoryProvider.categories.isEmpty) {
      await categoryProvider.fetchCategories();
    }
    await reportsProvider.fetchReportSummary();
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
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'school':
        return Icons.school;
      case 'flight':
        return Icons.flight;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String categoryName) {
    final hash = categoryName.hashCode;
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.7, 0.5).toColor();
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'CFA':
        return 'CFA';
      case 'JPY':
        return '¥';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      case 'CHF':
        return 'Fr';
      case 'CNY':
        return '¥';
      case 'INR':
        return '₹';
      case 'MXN':
        return '\$';
      case 'BRL':
        return 'R\$';
      case 'ZAR':
        return 'R';
      default:
        return '\$';
    }
  }
}

class _FeatureItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}