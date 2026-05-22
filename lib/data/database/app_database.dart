import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';
import 'daos/student_dao.dart';
import 'daos/transaction_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Students, Transactions],
  daos: [StudentDao, TransactionDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Bump this when you change the schema.
  @override
  int get schemaVersion => 1;

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
