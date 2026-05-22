import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'student_providers.dart';
import 'transaction_providers.dart';

/// Aggregated dashboard data — loaded once and refreshed when needed.
final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final studentRepo = ref.watch(studentRepositoryProvider);
  final txRepo = ref.watch(transactionRepositoryProvider);

  final results = await Future.wait([
    studentRepo.count(),                // 0
    txRepo.globalTotalDeposits(),       // 1
    txRepo.globalTotalWithdrawals(),    // 2
    txRepo.getRecent(5),               // 3
  ]);

  return DashboardData(
    totalStudents: results[0] as int,
    totalDeposits: results[1] as double,
    totalWithdrawals: results[2] as double,
    recentTransactions: results[3] as List,
  );
});

/// Immutable snapshot of dashboard data.
class DashboardData {
  const DashboardData({
    required this.totalStudents,
    required this.totalDeposits,
    required this.totalWithdrawals,
    required this.recentTransactions,
  });

  final int totalStudents;
  final double totalDeposits;
  final double totalWithdrawals;
  final List recentTransactions;

  double get netBalance => totalDeposits - totalWithdrawals;
  bool get isPositive => netBalance >= 0;
}
