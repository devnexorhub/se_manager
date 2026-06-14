import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'category_providers.dart';
import 'student_providers.dart';
import 'transaction_providers.dart';

// ═══════════════════════════════════════════════════════════════════════
//  DASHBOARD DATA
// ═══════════════════════════════════════════════════════════════════════

/// Aggregated dashboard data — reactively updates when transactions change.
final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  // Watch the transaction stream so we re-compute whenever the table changes.
  ref.watch(allTransactionsProvider);

  // Also re-compute when the student list or categories change.
  ref.watch(studentsStreamProvider);
  ref.watch(categoriesStreamProvider);

  final studentRepo = ref.watch(studentRepositoryProvider);
  final txRepo = ref.watch(transactionRepositoryProvider);
  final catRepo = ref.watch(categoryRepositoryProvider);

  // ── Grand total across all categories ───────────────────────
  final results = await Future.wait([
    studentRepo.count(),                // 0
    txRepo.globalTotalDeposits(),       // 1
    txRepo.globalTotalWithdrawals(),    // 2
    txRepo.getRecent(5),               // 3
    catRepo.count(),                    // 4
  ]);

  return DashboardData(
    totalStudents: results[0] as int,
    totalDeposits: results[1] as double,
    totalWithdrawals: results[2] as double,
    recentTransactions: results[3] as List,
    totalCategories: results[4] as int,
  );
});

/// Immutable snapshot of dashboard data.
class DashboardData {
  const DashboardData({
    required this.totalStudents,
    required this.totalDeposits,
    required this.totalWithdrawals,
    required this.recentTransactions,
    required this.totalCategories,
  });

  final int totalStudents;
  final double totalDeposits;
  final double totalWithdrawals;
  final List recentTransactions;
  final int totalCategories;

  double get netBalance => totalDeposits - totalWithdrawals;
  bool get isPositive => netBalance >= 0;
}
