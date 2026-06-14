import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/repositories/transaction_repository.dart';
import 'app_providers.dart';

// ═══════════════════════════════════════════════════════════════════════
//  REPOSITORY
// ═══════════════════════════════════════════════════════════════════════

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(
    transactionDao: ref.watch(transactionDaoProvider),
  );
});

// ═══════════════════════════════════════════════════════════════════════
//  STREAMS / FUTURES
// ═══════════════════════════════════════════════════════════════════════

/// Watch all transactions for a specific student.
final studentTransactionsProvider =
    StreamProvider.family<List<TransactionEntry>, int>((ref, studentId) {
  return ref.watch(transactionRepositoryProvider).watchByStudent(studentId);
});

/// Watch all transactions globally.
final allTransactionsProvider = StreamProvider<List<TransactionEntry>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchAll();
});

/// Watch all transactions for a specific category.
final categoryTransactionsProvider =
    StreamProvider.family<List<TransactionEntry>, int>((ref, categoryId) {
  return ref.watch(transactionRepositoryProvider).watchByCategory(categoryId);
});

/// Most recent N transactions.
final recentTransactionsProvider =
    FutureProvider.family<List<TransactionEntry>, int>((ref, limit) {
  return ref.watch(transactionRepositoryProvider).getRecent(limit);
});

/// Filter transactions by type for a given student.
final filteredByTypeProvider = StreamProvider.family<List<TransactionEntry>,
    ({int studentId, String type})>((ref, params) {
  return ref
      .watch(transactionRepositoryProvider)
      .watchByType(params.studentId, params.type);
});

/// Filter transactions by date range for a given student.
final filteredByDateRangeProvider = StreamProvider.family<
    List<TransactionEntry>,
    ({int studentId, DateTime from, DateTime to})>((ref, params) {
  return ref
      .watch(transactionRepositoryProvider)
      .watchByDateRange(params.studentId, params.from, params.to);
});

// ═══════════════════════════════════════════════════════════════════════
//  GLOBAL AGGREGATED DATA
// ═══════════════════════════════════════════════════════════════════════

/// Global total deposits.
final globalDepositsProvider = FutureProvider<double>((ref) {
  return ref.watch(transactionRepositoryProvider).globalTotalDeposits();
});

/// Global total withdrawals.
final globalWithdrawalsProvider = FutureProvider<double>((ref) {
  return ref.watch(transactionRepositoryProvider).globalTotalWithdrawals();
});

/// Global net balance.
final globalNetBalanceProvider = FutureProvider<double>((ref) {
  return ref.watch(transactionRepositoryProvider).globalNetBalance();
});

// ═══════════════════════════════════════════════════════════════════════
//  CATEGORY-SCOPED AGGREGATED DATA
// ═══════════════════════════════════════════════════════════════════════

/// Category total deposits.
final categoryDepositsProvider =
    FutureProvider.family<double, int>((ref, categoryId) {
  return ref
      .watch(transactionRepositoryProvider)
      .totalDepositsByCategory(categoryId);
});

/// Category total withdrawals.
final categoryWithdrawalsProvider =
    FutureProvider.family<double, int>((ref, categoryId) {
  return ref
      .watch(transactionRepositoryProvider)
      .totalWithdrawalsByCategory(categoryId);
});

// ═══════════════════════════════════════════════════════════════════════
//  FILTER STATE (used by transaction lists)
// ═══════════════════════════════════════════════════════════════════════

/// Selected transaction type filter (null = show all).
final transactionTypeFilterProvider = StateProvider<String?>((ref) => null);

/// Selected date range filter.
final transactionDateRangeProvider =
    StateProvider<({DateTime from, DateTime to})?>((ref) => null);
