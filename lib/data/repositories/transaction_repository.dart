import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/daos/transaction_dao.dart';

/// High-level repository for transaction CRUD + aggregation.
class TransactionRepository {
  TransactionRepository({required this.transactionDao});

  final TransactionDao transactionDao;

  // ── Read ────────────────────────────────────────────────────────

  /// Watch all transactions for a student, newest first.
  Stream<List<TransactionEntry>> watchByStudent(int studentId) =>
      transactionDao.watchByStudent(studentId);

  /// Get all transactions for a student.
  Future<List<TransactionEntry>> getByStudent(int studentId) =>
      transactionDao.getByStudent(studentId);

  /// Watch all transactions globally.
  Stream<List<TransactionEntry>> watchAll() => transactionDao.watchAll();

  /// Get all transactions globally.
  Future<List<TransactionEntry>> getAll() => transactionDao.getAll();

  /// Watch transactions filtered by type.
  Stream<List<TransactionEntry>> watchByType(int studentId, String type) =>
      transactionDao.watchByStudentAndType(studentId, type);

  /// Watch transactions filtered by date range.
  Stream<List<TransactionEntry>> watchByDateRange(
    int studentId,
    DateTime from,
    DateTime to,
  ) =>
      transactionDao.watchByStudentAndDateRange(studentId, from, to);

  /// Get the most recent N transactions.
  Future<List<TransactionEntry>> getRecent(int limit) =>
      transactionDao.getRecent(limit);

  // ── Write ───────────────────────────────────────────────────────

  /// Add a new transaction.
  Future<int> add({
    required int studentId,
    required String type,
    required double amount,
    String currency = 'USD',
    String? note,
    DateTime? createdAt,
  }) {
    return transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        studentId: studentId,
        type: type,
        amount: amount,
        currency: Value(currency),
        note: Value(note),
        createdAt: Value(createdAt ?? DateTime.now()),
      ),
    );
  }

  /// Update a transaction.
  Future<bool> update(TransactionEntry entry) =>
      transactionDao.updateTransaction(entry);

  /// Delete a transaction.
  Future<int> delete(int id) => transactionDao.deleteTransaction(id);

  // ── Aggregation ─────────────────────────────────────────────────

  /// Total deposits for a student.
  Future<double> totalDeposits(int studentId) =>
      transactionDao.totalDeposits(studentId);

  /// Total withdrawals for a student.
  Future<double> totalWithdrawals(int studentId) =>
      transactionDao.totalWithdrawals(studentId);

  /// Global total deposits.
  Future<double> globalTotalDeposits() =>
      transactionDao.globalTotalDeposits();

  /// Global total withdrawals.
  Future<double> globalTotalWithdrawals() =>
      transactionDao.globalTotalWithdrawals();

  /// Global net balance.
  Future<double> globalNetBalance() async {
    final deposits = await globalTotalDeposits();
    final withdrawals = await globalTotalWithdrawals();
    return deposits - withdrawals;
  }
}
