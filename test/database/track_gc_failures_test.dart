import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:drift/native.dart' show SqliteException;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';

import 'support/test_db.dart';

const _now = 100 * 24 * 60 * 60 * 1000;

Matcher _stateError(String fragment) => throwsA(
  isA<StateError>().having((e) => e.message, 'message', contains(fragment)),
);

void main() {
  late AppDatabase db;
  late int trackId;

  setUp(() async {
    db = openTestDb();
    final source = await addSource(db);
    trackId = await addAgedTrack(db, source, 'm', TrackStatus.missing);
  });
  tearDown(() => db.close());

  Future<int> count() async =>
      (await db.customSelect('SELECT count(*) AS n FROM tracks').getSingle())
          .read<int>('n');

  test('a CASCADE foreign key into tracks stops the run', () async {
    await db.customStatement(
      'CREATE TABLE cascade_refs (id INTEGER PRIMARY KEY, '
      'track_id INTEGER NOT NULL REFERENCES tracks(id) ON DELETE CASCADE)',
    );
    await expectLater(
      collectOrphanTracks(db, now: _now),
      _stateError('cascade_refs'),
    );
    expect(await count(), 1);
  });

  test('a composite foreign key into tracks stops the run', () async {
    await db.customStatement(
      'CREATE UNIQUE INDEX tracks_id_uid ON tracks (id, uid)',
    );
    await db.customStatement(
      'CREATE TABLE composite_refs (a INTEGER, b TEXT, '
      'FOREIGN KEY (a, b) REFERENCES tracks(id, uid) ON DELETE RESTRICT)',
    );
    await expectLater(
      collectOrphanTracks(db, now: _now),
      _stateError('composite foreign key in composite_refs'),
    );
    expect(await count(), 1);
  });

  test('a foreign key into an owned child stops the run', () async {
    await db.customStatement(
      'CREATE TABLE stats_refs (id INTEGER PRIMARY KEY, '
      'track_id INTEGER REFERENCES play_stats(track_id) ON DELETE RESTRICT)',
    );
    await expectLater(
      collectOrphanTracks(db, now: _now),
      _stateError('stats_refs.track_id references play_stats'),
    );
    expect(await count(), 1);
  });

  test('foreign keys off stops the run', () async {
    await db.customStatement('PRAGMA foreign_keys = OFF');
    await expectLater(
      collectOrphanTracks(db, now: _now),
      _stateError('foreign key enforcement is off'),
    );
    expect(await count(), 1);
  });

  test('a failure after the work started rolls everything back', () async {
    await db.customStatement(
      'INSERT INTO track_details (track_id) VALUES (?)',
      [trackId],
    );
    await db.customStatement(
      'CREATE TRIGGER boom BEFORE DELETE ON track_details '
      "BEGIN SELECT RAISE(ABORT, 'boom'); END",
    );
    await expectLater(
      collectOrphanTracks(db, now: _now),
      throwsA(anyOf(isA<SqliteException>(), isA<DriftRemoteException>())),
    );
    expect(await count(), 1);
    final temp = await db
        .customSelect(
          "SELECT name FROM sqlite_temp_master WHERE name = 'gc_candidates'",
        )
        .get();
    expect(temp, isEmpty);

    await db.customStatement('DROP TRIGGER boom');
    expect(await collectOrphanTracks(db, now: _now), 1);
  });
}
