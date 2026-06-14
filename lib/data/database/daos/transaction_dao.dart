import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions, Students])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  /// Watch all transactions for a student, newest first.
  Stream<List<TransactionEntry>> watchByStudent(int studentId) {
    return (select(transactions)
          ..where((t) => t.studentId.equals(studentId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Get all transactions for a student.
  Future<List<TransactionEntry>> getByStudent(int studentId) {
    return (select(transactions)
          ..where((t) => t.studentId.equals(studentId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Watch all transactions (global), newest first.
  Stream<List<TransactionEntry>> watchAll() {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Get all transactions.
  Future<List<TransactionEntry>> getAll() {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Watch transactions for all students in a specific category.
  Stream<List<TransactionEntry>> watchByCategory(int categoryId) {
    final studentIds = selectOnly(students)
      ..addColumns([students.id])
      ..where(students.categoryId.equals(categoryId));

    return (select(transactions)
          ..where((t) => t.studentId.isInQuery(studentIds))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Filter transactions by type for a student.
  Stream<List<TransactionEntry>> watchByStudentAndType(
    int studentId,
    String type,
  ) {
    return (select(transactions)
          ..where(
              (t) => t.studentId.equals(studentId) & t.type.equals(type))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Filter transactions by date range for a student.
  Stream<List<TransactionEntry>> watchByStudentAndDateRange(
    int studentId,
    DateTime from,
    DateTime to,
  ) {
    return (select(transactions)
          ..where((t) =>
              t.studentId.equals(studentId) &
              t.createdAt.isBiggerOrEqualValue(from) &
              t.createdAt.isSmallerOrEqualValue(to))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Insert a new transaction.
  Future<int> insertTransaction(TransactionsCompanion entry) {
    return into(transactions).insert(entry);
  }

  /// Update a transaction.
  Future<bool> updateTransaction(TransactionEntry entry) {
    return update(transactions).replace(entry);
  }

  /// Delete a transaction by ID.
  Future<int> deleteTransaction(int id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  /// Sum of deposits for a student.
  Future<double> totalDeposits(int studentId) async {
    final sum = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..addColumns([sum])
      ..where(transactions.studentId.equals(studentId) &
          transactions.type.equals('deposit'));
    final row = await query.getSingle();
    return row.read(sum) ?? 0.0;
  }

  /// Sum of withdrawals for a student.
  Future<double> totalWithdrawals(int studentId) async {
    final sum = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..addColumns([sum])
      ..where(transactions.studentId.equals(studentId) &
          transactions.type.equals('withdrawal'));
    final row = await query.getSingle();
    return row.read(sum) ?? 0.0;
  }

  /// Global total deposits (all students).
  Future<double> globalTotalDeposits() async {
    final sum = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..addColumns([sum])
      ..where(transactions.type.equals('deposit'));
    final row = await query.getSingle();
    return row.read(sum) ?? 0.0;
  }

  /// Global total withdrawals (all students).
  Future<double> globalTotalWithdrawals() async {
    final sum = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..addColumns([sum])
      ..where(transactions.type.equals('withdrawal'));
    final row = await query.getSingle();
    return row.read(sum) ?? 0.0;
  }

  /// Total deposits for all students in a category.
  Future<double> totalDepositsByCategory(int categoryId) async {
    final sum = transactions.amount.sum();
    final query = selectOnly(transactions).join([
      innerJoin(students, students.id.equalsExp(transactions.studentId)),
    ])
      ..addColumns([sum])
      ..where(students.categoryId.equals(categoryId) &
          transactions.type.equals('deposit'));
    final row = await query.getSingle();
    return row.read(sum) ?? 0.0;
  }

  /// Total withdrawals for all students in a category.
  Future<double> totalWithdrawalsByCategory(int categoryId) async {
    final sum = transactions.amount.sum();
    final query = selectOnly(transactions).join([
      innerJoin(students, students.id.equalsExp(transactions.studentId)),
    ])
      ..addColumns([sum])
      ..where(students.categoryId.equals(categoryId) &
          transactions.type.equals('withdrawal'));
    final row = await query.getSingle();
    return row.read(sum) ?? 0.0;
  }

  /// Recent N transactions globally.
  Future<List<TransactionEntry>> getRecent(int limit) {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Recent N transactions for a category.
  Future<List<TransactionEntry>> getRecentByCategory(
      int categoryId, int limit) {
    final studentIds = selectOnly(students)
      ..addColumns([students.id])
      ..where(students.categoryId.equals(categoryId));

    return (select(transactions)
          ..where((t) => t.studentId.isInQuery(studentIds))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }
}
