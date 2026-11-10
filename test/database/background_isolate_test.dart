import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/kanaru.dart';

import 'support/pro_like_database.dart';
import 'support/pro_like_database.drift.dart';
import 'support/test_db.dart';

/// The production file database runs SQLite on a background isolate; an
/// extension database must still share it like it shares an in-memory one.
void main() {
  late Directory dir;
  late File file;
  late AppDatabase db;
  late ProLikeDatabase pro;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    dir = Directory.systemTemp.createTempSync('kanaru_bg_');
    file = File('${dir.path}/kanaru.db');
    db = AppDatabase.file(file);
    // openedConnection() itself must open the public database first.
    pro = ProLikeDatabase.connect(await db.openedConnection());
    await pro.createOwnTables();
  });
  tearDown(() async {
    // Extension first, then the public database.
    await pro.close();
    await db.close();
    dir.deleteSync(recursive: true);
  });

  test('pragmas are set inside the background isolate', () async {
    for (final name in ['foreign_keys', 'recursive_triggers']) {
      final row = await pro.customSelect('PRAGMA $name').getSingle();
      expect(row.read<int>(name), 1, reason: name);
    }
  });

  test('writes of either database are visible to the other', () async {
    final source = await addSource(db);
    final track = await addTrack(db, source, locator: 'a.flac');
    await pro
        .into(pro.proLikeNotes)
        .insert(ProLikeNotesCompanion.insert(trackId: track, body: 'n'));
    final fromApp = await db
        .customSelect('SELECT body FROM pro_like_notes')
        .getSingle();
    expect(fromApp.read<String>('body'), 'n');
    final fromPro = await (pro.select(
      pro.tracks,
    )..where((t) => t.id.equals(track))).getSingle();
    expect(fromPro.locator, 'a.flac');
  });

  test('RESTRICT foreign key holds across the isolate', () async {
    final source = await addSource(db);
    final track = await addTrack(db, source, locator: 'a.flac');
    await pro
        .into(pro.proLikeNotes)
        .insert(ProLikeNotesCompanion.insert(trackId: track, body: 'n'));
    await expectLater(
      (db.delete(db.tracks)..where((t) => t.id.equals(track))).go(),
      throwsA(
        isA<DriftRemoteException>().having(
          (e) => e.toString(),
          'message',
          contains('FOREIGN KEY'),
        ),
      ),
    );
  });

  test('watch streams fire for writes from the other database', () async {
    final source = await addSource(db);
    final track = await addTrack(db, source, locator: 'a.flac');

    final appCount = db
        .customSelect(
          'SELECT COUNT(*) AS c FROM pro_like_notes',
          readsFrom: {pro.proLikeNotes},
        )
        .watchSingle()
        .map((r) => r.read<int>('c'));
    final appSees = appCount
        .firstWhere((c) => c == 1)
        .timeout(const Duration(seconds: 5));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await pro
        .into(pro.proLikeNotes)
        .insert(ProLikeNotesCompanion.insert(trackId: track, body: 'n'));
    expect(await appSees, 1);

    final proSees = pro
        .select(pro.tracks)
        .watch()
        .map((rows) => rows.length)
        .firstWhere((n) => n == 2)
        .timeout(const Duration(seconds: 5));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await addTrack(db, source, locator: 'b.flac');
    expect(await proSees, 2);
  });

  test('a transaction on the app database is atomic', () async {
    final source = await addSource(db);
    await expectLater(
      db.transaction(() async {
        await addTrack(db, source, locator: 'x.flac');
        throw StateError('boom');
      }),
      throwsStateError,
    );
    expect(await db.select(db.tracks).get(), isEmpty);

    await db.transaction(() async {
      await addTrack(db, source, locator: 'y.flac');
    });
    expect(await pro.select(pro.tracks).get(), hasLength(1));
  });

  test('a transaction on the extension database is atomic', () async {
    final source = await addSource(db);
    final track = await addTrack(db, source, locator: 'a.flac');
    await expectLater(
      pro.transaction(() async {
        await pro
            .into(pro.proLikeNotes)
            .insert(ProLikeNotesCompanion.insert(trackId: track, body: 'n'));
        throw StateError('boom');
      }),
      throwsStateError,
    );
    expect(
      await db.customSelect('SELECT 1 FROM pro_like_notes').get(),
      isEmpty,
    );
  });

  test('data survives close and reopen in the background', () async {
    final source = await addSource(db);
    await addTrack(db, source, locator: 'a.flac');
    await pro.close();
    await db.close();
    db = AppDatabase.file(file);
    pro = ProLikeDatabase.connect(await db.openedConnection());
    expect(await db.select(db.tracks).get(), hasLength(1));
  });

  test('an extension on openedConnection never runs its own create step', () async {
    // setUp used the ProLikeDatabase tripwire: its onCreate/onUpgrade throw.
    // Public tables exist, the guard passed and the version is the public one.
    final tables = await pro
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    final names = tables.map((r) => r.read<String>('name'));
    expect(names, containsAll(['tracks', 'sources', 'play_stats_ctl']));
    final version = await pro.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), db.schemaVersion);
  });

  test(
    'the play_stats_ctl reset ran before the extension got the connection',
    () async {
      await db.customStatement('UPDATE play_stats_ctl SET bulk = 1');
      await pro.close();
      await db.close();
      db = AppDatabase.file(file);
      pro = ProLikeDatabase.connect(await db.openedConnection());
      final bulk = await pro
          .customSelect('SELECT bulk FROM play_stats_ctl')
          .getSingle();
      expect(bulk.read<int>('bulk'), 0);
    },
  );
}
