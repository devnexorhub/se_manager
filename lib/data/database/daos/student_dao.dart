import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'student_dao.g.dart';

@DriftAccessor(tables: [Students, Transactions])
class StudentDao extends DatabaseAccessor<AppDatabase>
    with _$StudentDaoMixin {
  StudentDao(super.db);

  /// Watch all students ordered by name.
  Stream<List<Student>> watchAll() {
    return (select(students)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Get all students.
  Future<List<Student>> getAll() {
    return (select(students)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Get a single student by ID.
  Future<Student> getById(int id) {
    return (select(students)..where((t) => t.id.equals(id))).getSingle();
  }

  /// Search students by name.
  Stream<List<Student>> watchBySearch(String query) {
    return (select(students)
          ..where((t) => t.name.like('%$query%'))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Insert a new student, returns the auto-generated ID.
  Future<int> insertStudent(StudentsCompanion entry) {
    return into(students).insert(entry);
  }

  /// Update an existing student.
  Future<bool> updateStudent(StudentsCompanion entry) {
    return update(students).replace(
      Student(
        id: entry.id.value,
        name: entry.name.value,
        contact: entry.contact.value,
        createdAt: entry.createdAt.value,
      ),
    );
  }

  /// Delete a student and CASCADE their transactions.
  Future<void> deleteStudent(int id) async {
    // Delete transactions first  
    await (delete(transactions)..where((t) => t.studentId.equals(id))).go();
    await (delete(students)..where((t) => t.id.equals(id))).go();
  }

  /// Count total students.
  Future<int> count() async {
    final countExpr = students.id.count();
    final query = selectOnly(students)..addColumns([countExpr]);
    final row = await query.getSingle();
    return row.read(countExpr)!;
  }
}
