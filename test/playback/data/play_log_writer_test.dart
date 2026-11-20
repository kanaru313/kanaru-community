import 'package:drift/drift.dart' show TableUpdateQuery, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/data/play_log_writer.dart';

import '../../database/support/test_db.dart';
import '../../library/history/data/history_fixture.dart'
    show statsRecomputed, statsTable;

void main() {
  late AppDatabase db;
  late PlayLogWriter writer;
  late TrackId track;

  setUp(() async {
    db = openTestDb();
    writer = PlayLogWriter(db);
    final src = await addSource(db);
    track = TrackId(await addTrack(db, src, locator: 'a.mp3'));
  });
  tearDown(() => db.close());

  Future<Map<String, Object?>> row(int id) async =>
      (await db
              .customSelect(
                'SELECT * FROM play_log WHERE id = ?',
                variables: [Variable.withInt(id)],
              )
              .getSingle())
          .data;

  test('insert then update listened_ms', () async {
    final id = await writer.insertListen(
      trackId: track,
      playedAt: 5000,
      listenedMs: 31000,
      deviceId: 'dev',
      context: const PlayContext(
        PlayContextKind.album,
        ref: 'k',
        label: 'Album',
      ),
      now: 5100,
    );
    var r = await row(id);
    expect(r['listened_ms'], 31000);
    expect(r['skipped'], 0);
    expect(r['context_kind'], 'album');
    expect(r['context_ref'], 'k');
    expect(r['device_id'], 'dev');
    expect(r['updated_at'], 5100);
    expect(r['deleted_at'], isNull);
    expect((r['uid']! as String), hasLength(26));

    await writer.updateListened(id, 90000, 6000);
    r = await row(id);
    expect(r['listened_ms'], 90000);
    expect(r['updated_at'], 6000);
  });

  test('a listen without context leaves the context columns null', () async {
    final id = await writer.insertListen(
      trackId: track,
      playedAt: 1,
      listenedMs: 1,
      deviceId: 'dev',
      now: 1,
    );
    final r = await row(id);
    expect(r['context_kind'], isNull);
    expect(r['context_ref'], isNull);
  });

  test(
    'play_stats counts through the trigger, and an update keeps the count',
    () async {
      final a = await writer.insertListen(
        trackId: track,
        playedAt: 100,
        listenedMs: 40000,
        deviceId: 'dev',
        now: 100,
      );
      await writer.insertListen(
        trackId: track,
        playedAt: 200,
        listenedMs: 40000,
        deviceId: 'dev',
        now: 200,
      );
      await writer.updateListened(a, 50000, 300);
      final s = await db
          .customSelect(
            'SELECT play_count, first_played_at, last_played_at FROM play_stats WHERE track_id = ?',
            variables: [Variable.withInt(track.value)],
          )
          .getSingle();
      expect(s.read<int>('play_count'), 2);
      expect(s.read<int>('first_played_at'), 100);
      expect(s.read<int>('last_played_at'), 200);
    },
  );

  test('notifies play_log', () async {
    final seen = expectLater(
      db.tableUpdates(TableUpdateQuery.onTableName('play_log')),
      emits(anything),
    );
    await writer.insertListen(
      trackId: track,
      playedAt: 1,
      listenedMs: 1,
      deviceId: 'dev',
      now: 1,
    );
    await seen;
  });

  group('deleteRange', () {
    late TrackId other;

    setUp(() async {
      final src = await addSource(db, name: 'Two');
      other = TrackId(await addTrack(db, src, locator: 'b.mp3'));
      for (final (t, at) in [
        (track, 100),
        (track, 200),
        (track, 300),
        (other, 150),
        (other, 400),
      ]) {
        await writer.insertListen(
          trackId: t,
          playedAt: at,
          listenedMs: 40000,
          deviceId: 'dev',
          now: at,
        );
      }
    });

    Future<List<int>> playedAts() async => [
      for (final r
          in await db
              .customSelect('SELECT played_at FROM play_log ORDER BY played_at')
              .get())
        r.read<int>('played_at'),
    ];

    test(
      'removes [from, to) and keeps the stats equal to a recompute',
      () async {
        expect(await writer.deleteRange(from: 150, to: 300), 2);
        expect(await playedAts(), [100, 300, 400]);
        expect(await statsTable(db), await statsRecomputed(db));
      },
    );

    test('an open side reaches the end of the log', () async {
      expect(await writer.deleteRange(from: 300), 2);
      expect(await playedAts(), [100, 150, 200]);
      expect(await writer.deleteRange(to: 150), 1);
      expect(await playedAts(), [150, 200]);
      expect(await statsTable(db), await statsRecomputed(db));
    });

    test('no bounds clears everything and empties the stats', () async {
      expect(await writer.deleteRange(), 5);
      expect(await playedAts(), isEmpty);
      expect(await statsTable(db), isEmpty);
    });

    test('an empty range deletes nothing', () async {
      expect(await writer.deleteRange(from: 500, to: 600), 0);
      expect(await writer.deleteRange(from: 200, to: 200), 0);
      expect(await playedAts(), hasLength(5));
      expect(await statsTable(db), await statsRecomputed(db));
    });

    test('a tombstoned row is not counted as deleted', () async {
      await db.customStatement(
        'UPDATE play_log SET deleted_at = 1 WHERE played_at = 100',
      );
      expect(await writer.deleteRange(), 4);
    });
  });
}
