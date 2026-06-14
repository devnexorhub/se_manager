import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../providers/category_providers.dart';
import '../../../providers/student_providers.dart';
import '../../../providers/transaction_providers.dart';
import '../../../providers/dashboard_providers.dart';

/// Category detail screen — shows members within a category + balance header.
class CategoryDetailScreen extends ConsumerStatefulWidget {
  const CategoryDetailScreen({super.key, required this.categoryId});

  final int categoryId;

  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryAsync = ref.watch(categoryByIdProvider(widget.categoryId));

    return categoryAsync.when(
      data: (category) => _buildBody(context, category),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildBody(BuildContext context, Category category) {
    final query = ref.watch(studentSearchQueryProvider);
    final membersAsync = query.isEmpty
        ? ref.watch(studentsByCategoryProvider(widget.categoryId))
        : ref.watch(studentSearchByCategoryProvider(
            (categoryId: widget.categoryId, query: query)));
    final balanceAsync = ref.watch(categoryBalanceProvider(widget.categoryId));
    final catColor = Color(category.color);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: AppStrings.searchMembers,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                    onChanged: (val) =>
                        ref.read(studentSearchQueryProvider.notifier).state =
                            val,
                  )
                : Text(category.name),
            actions: [
              if (_isSearching)
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    setState(() => _isSearching = false);
                    _searchController.clear();
                    ref.read(studentSearchQueryProvider.notifier).state = '';
                  },
                )
              else ...[
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () => setState(() => _isSearching = true),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () =>
                      context.go('/categories/${widget.categoryId}/edit'),
                ),
              ],
            ],
          ),

          // ── Category Balance Card ─────────────────────────────────
          SliverToBoxAdapter(
            child: balanceAsync.when(
              data: (balance) =>
                  _CategoryBalanceCard(balance: balance, color: catColor),
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

          // ── Members Header ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  Text(
                    AppStrings.members,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  ref.watch(categoryMemberCountProvider(widget.categoryId)).when(
                        data: (count) => Text(
                          '$count total',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withAlpha(140),
                                  ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                ],
              ),
            ),
          ),

          // ── Members List ──────────────────────────────────────────
          membersAsync.when(
            data: (members) {
              if (members.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: 64,
                            color: catColor.withAlpha(60)),
                        const SizedBox(height: 12),
                        const Text('No members yet'),
                        const SizedBox(height: 4),
                        Text(
                          'Tap + to add your first member',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.only(bottom: 88),
                sliver: SliverList.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    return _MemberCard(
                      student: members[index],
                      categoryId: widget.categoryId,
                      catColor: catColor,
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

      // ── FAB: Add Member ───────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_member',
        onPressed: () =>
            context.go('/categories/${widget.categoryId}/members/add'),
        child: const Icon(Icons.person_add_rounded),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  CATEGORY BALANCE CARD
// ═════════════════════════════════════════════════════════════════════════

class _CategoryBalanceCard extends StatelessWidget {
  const _CategoryBalanceCard({required this.balance, required this.color});

  final CategoryBalance balance;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withAlpha(180)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            AppStrings.currentBalance,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              Formatters.currency(balance.currentBalance),
              style: theme.textTheme.displayMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
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
              Container(width: 1, height: 40, color: Colors.white24),
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
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
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
//  MEMBER CARD (reused student card styled for category context)
// ═════════════════════════════════════════════════════════════════════════

class _MemberCard extends ConsumerWidget {
  const _MemberCard({
    required this.student,
    required this.categoryId,
    required this.catColor,
  });

  final Student student;
  final int categoryId;
  final Color catColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(studentBalanceProvider(student.id));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dismissible(
      key: ValueKey(student.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(30),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) {
        ref.read(studentRepositoryProvider).delete(student.id);
        ref.invalidate(studentsByCategoryProvider(categoryId));
        ref.invalidate(categoryMemberCountProvider(categoryId));
        ref.invalidate(categoryBalanceProvider(categoryId));
        ref.invalidate(dashboardDataProvider);
        ref.invalidate(allTransactionsProvider);
      },
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              context.go('/categories/$categoryId/members/${student.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ── Avatar ──────────────────────────────────────
                CircleAvatar(
                  radius: 24,
                  backgroundColor: catColor.withAlpha(isDark ? 50 : 30),
                  child: Text(
                    student.name.isNotEmpty
                        ? student.name[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: catColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // ── Info ────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student.contact ?? 'No contact info',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withAlpha(160),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // ── Balance ─────────────────────────────────────
                balanceAsync.when(
                  data: (balance) {
                    final color = balance.isPositive
                        ? AppColors.deposit
                        : AppColors.withdrawal;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.currency(balance.currentBalance),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          balance.isPositive ? 'Balance' : 'Deficit',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color.withAlpha(180),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, _) =>
                      const Icon(Icons.error_outline, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(AppStrings.deleteMember),
            content: Text(
                'Delete "${student.name}" and all their transactions? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(AppStrings.delete),
              ),
            ],
          ),
        ) ??
        false;
  }
}
