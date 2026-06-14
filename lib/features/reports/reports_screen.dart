import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/enums.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/app_database.dart';
import '../../providers/category_providers.dart';
import '../../providers/student_providers.dart';
import '../../providers/transaction_providers.dart';

/// Reports screen with bar, pie, and line charts plus date-range filtering.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  FilterPeriod _period = FilterPeriod.month;
  int? _selectedCategoryId; // null = all categories

  DateTime get _fromDate {
    final now = DateTime.now();
    return switch (_period) {
      FilterPeriod.week => now.subtract(const Duration(days: 7)),
      FilterPeriod.month => now.subtract(const Duration(days: 30)),
      FilterPeriod.quarter => now.subtract(const Duration(days: 90)),
      FilterPeriod.year => now.subtract(const Duration(days: 365)),
      FilterPeriod.all => DateTime(2020),
    };
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = _selectedCategoryId == null
        ? ref.watch(allTransactionsProvider)
        : ref.watch(categoryTransactionsProvider(_selectedCategoryId!));
    final studentsAsync = ref.watch(studentsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.reports)),
      body: txAsync.when(
        data: (allTx) {
          // Filter by period
          final transactions = allTx
              .where((t) => t.createdAt.isAfter(_fromDate))
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Category Filter ─────────────────────────────
                categoriesAsync.when(
                  data: (categories) {
                    if (categories.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _CategoryChip(
                              label: AppStrings.allCategories,
                              selected: _selectedCategoryId == null,
                              onTap: () => setState(
                                  () => _selectedCategoryId = null),
                            ),
                            const SizedBox(width: 8),
                            ...categories.map((cat) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _CategoryChip(
                                    label: cat.name,
                                    selected:
                                        _selectedCategoryId == cat.id,
                                    color: Color(cat.color),
                                    onTap: () => setState(
                                        () => _selectedCategoryId = cat.id),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),

                // ── Period Selector ──────────────────────────────
                _PeriodSelector(
                  selected: _period,
                  onChanged: (p) => setState(() => _period = p),
                ),
                const SizedBox(height: 8),

                if (transactions.isEmpty) ...[
                  _buildEmpty(context),
                ] else ...[
                  // ── Bar Chart ────────────────────────────────────
                  _SectionTitle(title: 'Deposits vs Withdrawals'),
                  _BarChartWidget(transactions: transactions),

                  // ── Pie Chart ────────────────────────────────────
                  _SectionTitle(title: 'Top Members by Deposits'),
                  studentsAsync.when(
                    data: (students) => _PieChartWidget(
                      transactions: transactions,
                      students: students,
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const SizedBox.shrink(),
                  ),

                  // ── Line Chart ───────────────────────────────────
                  _SectionTitle(title: 'Balance Trend'),
                  _LineChartWidget(
                    transactions: transactions,
                    period: _period,
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withAlpha(60)),
            const SizedBox(height: 16),
            Text('No data for this period',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Add some transactions to see reports',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  CATEGORY CHIP
// ═════════════════════════════════════════════════════════════════════════

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c : Colors.grey.withAlpha(60),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? c : null,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  SECTION TITLE
// ═════════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  PERIOD SELECTOR
// ═════════════════════════════════════════════════════════════════════════

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});

  final FilterPeriod selected;
  final ValueChanged<FilterPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: FilterPeriod.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final period = FilterPeriod.values[index];
          final isSelected = period == selected;
          return ChoiceChip(
            label: Text(period.label),
            selected: isSelected,
            onSelected: (_) => onChanged(period),
            selectedColor: AppColors.primary.withAlpha(30),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primary : null,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            side: BorderSide(
              color: isSelected ? AppColors.primary : Colors.grey.withAlpha(60),
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  BAR CHART — Monthly Deposits vs Withdrawals
// ═════════════════════════════════════════════════════════════════════════

class _BarChartWidget extends StatelessWidget {
  const _BarChartWidget({required this.transactions});

  final List<TransactionEntry> transactions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Group by month
    final Map<String, double> depositsMap = {};
    final Map<String, double> withdrawalsMap = {};

    for (final tx in transactions) {
      final key = '${tx.createdAt.year}-${tx.createdAt.month.toString().padLeft(2, '0')}';
      if (tx.type == 'deposit') {
        depositsMap[key] = (depositsMap[key] ?? 0) + tx.amount;
      } else {
        withdrawalsMap[key] = (withdrawalsMap[key] ?? 0) + tx.amount;
      }
    }

    final months = {...depositsMap.keys, ...withdrawalsMap.keys}.toList()..sort();
    final lastMonths = months.length > 6 ? months.sublist(months.length - 6) : months;

    if (lastMonths.isEmpty) return const SizedBox.shrink();

    final monthLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? AppColors.dividerDark : AppColors.dividerLight)
              .withAlpha(80),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _LegendDot(color: AppColors.deposit, label: 'Deposits'),
              const SizedBox(width: 12),
              _LegendDot(color: AppColors.withdrawal, label: 'Withdrawals'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => isDark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceLight,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= lastMonths.length) {
                          return const SizedBox.shrink();
                        }
                        final monthNum = int.parse(lastMonths[idx].split('-')[1]);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            monthLabels[monthNum - 1],
                            style: theme.textTheme.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(lastMonths.length, (i) {
                  final key = lastMonths[i];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: depositsMap[key] ?? 0,
                        color: AppColors.deposit,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                      BarChartRodData(
                        toY: withdrawalsMap[key] ?? 0,
                        color: AppColors.withdrawal,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  PIE CHART — Top Students by Deposits
// ═════════════════════════════════════════════════════════════════════════

class _PieChartWidget extends StatelessWidget {
  const _PieChartWidget({
    required this.transactions,
    required this.students,
  });

  final List<TransactionEntry> transactions;
  final List<Student> students;

  static const _pieColors = [
    Color(0xFF6C5CE7),
    Color(0xFF00CEC9),
    Color(0xFFFDAA5E),
    Color(0xFFFF6B6B),
    Color(0xFF74B9FF),
    Color(0xFF55EFC4),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Sum deposits per student
    final Map<int, double> depositsByStudent = {};
    for (final tx in transactions) {
      if (tx.type == 'deposit') {
        depositsByStudent[tx.studentId] =
            (depositsByStudent[tx.studentId] ?? 0) + tx.amount;
      }
    }

    if (depositsByStudent.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text('No deposit data', style: theme.textTheme.bodyMedium)),
      );
    }

    // Sort and take top 5
    final sorted = depositsByStudent.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final total = top.fold<double>(0, (s, e) => s + e.value);

    // Build name lookup
    final nameMap = {for (final s in students) s.id: s.name};

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? AppColors.dividerDark : AppColors.dividerLight)
              .withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          // ── Pie ────────────────────────────────────────────────
          SizedBox(
            width: 140,
            height: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: List.generate(top.length, (i) {
                  final pct = (top[i].value / total) * 100;
                  return PieChartSectionData(
                    value: top[i].value,
                    color: _pieColors[i % _pieColors.length],
                    radius: 40,
                    title: '${pct.toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 20),

          // ── Legend ─────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(top.length, (i) {
                final name = nameMap[top[i].key] ?? 'Unknown';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _pieColors[i % _pieColors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        Formatters.currencyCompact(top[i].value),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  LINE CHART — Balance Trend
// ═════════════════════════════════════════════════════════════════════════

class _LineChartWidget extends StatelessWidget {
  const _LineChartWidget({
    required this.transactions,
    required this.period,
  });

  final List<TransactionEntry> transactions;
  final FilterPeriod period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (transactions.isEmpty) return const SizedBox.shrink();

    // Sort oldest → newest
    final sorted = [...transactions]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Build cumulative balance spots
    double balance = 0;
    final spots = <FlSpot>[];
    for (int i = 0; i < sorted.length; i++) {
      final tx = sorted[i];
      balance += tx.type == 'deposit' ? tx.amount : -tx.amount;
      spots.add(FlSpot(i.toDouble(), balance));
    }

    final maxY = spots.map((s) => s.y).reduce(max);
    final minY = spots.map((s) => s.y).reduce(min);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? AppColors.dividerDark : AppColors.dividerLight)
              .withAlpha(80),
        ),
      ),
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: isDark
                    ? Colors.white.withAlpha(15)
                    : Colors.black.withAlpha(15),
                strokeWidth: 1,
              ),
            ),
            titlesData: const FlTitlesData(
              topTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minY: minY < 0 ? minY * 1.1 : 0,
            maxY: maxY * 1.1,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.primary,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withAlpha(40),
                      AppColors.primary.withAlpha(5),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => isDark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceLight,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    return LineTooltipItem(
                      Formatters.currency(spot.y),
                      TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  LEGEND DOT (shared)
// ═════════════════════════════════════════════════════════════════════════

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color
                    ?.withAlpha(140),
              ),
        ),
      ],
    );
  }
}
