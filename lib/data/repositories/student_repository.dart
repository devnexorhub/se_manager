import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/daos/student_dao.dart';
import '../database/daos/transaction_dao.dart';

/// High-level repository for student CRUD + aggregated balance info.
class StudentRepository {
  StudentRepository({required this.studentDao, required this.transactionDao});

  final StudentDao studentDao;
  final TransactionDao transactionDao;

  // ── Read ────────────────────────────────────────────────────────

  /// Watch all students (sorted by name).
  Stream<List<Student>> watchAll() => studentDao.watchAll();

  /// Get all students.
  Future<List<Student>> getAll() => studentDao.getAll();

  /// Get a single student.
  Future<Student> getById(int id) => studentDao.getById(id);

  /// Search students by name.
  Stream<List<Student>> searchByName(String query) =>
      studentDao.watchBySearch(query);

  /// Total student count.
  Future<int> count() => studentDao.count();

  // ── Write ───────────────────────────────────────────────────────

  /// Add a new student. Returns the auto-generated ID.
  Future<int> add({required String name, String? contact}) {
    return studentDao.insertStudent(
      StudentsCompanion.insert(
        name: name,
        contact: Value(contact),
      ),
    );
  }

  /// Update an existing student.
  Future<bool> update({
    required int id,
    required String name,
    String? contact,
    required DateTime createdAt,
  }) {
    return studentDao.updateStudent(
      StudentsCompanion(
        id: Value(id),
        name: Value(name),
        contact: Value(contact),
        createdAt: Value(createdAt),
      ),
    );
  }

  /// Delete a student and all associated transactions.
  Future<void> delete(int id) => studentDao.deleteStudent(id);

  // ── Balance Helpers ─────────────────────────────────────────────

  /// Get balance summary for one student.
  Future<StudentBalance> getBalance(int studentId) async {
    final deposits = await transactionDao.totalDeposits(studentId);
    final withdrawals = await transactionDao.totalWithdrawals(studentId);
    return StudentBalance(
      totalDeposits: deposits,
      totalWithdrawals: withdrawals,
      currentBalance: deposits - withdrawals,
    );
  }
}

/// Immutable balance snapshot for a student.
class StudentBalance {
  const StudentBalance({
    required this.totalDeposits,
    required this.totalWithdrawals,
    required this.currentBalance,
  });

  final double totalDeposits;
  final double totalWithdrawals;
  final double currentBalance;

  bool get isPositive => currentBalance >= 0;
}
