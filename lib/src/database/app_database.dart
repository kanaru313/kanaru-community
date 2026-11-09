import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'app_database.drift.dart';
import 'tables.dart';

/// The one database of the app. It owns `schemaVersion`; tables of extensions
/// live in their own drift databases opened on the same connection.
@DriftDatabase(tables: [ExtensionSchema])
class AppDatabase extends $AppDatabase {
  AppDatabase(super.executor);

  /// Opens (or creates) the database file on the calling isolate. A
  /// background isolate (`createInBackground`) waits until sharing its
  /// connection with extension databases is proven.
  factory AppDatabase.file(File file) => AppDatabase(NativeDatabase(file));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
