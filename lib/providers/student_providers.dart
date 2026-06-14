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

/// Watch all students as a stream (auto-updates on DB changes) — global.
final studentsStreamProvider = StreamProvider<List<Student>>((ref) {
  return ref.watch(studentRepositoryProvider).watchAll();
});

/// Watch students in a specific category.
final studentsByCategoryProvider =
    StreamProvider.family<List<Student>, int>((ref, categoryId) {
  return ref.watch(studentRepositoryProvider).watchByCategory(categoryId);
});

/// Search students by name (global).
final studentSearchProvider =
    StreamProvider.family<List<Student>, String>((ref, query) {
  if (query.isEmpty) return ref.watch(studentRepositoryProvider).watchAll();
  return ref.watch(studentRepositoryProvider).searchByName(query);
});

/// Search students by name within a category.
final studentSearchByCategoryProvider = StreamProvider.family<List<Student>,
    ({int categoryId, String query})>((ref, params) {
  if (params.query.isEmpty) {
    return ref
        .watch(studentRepositoryProvider)
        .watchByCategory(params.categoryId);
  }
  return ref
      .watch(studentRepositoryProvider)
      .searchByNameInCategory(params.categoryId, params.query);
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

/// Student count in a specific category.
final studentCountByCategoryProvider =
    FutureProvider.family<int, int>((ref, categoryId) {
  return ref.watch(studentRepositoryProvider).countByCategory(categoryId);
});

// ═══════════════════════════════════════════════════════════════════════
//  SEARCH QUERY STATE
// ═══════════════════════════════════════════════════════════════════════

/// Current search query for the student list.
final studentSearchQueryProvider = StateProvider<String>((ref) => '');
