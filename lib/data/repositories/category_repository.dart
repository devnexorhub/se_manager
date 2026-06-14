import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/daos/category_dao.dart';
import '../database/daos/transaction_dao.dart';

/// High-level repository for category CRUD + aggregated balance info.
class CategoryRepository {
  CategoryRepository({
    required this.categoryDao,
    required this.transactionDao,
  });

  final CategoryDao categoryDao;
  final TransactionDao transactionDao;

  // ── Read ────────────────────────────────────────────────────────

  /// Watch all categories (sorted by name).
  Stream<List<Category>> watchAll() => categoryDao.watchAll();

  /// Get all categories.
  Future<List<Category>> getAll() => categoryDao.getAll();

  /// Get a single category.
  Future<Category> getById(int id) => categoryDao.getById(id);

  /// Search categories by name.
  Stream<List<Category>> searchByName(String query) =>
      categoryDao.watchBySearch(query);

  /// Total category count.
  Future<int> count() => categoryDao.count();

  /// Member count for a category.
  Future<int> memberCount(int categoryId) =>
      categoryDao.memberCount(categoryId);

  // ── Write ───────────────────────────────────────────────────────

  /// Add a new category. Returns the auto-generated ID.
  Future<int> add({
    required String name,
    String? description,
    String icon = 'folder',
    int color = 0xFF6C5CE7,
  }) {
    return categoryDao.insertCategory(
      CategoriesCompanion.insert(
        name: name,
        description: Value(description),
        icon: Value(icon),
        color: Value(color),
      ),
    );
  }

  /// Update an existing category.
  Future<bool> update({
    required int id,
    required String name,
    String? description,
    required String icon,
    required int color,
    required DateTime createdAt,
  }) {
    return categoryDao.updateCategory(
      CategoriesCompanion(
        id: Value(id),
        name: Value(name),
        description: Value(description),
        icon: Value(icon),
        color: Value(color),
        createdAt: Value(createdAt),
      ),
    );
  }

  /// Delete a category and all associated members + transactions.
  Future<void> delete(int id) => categoryDao.deleteCategory(id);

  // ── Balance Helpers ─────────────────────────────────────────────

  /// Get aggregated balance for all members in a category.
  Future<CategoryBalance> getBalance(int categoryId) async {
    final deposits =
        await transactionDao.totalDepositsByCategory(categoryId);
    final withdrawals =
        await transactionDao.totalWithdrawalsByCategory(categoryId);
    return CategoryBalance(
      totalDeposits: deposits,
      totalWithdrawals: withdrawals,
      currentBalance: deposits - withdrawals,
    );
  }
}

/// Immutable balance snapshot for a category.
class CategoryBalance {
  const CategoryBalance({
    required this.totalDeposits,
    required this.totalWithdrawals,
    required this.currentBalance,
  });

  final double totalDeposits;
  final double totalWithdrawals;
  final double currentBalance;

  bool get isPositive => currentBalance >= 0;
}
