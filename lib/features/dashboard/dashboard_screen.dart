import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/app_database.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/student_providers.dart';
import '../../providers/transaction_providers.dart';

/// Dashboard screen with summary cards, mini chart, and recent transactions.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      body: dashAsync.when(
        data: (data) => _DashboardBody(data: data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  BODY
// ═════════════════════════════════════════════════════════════════════════

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recentTxAsync = ref.watch(allTransactionsProvider);

    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 120,
          floating: true,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.dashboardGradient,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back 👋',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.appName,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Summary Cards ───────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              _SummaryCard(
                icon: Icons.people_rounded,
                label: AppStrings.totalStudents,
                value: '${data.totalStudents}',
                gradient: AppColors.primaryGradient,
              ),
              _SummaryCard(
                icon: Icons.account_balance_wallet_rounded,
                label: AppStrings.netBalance,
                value: Formatters.currency(data.netBalance),
                gradient: data.isPositive
                    ? AppColors.depositGradient
                    : AppColors.withdrawalGradient,
              ),
              _SummaryCard(
                icon: Icons.arrow_downward_rounded,
                label: AppStrings.totalDeposits,
                value: Formatters.currency(data.totalDeposits),
                gradient: AppColors.depositGradient,
              ),
              _SummaryCard(
                icon: Icons.arrow_upward_rounded,
                label: AppStrings.totalWithdrawals,
                value: Formatters.currency(data.totalWithdrawals),
                gradient: AppColors.withdrawalGradient,
              ),
            ],
          ),
        ),

        // ── Mini Chart ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: recentTxAsync.when(
            data: (txList) => txList.isEmpty
                ? const SizedBox.shrink()
                : _MiniChart(transactions: txList),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),

        // ── Recent Transactions Header ──────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text(
                  AppStrings.recentTransactions,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/students'),
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
        ),

        // ── Recent Transactions List ────────────────────────────────
        recentTxAsync.when(
          data: (txList) {
            if (txList.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_rounded,
                          size: 64,
                          color: theme.colorScheme.primary.withAlpha(60)),
                      const SizedBox(height: 12),
                      Text(
                        'No transactions yet',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add a student and start recording',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            }

            final recent = txList.take(8).toList();
            return SliverPadding(
              padding: const EdgeInsets.only(bottom: 24),
              sliver: SliverList.builder(
                itemCount: recent.length,
                itemBuilder: (context, index) {
                  final tx = recent[index];
                  return _RecentTxTile(tx: tx);
                },
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SliverToBoxAdapter(
            child: Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  SUMMARY CARD
// ═════════════════════════════════════════════════════════════════════════

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
  });

  final IconData icon;
  final String label;
  final String value;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withAlpha(50),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  MINI CHART (Last 7-Day Activity)
// ═════════════════════════════════════════════════════════════════════════

class _MiniChart extends StatelessWidget {
  const _MiniChart({required this.transactions});

  final List<TransactionEntry> transactions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Group last 7 days
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });

    final depositData = <FlSpot>[];
    final withdrawalData = <FlSpot>[];

    for (int i = 0; i < days.length; i++) {
      final day = days[i];
      final nextDay = day.add(const Duration(days: 1));

      double deposits = 0;
      double withdrawals = 0;

      for (final tx in transactions) {
        if (tx.createdAt.isAfter(day) && tx.createdAt.isBefore(nextDay)) {
          if (tx.type == 'deposit') {
            deposits += tx.amount;
          } else {
            withdrawals += tx.amount;
          }
        }
      }

      depositData.add(FlSpot(i.toDouble(), deposits));
      withdrawalData.add(FlSpot(i.toDouble(), withdrawals));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.dividerDark.withAlpha(80)
              : AppColors.dividerLight.withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Last 7 Days',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _LegendDot(color: AppColors.deposit, label: 'Deposits'),
              const SizedBox(width: 12),
              _LegendDot(color: AppColors.withdrawal, label: 'Withdrawals'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calcInterval(depositData, withdrawalData),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? Colors.white.withAlpha(15)
                        : Colors.black.withAlpha(15),
                    strokeWidth: 1,
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
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= days.length) {
                          return const SizedBox.shrink();
                        }
                        final day = days[idx];
                        final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[day.weekday - 1],
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withAlpha(120),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  _line(depositData, AppColors.deposit),
                  _line(withdrawalData, AppColors.withdrawal),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => isDark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceLight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calcInterval(List<FlSpot> a, List<FlSpot> b) {
    double maxVal = 0;
    for (final s in [...a, ...b]) {
      if (s.y > maxVal) maxVal = s.y;
    }
    if (maxVal <= 0) return 1;
    return (maxVal / 3).ceilToDouble();
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, xPercentage, bar, index) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 0,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withAlpha(30),
      ),
    );
  }
}

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

// ═════════════════════════════════════════════════════════════════════════
//  RECENT TRANSACTION TILE
// ═════════════════════════════════════════════════════════════════════════

class _RecentTxTile extends ConsumerWidget {
  const _RecentTxTile({required this.tx});

  final TransactionEntry tx;

  bool get isDeposit => tx.type == 'deposit';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = isDeposit ? AppColors.deposit : AppColors.withdrawal;
    final studentAsync = ref.watch(studentByIdProvider(tx.studentId));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/students/${tx.studentId}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Icon ─────────────────────────────────────────────
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDeposit
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // ── Details ──────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    studentAsync.when(
                      data: (s) => Text(
                        s.name,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      loading: () => const SizedBox(height: 16),
                      error: (_, _) =>
                          Text('Student #${tx.studentId}',
                              style: theme.textTheme.titleSmall),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.relative(tx.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withAlpha(140),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Amount ───────────────────────────────────────────
              Text(
                '${isDeposit ? '+' : '-'} ${Formatters.currency(tx.amount)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
