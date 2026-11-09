import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/row_uids.dart';
import 'package:kanaru/src/database/tables.dart';

int _uidCounter = 0;

/// Matches a future that fails with a `SqliteException` whose message
/// contains [fragment], so a constraint test cannot pass for another reason.
Matcher throwsConstraint(String fragment) => throwsA(
      isA<SqliteException>().having((e) => e.message, 'message', contains(fragment)),
    );

/// A fresh in-memory [AppDatabase] with the same connection setup as the
/// file database. Close it in `tearDown`.
AppDatabase openTestDb() {
  // Tests open several databases on purpose (reference, Pro-like).
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory(setup: configureConnection));
}

/// Inserts a source and returns its id. [uid] defaults to a unique value.
Future<int> addSource(
  AppDatabase db, {
  String kind = SourceKind.local,
  String? uid,
  String name = 'Music',
  String? root,
  int now = 1000,
}) =>
    db.into(db.sources).insert(
          SourcesCompanion.insert(
            uid: uid ?? 'src-${_uidCounter++}-$name',
            kind: kind,
            name: name,
            root: Value(root),
            addedAt: now,
            updatedAt: now,
          ),
        );

/// Inserts a mount for [sourceId].
Future<void> addMount(
  AppDatabase db,
  int sourceId, {
  required String root,
  bool enabled = true,
}) =>
    db.into(db.sourceMounts).insert(
          SourceMountsCompanion.insert(
            sourceId: Value(sourceId),
            root: Value(root),
            enabled: Value(enabled),
            addedAt: 1000,
          ),
        );

/// Inserts a track of [sourceId] and returns its id.
Future<int> addTrack(
  AppDatabase db,
  int sourceId, {
  required String locator,
  String title = 'Title',
  String status = TrackStatus.present,
  String? uid,
  int? rating,
  int now = 1000,
}) =>
    db.into(db.tracks).insert(
          TracksCompanion.insert(
            uid: uid ?? trackUid('source-$sourceId', locator),
            sourceId: sourceId,
            locator: locator,
            relPath: locator,
            title: title,
            status: Value(status),
            rating: Value(rating),
            addedAt: now,
            updatedAt: now,
          ),
        );
