import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';
import 'daos/category_dao.dart';
import 'daos/student_dao.dart';
import 'daos/transaction_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Categories, Students, Transactions],
  daos: [CategoryDao, StudentDao, TransactionDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Bump this when you change the schema.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // Create the categories table
            await m.createTable(categories);

            // Insert a default category for existing students
            await customStatement(
              "INSERT INTO categories (name, description, icon, color, created_at) "
              "VALUES ('Student Expense Tracker', 'Default category for existing students', "
              "'school', ${0xFF6C5CE7}, strftime('%s', 'now'))",
            );

            // Add categoryId column to students table
            await customStatement(
              'ALTER TABLE students ADD COLUMN category_id INTEGER '
              'REFERENCES categories(id) DEFAULT 1',
            );

            // Backfill existing students with the default category (id=1)
            await customStatement(
              'UPDATE students SET category_id = 1 WHERE category_id IS NULL',
            );
          }
        },
      );

  /// Returns the path to the database file (useful for backup).
  static Future<String> get databasePath async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'se_manager.db');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'se_manager.db'));
    return NativeDatabase.createInBackground(file);
  });
}
