import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/repositories/category_repository.dart';
import 'app_providers.dart';

// ═══════════════════════════════════════════════════════════════════════
//  REPOSITORY
// ═══════════════════════════════════════════════════════════════════════

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(
    categoryDao: ref.watch(categoryDaoProvider),
    transactionDao: ref.watch(transactionDaoProvider),
  );
});

// ═══════════════════════════════════════════════════════════════════════
//  STREAMS / FUTURES
// ═══════════════════════════════════════════════════════════════════════

/// Watch all categories as a stream (auto-updates on DB changes).
final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAll();
});

/// Search categories by name.
final categorySearchProvider =
    StreamProvider.family<List<Category>, String>((ref, query) {
  if (query.isEmpty) return ref.watch(categoryRepositoryProvider).watchAll();
  return ref.watch(categoryRepositoryProvider).searchByName(query);
});

/// Get a single category by ID.
final categoryByIdProvider =
    FutureProvider.family<Category, int>((ref, id) {
  return ref.watch(categoryRepositoryProvider).getById(id);
});

/// Balance for a specific category.
final categoryBalanceProvider =
    FutureProvider.family<CategoryBalance, int>((ref, categoryId) {
  return ref.watch(categoryRepositoryProvider).getBalance(categoryId);
});

/// Member count for a specific category.
final categoryMemberCountProvider =
    FutureProvider.family<int, int>((ref, categoryId) {
  return ref.watch(categoryRepositoryProvider).memberCount(categoryId);
});

/// Total category count.
final categoryCountProvider = FutureProvider<int>((ref) {
  return ref.watch(categoryRepositoryProvider).count();
});

// ═══════════════════════════════════════════════════════════════════════
//  SEARCH QUERY STATE
// ═══════════════════════════════════════════════════════════════════════

/// Current search query for the category list.
final categorySearchQueryProvider = StateProvider<String>((ref) => '');
