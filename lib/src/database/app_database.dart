import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:sqlite3/common.dart' show CommonDatabase;

import 'app_database.drift.dart';
import 'schema_guard.dart';
import 'tables.dart';

/// Per-connection settings every Kanaru database connection needs: foreign
/// keys enforced and triggers firing recursively. Extensions open on
/// `AppDatabase.openedConnection()`, never on an executor of their own. Pass it
/// as `NativeDatabase(setup:)` / `createInBackground(setup:)`; [AppDatabase]
/// runs the same pragmas again when it opens, so a connection created
/// elsewhere is covered too.
void configureConnection(CommonDatabase db) {
  db
    ..execute('PRAGMA foreign_keys = ON')
    ..execute('PRAGMA recursive_triggers = ON');
}

/// The one database of the app. It owns `schemaVersion`; tables of extensions
/// live in their own drift databases opened on the same connection.
@DriftDatabase(
  tables: [
    ExtensionSchema,
    Sources,
    SourceMounts,
    ExcludedFolders,
    Tracks,
    TrackDetails,
    TrackArtists,
    CoverColors,
    PlayLog,
    PlayStats,
    QueueEntries,
    Playlists,
    PlaylistEntries,
    SavedItems,
  ],
  include: {'tables/library_track_search.drift', 'tables/playback_stats.drift'},
)
class AppDatabase extends $AppDatabase {
  AppDatabase(QueryExecutor executor) : this._(executor, isReference: false);

  AppDatabase._(super.executor, {required bool isReference})
    : _isReferenceDatabase = isReference;

  final bool _isReferenceDatabase;

  /// Opens (or creates) the database file on a background isolate, so queries
  /// and scanner writes never block UI frames. [configureConnection] runs
  /// inside that isolate and must stay a top-level function. `beforeOpen` (and
  /// the schema guard in it) runs on the calling isolate; its errors and
  /// SQLite's reach callers as `DriftRemoteException` (nested for `beforeOpen`).
  /// For a SQLite error `remoteCause` is the `SqliteException` (one level);
  /// for `beforeOpen` errors rely only on `toString()`.
  ///
  /// Keep it a single connection (no `readPool`): TEMP tables and triggers
  /// (play stats bulk, track GC), pragmas and transactions are per connection.
  factory AppDatabase.file(File file) => AppDatabase(
    NativeDatabase.createInBackground(file, setup: configureConnection),
  );

  /// Opens this database (migration, schema guard) and returns the connection
  /// extension databases open on (`ProDatabase.connect(await db.openedConnection())`).
  /// Always use this for extensions: the remote executor runs the migration of
  /// the last database that touched it, so an extension that queried first
  /// would run its own create step against the file.
  Future<DatabaseConnection> openedConnection() async {
    await doWhenOpened((_) async {});
    return connection;
  }

  /// The raw connection (drift marks `connection` protected). Only valid after
  /// the database opened; prefer [openedConnection].
  DatabaseConnection get sharedConnection => connection;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA recursive_triggers = ON');
      if (kDebugMode && !_isReferenceDatabase) {
        await verifyDevSchema(this, openReference: _ReferenceAppDatabase.new);
      }
      // No transaction is in flight at open, so a set switch is stale
      // (left by a crash) and would freeze the stats triggers.
      await customStatement(
        'UPDATE play_stats_ctl SET bulk = 0 WHERE bulk <> 0',
      );
    },
  );
}

/// The fresh in-memory copy the schema guard compares a file against. It is
/// its own type so drift does not warn about two `AppDatabase`s, and it never
/// runs the guard itself, so it cannot recurse.
class _ReferenceAppDatabase extends AppDatabase {
  _ReferenceAppDatabase()
    : super._(
        NativeDatabase.memory(setup: configureConnection),
        isReference: true,
      );
}
