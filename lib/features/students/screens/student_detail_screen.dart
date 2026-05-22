import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../providers/student_providers.dart';
import '../../../providers/transaction_providers.dart';

/// Student detail screen showing balance header + transaction history.
class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({super.key, required this.studentId});

  final int studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentByIdProvider(studentId));

    return studentAsync.when(
      data: (student) => _DetailBody(student: student),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  BODY
// ═════════════════════════════════════════════════════════════════════════

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(studentBalanceProvider(student.id));
    final txAsync = ref.watch(studentTransactionsProvider(student.id));
    final typeFilter = ref.watch(transactionTypeFilterProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            title: Text(student.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () =>
                    context.go('/students/${student.id}/edit'),
              ),
            ],
          ),

          // ── Balance Card ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: balanceAsync.when(
              data: (balance) => _BalanceCard(balance: balance),
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error: $e'),
              ),
            ),
          ),

          // ── Filter Chips ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    AppStrings.transactionHistory,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  _FilterChip(
                    label: 'All',
                    selected: typeFilter == null,
                    onTap: () => ref
                        .read(transactionTypeFilterProvider.notifier)
                        .state = null,
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'In',
                    selected: typeFilter == 'deposit',
                    color: AppColors.deposit,
                    onTap: () => ref
                        .read(transactionTypeFilterProvider.notifier)
                        .state = 'deposit',
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'Out',
                    selected: typeFilter == 'withdrawal',
                    color: AppColors.withdrawal,
                    onTap: () => ref
                        .read(transactionTypeFilterProvider.notifier)
                        .state = 'withdrawal',
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Transaction List ─────────────────────────────────────
          txAsync.when(
            data: (txList) {
              final filtered = typeFilter == null
                  ? txList
                  : txList.where((t) => t.type == typeFilter).toList();

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha(60)),
                        const SizedBox(height: 12),
                        const Text('No transactions yet'),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.only(bottom: 88),
                sliver: SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final tx = filtered[index];
                    return _TransactionTile(
                      tx: tx,
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Transaction'),
                            content: const Text(
                                'Are you sure you want to delete this transaction?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text(AppStrings.cancel),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.error),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text(AppStrings.delete),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          ref
                              .read(transactionRepositoryProvider)
                              .delete(tx.id);
                          ref.invalidate(
                              studentTransactionsProvider(student.id));
                          ref.invalidate(
                              studentBalanceProvider(student.id));
                        }
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),

      // ── FAB: Add Transaction ─────────────────────────────────────
      floatingActionButton: SafeArea(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 6,
            shadowColor: AppColors.primary.withAlpha(80),
          ),
          onPressed: () =>
              context.go('/students/${student.id}/transaction/add'),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            'Transaction',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  BALANCE CARD
// ═════════════════════════════════════════════════════════════════════════

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final StudentBalance balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Current Balance ──────────────────────────────────────
          Text(
            AppStrings.currentBalance,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.currency(balance.currentBalance),
            style: theme.textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // ── Deposits / Withdrawals Row ───────────────────────────
          Row(
            children: [
              Expanded(
                child: _BalanceStat(
                  icon: Icons.arrow_downward_rounded,
                  label: AppStrings.totalDeposits,
                  value: Formatters.currency(balance.totalDeposits),
                  color: const Color(0xFF55EFC4),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white24,
              ),
              Expanded(
                child: _BalanceStat(
                  icon: Icons.arrow_upward_rounded,
                  label: AppStrings.totalWithdrawals,
                  value: Formatters.currency(balance.totalWithdrawals),
                  color: const Color(0xFFFF8E8E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  const _BalanceStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white60,
              ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  FILTER CHIP
// ═════════════════════════════════════════════════════════════════════════

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
    final c = color ?? Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
//  TRANSACTION TILE
// ═════════════════════════════════════════════════════════════════════════

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx, required this.onDelete});

  final TransactionEntry tx;
  final VoidCallback onDelete;

  bool get isDeposit => tx.type == 'deposit';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDeposit ? AppColors.deposit : AppColors.withdrawal;

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // handled manually
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Icon ─────────────────────────────────────────
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

              // ── Details ──────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDeposit
                          ? AppStrings.deposit
                          : AppStrings.withdrawal,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx.note?.isNotEmpty == true
                          ? tx.note!
                          : Formatters.dateTime(tx.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withAlpha(140),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // ── Amount ───────────────────────────────────────
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
