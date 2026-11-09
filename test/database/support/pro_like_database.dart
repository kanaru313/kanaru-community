import 'package:drift/drift.dart';
import 'package:kanaru/src/database/tables.dart';

import 'pro_like_database.drift.dart';

/// A Pro-style table with a foreign key into `tracks`.
class ProLikeNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.restrict)();
  TextColumn get body => text()();
}

/// Stand-in for the Pro database: lists public tables it joins, owns one
/// table, and opens on the connection of an already open `AppDatabase`.
@DriftDatabase(tables: [Tracks, Sources, ProLikeNotes])
class ProLikeDatabase extends $ProLikeDatabase {
  ProLikeDatabase.connect(DatabaseConnection super.connection);

  @override
  int get schemaVersion => 1;

  /// Tripwire: the public database already created the shared tables, so
  /// this database must never run a create or upgrade of its own.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async =>
            throw StateError('ProLikeDatabase must not create tables'),
        onUpgrade: (m, from, to) async =>
            throw StateError('ProLikeDatabase must not migrate tables'),
      );

  /// Creates the one table this database owns, by hand.
  Future<void> createOwnTables() => createMigrator().createTable(proLikeNotes);
}
