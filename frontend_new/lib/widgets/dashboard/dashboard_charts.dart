import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DashboardCharts extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final Map<String, double> categorySpending;
  final String currencySymbol;
  final List<Color> categoryColors;

  const DashboardCharts({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.categorySpending,
    required this.currencySymbol,
    required this.categoryColors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = entries.take(5).toList();

    return Column(
      children: [
        if (totalIncome > 0 || totalExpense > 0)
          _IncomeExpenseBarChart(
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            currencySymbol: currencySymbol,
            theme: theme,
          ),
        if (topEntries.isNotEmpty) ...[
          const SizedBox(height: 16),
          _CategoryPieChart(
            entries: topEntries,
            colors: categoryColors,
            currencySymbol: currencySymbol,
            theme: theme,
          ),
        ],
      ],
    );
  }
}

class _IncomeExpenseBarChart extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final String currencySymbol;
  final ThemeData theme;

  const _IncomeExpenseBarChart({
    required this.totalIncome,
    required this.totalExpense,
    required this.currencySymbol,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = [totalIncome, totalExpense, 1.0].reduce((a, b) => a > b ? a : b) * 1.2;

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final label = value.toInt() == 0 ? 'Inc.' : 'Exp.';
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: totalIncome,
                  color: Colors.green,
                  width: 28,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: totalExpense,
                  color: Colors.red,
                  width: 28,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final List<MapEntry<String, double>> entries;
  final List<Color> colors;
  final String currencySymbol;
  final ThemeData theme;

  const _CategoryPieChart({
    required this.entries,
    required this.colors,
    required this.currencySymbol,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<double>(0, (sum, e) => sum + e.value);

    return Row(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 28,
              sections: List.generate(entries.length, (index) {
                final entry = entries[index];
                final percentage = total == 0 ? 0.0 : (entry.value / total) * 100;
                return PieChartSectionData(
                  value: entry.value,
                  color: colors[index % colors.length],
                  title: '${percentage.toStringAsFixed(0)}%',
                  radius: 42,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.asMap().entries.map((item) {
              final index = item.key;
              final entry = item.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      '$currencySymbol${entry.value.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
