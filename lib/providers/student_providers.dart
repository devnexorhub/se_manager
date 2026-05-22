import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/repositories/student_repository.dart';
import 'app_providers.dart';

// ═══════════════════════════════════════════════════════════════════════
//  REPOSITORY
// ═══════════════════════════════════════════════════════════════════════

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(
    studentDao: ref.watch(studentDaoProvider),
    transactionDao: ref.watch(transactionDaoProvider),
  );
});

// ═══════════════════════════════════════════════════════════════════════
//  STREAMS / FUTURES
// ═══════════════════════════════════════════════════════════════════════

/// Watch all students as a stream (auto-updates on DB changes).
final studentsStreamProvider = StreamProvider<List<Student>>((ref) {
  return ref.watch(studentRepositoryProvider).watchAll();
});

/// Search students by name.
final studentSearchProvider =
    StreamProvider.family<List<Student>, String>((ref, query) {
  if (query.isEmpty) return ref.watch(studentRepositoryProvider).watchAll();
  return ref.watch(studentRepositoryProvider).searchByName(query);
});

/// Get a single student by ID.
final studentByIdProvider =
    FutureProvider.family<Student, int>((ref, id) {
  return ref.watch(studentRepositoryProvider).getById(id);
});

/// Balance for a specific student.
final studentBalanceProvider =
    FutureProvider.family<StudentBalance, int>((ref, studentId) {
  return ref.watch(studentRepositoryProvider).getBalance(studentId);
});

/// Total student count.
final studentCountProvider = FutureProvider<int>((ref) {
  return ref.watch(studentRepositoryProvider).count();
});

// ═══════════════════════════════════════════════════════════════════════
//  SEARCH QUERY STATE
// ═══════════════════════════════════════════════════════════════════════

/// Current search query for the student list.
final studentSearchQueryProvider = StateProvider<String>((ref) => '');
