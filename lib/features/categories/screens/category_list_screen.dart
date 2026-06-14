import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/app_database.dart';

import '../../../providers/category_providers.dart';
import '../../../providers/dashboard_providers.dart';

/// Category list screen showing all custom categories with balance info.
class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(categorySearchQueryProvider);
    final categoriesAsync = query.isEmpty
        ? ref.watch(categoriesStreamProvider)
        : ref.watch(categorySearchProvider(query));

    return Scaffold(
      appBar: _isSearching ? _searchAppBar(context) : _normalAppBar(context),
      body: categoriesAsync.when(
        data: (categories) => categories.isEmpty
            ? _buildEmpty(context)
            : _buildGrid(context, categories),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_category',
        onPressed: () => context.go('/categories/add'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  // ── App Bars ──────────────────────────────────────────────────────

  PreferredSizeWidget _normalAppBar(BuildContext context) {
    return AppBar(
      title: const Text(AppStrings.categories),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () => setState(() => _isSearching = true),
        ),
      ],
    );
  }

  PreferredSizeWidget _searchAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () {
          setState(() => _isSearching = false);
          _searchController.clear();
          ref.read(categorySearchQueryProvider.notifier).state = '';
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: AppStrings.searchCategories,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
        onChanged: (val) =>
            ref.read(categorySearchQueryProvider.notifier).state = val,
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () {
              _searchController.clear();
              ref.read(categorySearchQueryProvider.notifier).state = '';
            },
          ),
      ],
    );
  }

  // ── Empty State ───────────────────────────────────────────────────

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.category_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withAlpha(80)),
          const SizedBox(height: 16),
          Text(
            'No categories yet',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first category',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
          ),
        ],
      ),
    );
  }

  // ── Category Grid ────────────────────────────────────────────────

  Widget _buildGrid(BuildContext context, List<Category> categories) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return _CategoryCard(category: categories[index]);
          },
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  CATEGORY CARD
// ═════════════════════════════════════════════════════════════════════════

/// Icon mapping from stored string to IconData.
IconData getCategoryIcon(String iconName) {
  const iconMap = <String, IconData>{
    'folder': Icons.folder_rounded,
    'school': Icons.school_rounded,
    'business': Icons.business_rounded,
    'home': Icons.home_rounded,
    'group': Icons.group_rounded,
    'sports': Icons.sports_rounded,
    'restaurant': Icons.restaurant_rounded,
    'shopping': Icons.shopping_cart_rounded,
    'travel': Icons.flight_rounded,
    'health': Icons.health_and_safety_rounded,
    'music': Icons.music_note_rounded,
    'code': Icons.code_rounded,
    'star': Icons.star_rounded,
    'pets': Icons.pets_rounded,
    'church': Icons.church_rounded,
    'volunteer': Icons.volunteer_activism_rounded,
  };
  return iconMap[iconName] ?? Icons.folder_rounded;
}

class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(categoryBalanceProvider(category.id));
    final memberCountAsync =
        ref.watch(categoryMemberCountProvider(category.id));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catColor = Color(category.color);

    return GestureDetector(
      onTap: () => context.go('/categories/${category.id}'),
      onLongPress: () => _showOptions(context, ref),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: catColor.withAlpha(isDark ? 60 : 40),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: catColor.withAlpha(isDark ? 20 : 15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icon + Menu ───────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: catColor.withAlpha(isDark ? 50 : 30),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    getCategoryIcon(category.icon),
                    color: catColor,
                    size: 24,
                  ),
                ),
                const Spacer(),
                memberCountAsync.when(
                  data: (count) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withAlpha(isDark ? 40 : 20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: catColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
            const Spacer(),

            // ── Name ──────────────────────────────────────────────
            Text(
              category.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (category.description != null &&
                category.description!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                category.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withAlpha(140),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),

            // ── Balance ───────────────────────────────────────────
            balanceAsync.when(
              data: (balance) {
                final color =
                    balance.isPositive ? AppColors.deposit : AppColors.withdrawal;
                return Row(
                  children: [
                    Icon(
                      balance.isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: color,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          Formatters.currency(balance.currentBalance),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, _) =>
                  const Icon(Icons.error_outline, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              category.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text(AppStrings.editCategory),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/categories/${category.id}/edit');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_rounded, color: AppColors.error),
              title: const Text(
                AppStrings.deleteCategory,
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await _confirmDelete(context);
                if (confirm) {
                  ref
                      .read(categoryRepositoryProvider)
                      .delete(category.id);
                  ref.invalidate(categoriesStreamProvider);
                  ref.invalidate(categoryCountProvider);
                  ref.invalidate(dashboardDataProvider);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(AppStrings.deleteCategory),
            content: Text(
                'Delete "${category.name}" and all its members and transactions? '
                'This cannot be undone.'),
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
