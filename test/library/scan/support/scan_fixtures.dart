import 'dart:async';

import 'package:drift/drift.dart'
    show
        ApplyInterceptor,
        BooleanExpressionOperators,
        QueryExecutor,
        QueryInterceptor,
        Value,
        Variable;
import 'package:drift/native.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/scan/native_tag_reader.dart';
import 'package:kanaru/src/library/data/scan/tag_pass.dart';
import 'package:kanaru/src/library/domain/scan/native_failure.dart';
import 'package:kanaru/src/library/domain/scan/scan_folder.dart';
import 'package:kanaru/src/library/domain/scan/tag_read.dart';
import 'package:kanaru/src/storage/domain/local_folder_listing.dart';

import '../../../database/support/test_db.dart';

const scanRoot = '/music';
const scanNow = 5000;

/// A source with an enabled mount, as a scan folder.
Future<ScanFolder> addScanFolder(
  AppDatabase db, {
  String uid = 'src-scan',
  String root = scanRoot,
}) async {
  final id = await addSource(db, uid: uid, root: root);
  await addMount(db, id, root: root);
  return ScanFolder(sourceId: id, sourceUid: uid, root: root);
}

ListedFile listed(
  String locator, {
  int mtime = 10,
  int size = 100,
  int? durationMs,
}) => ListedFile(
  locator: locator,
  sizeBytes: size,
  mtimeMs: mtime,
  durationMs: durationMs,
);

/// A reader that answers from a table, with hooks for the tests.
class FakeTagReader implements TagReader {
  /// Answers by locator-independent file name (`one.mp3`); a file with no
  /// entry reads as a plain track titled after its stem.
  final Map<String, TagRead> byName = {};
  final List<List<String>> calls = [];

  /// Runs before each answer (apply an exclusion, remove the source, ...).
  Future<void> Function(List<String> paths)? onRead;

  /// Never answers when set.
  Completer<List<TagRead>>? hang;
  Object? throwWith;

  int get readCount => calls.fold(0, (n, c) => n + c.length);

  TagRead _answer(String path) {
    final name = path.substring(path.lastIndexOf('/') + 1);
    final given = byName[name];
    if (given != null) {
      return TagRead(path: path, fields: given.fields, error: given.error);
    }
    final stem = name.substring(0, name.lastIndexOf('.'));
    return TagRead(
      path: path,
      fields: TagFields(title: stem, durationMs: 200000),
    );
  }

  @override
  Future<List<TagRead>> read(List<String> paths) async {
    calls.add(paths);
    if (throwWith != null) throw throwWith!;
    if (hang != null) return hang!.future;
    await onRead?.call(paths);
    return [for (final p in paths) _answer(p)];
  }
}

TagRead tagged(String title, {TagFields? fields}) => TagRead(
  path: '',
  fields: fields ?? TagFields(title: title, durationMs: 200000),
);

TagRead failed(String kind, {required bool transient}) => TagRead(
  path: '',
  error: NativeFailure(kind: kind, transient: transient),
);

TagPassDeps passDeps(
  AppDatabase db,
  FakeTagReader reader, {
  int now = scanNow,
  int skipShorterThanMs = 0,
  ShortFileMemo? memo,
  Duration timeout = const Duration(seconds: 5),
  bool Function()? shouldStop,
  int isolateAbove = 5000,
  Future<RootPresence> Function()? presence,
}) => TagPassDeps(
  db: db,
  reader: reader,
  now: () => now,
  skipShorterThanMs: skipShorterThanMs,
  shortMemo: memo,
  tagTimeout: timeout,
  shouldStop: shouldStop,
  isolateDiffAbove: isolateAbove,
  rootStillThere: presence ?? () async => const RootPresence(present: true),
);

Future<Track> trackAt(AppDatabase db, int sourceId, String locator) =>
    (db.select(db.tracks)..where(
          (t) => t.sourceId.equals(sourceId) & t.locator.equals(locator),
        ))
        .getSingle();

Future<Track?> maybeTrackAt(AppDatabase db, int sourceId, String locator) =>
    (db.select(db.tracks)..where(
          (t) => t.sourceId.equals(sourceId) & t.locator.equals(locator),
        ))
        .getSingleOrNull();

Future<List<String>> artistKeysOf(AppDatabase db, int trackId) async {
  final rows = await db
      .customSelect(
        'SELECT artist_key FROM track_artists WHERE track_id = ? '
        'ORDER BY position',
        variables: [Variable.withInt(trackId)],
      )
      .get();
  return [for (final r in rows) r.read<String>('artist_key')];
}

Future<Map<String, int>> statusCounts(AppDatabase db, int sourceId) async {
  final rows = await db
      .customSelect(
        'SELECT status, COUNT(*) AS n FROM tracks WHERE source_id = ? '
        'GROUP BY status',
        variables: [Variable.withInt(sourceId)],
      )
      .get();
  return {for (final r in rows) r.read<String>('status'): r.read<int>('n')};
}

/// Records the UPDATE statements a database runs.
class StatementLog extends QueryInterceptor {
  final List<String> updates = [];
  final List<String> selects = [];

  int updatesMatching(Pattern p) => updates.where((u) => u.contains(p)).length;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    selects.add(statement);
    return super.runSelect(executor, statement, args);
  }

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    updates.add(statement);
    return super.runUpdate(executor, statement, args);
  }
}

/// An in-memory database that records its UPDATE statements in [log].
AppDatabase openLoggedDb(StatementLog log) => AppDatabase(
  NativeDatabase.memory(setup: configureConnection).interceptWith(log),
);

/// Inserts [count] present rows `f0.mp3`... for [sourceId] in one batch.
Future<void> addManyTracks(AppDatabase db, int sourceId, int count) =>
    db.batch((b) {
      b.insertAll(db.tracks, [
        for (var i = 0; i < count; i++)
          TracksCompanion.insert(
            uid: 'u-$sourceId-$i',
            sourceId: sourceId,
            locator: 'f${i.toString().padLeft(5, '0')}.mp3',
            relPath: 'f$i.mp3',
            title: 'T$i',
            mtimeMs: const Value(10),
            sizeBytes: const Value(100),
            tagsVersion: const Value(1),
            keysVersion: const Value(1),
            addedAt: 1000,
            updatedAt: 1000,
          ),
      ]);
    });
