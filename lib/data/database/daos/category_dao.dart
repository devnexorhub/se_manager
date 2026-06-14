import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories, Students, Transactions])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// Watch all categories ordered by name.
  Stream<List<Category>> watchAll() {
    return (select(categories)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Get all categories.
  Future<List<Category>> getAll() {
    return (select(categories)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Get a single category by ID.
  Future<Category> getById(int id) {
    return (select(categories)..where((t) => t.id.equals(id))).getSingle();
  }

  /// Search categories by name.
  Stream<List<Category>> watchBySearch(String query) {
    return (select(categories)
          ..where((t) => t.name.like('%$query%'))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Insert a new category, returns the auto-generated ID.
  Future<int> insertCategory(CategoriesCompanion entry) {
    return into(categories).insert(entry);
  }

  /// Update an existing category.
  Future<bool> updateCategory(CategoriesCompanion entry) {
    return update(categories).replace(
      Category(
        id: entry.id.value,
        name: entry.name.value,
        description: entry.description.value,
        icon: entry.icon.value,
        color: entry.color.value,
        createdAt: entry.createdAt.value,
      ),
    );
  }

  /// Delete a category and CASCADE its members + their transactions.
  Future<void> deleteCategory(int id) async {
    // Get all student IDs in this category
    final memberIds = await (selectOnly(students)
          ..addColumns([students.id])
          ..where(students.categoryId.equals(id)))
        .map((row) => row.read(students.id)!)
        .get();

    // Delete transactions for all members
    if (memberIds.isNotEmpty) {
      await (delete(transactions)
            ..where((t) => t.studentId.isIn(memberIds)))
          .go();
    }

    // Delete all members
    await (delete(students)..where((t) => t.categoryId.equals(id))).go();

    // Delete the category
    await (delete(categories)..where((t) => t.id.equals(id))).go();
  }

  /// Count members in a category.
  Future<int> memberCount(int categoryId) async {
    final countExpr = students.id.count();
    final query = selectOnly(students)
      ..addColumns([countExpr])
      ..where(students.categoryId.equals(categoryId));
    final row = await query.getSingle();
    return row.read(countExpr)!;
  }

  /// Total count of categories.
  Future<int> count() async {
    final countExpr = categories.id.count();
    final query = selectOnly(categories)..addColumns([countExpr]);
    final row = await query.getSingle();
    return row.read(countExpr)!;
  }
}
