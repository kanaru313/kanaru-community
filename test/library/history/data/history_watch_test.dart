import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/history/history_repository.dart';
import 'package:kanaru/src/library/data/history/history_watch.dart';
import 'package:kanaru/src/library/domain/history/history_change.dart';

import '../../../database/support/test_db.dart';
import 'history_fixture.dart';

void main() {
  // testWidgets runs on a fake clock: pump(d) advances time without waiting.
  group('debounced', () {
    testWidgets('a burst gives one event after the quiet period', (t) async {
      final source = StreamController<int>();
      final events = <void>[];
      final sub = debounced(
        source.stream,
        const Duration(milliseconds: 40),
      ).listen(events.add);
      for (var i = 0; i < 5; i++) {
        source.add(i);
        await t.pump(const Duration(milliseconds: 10));
      }
      expect(events, isEmpty);
      await t.pump(const Duration(milliseconds: 40));
      expect(events.length, 1);
      unawaited(sub.cancel());
      unawaited(source.close());
      await t.pump();
    });

    testWidgets('cancelling drops the pending event and the source listener', (
      t,
    ) async {
      final source = StreamController<int>();
      final events = <void>[];
      final sub = debounced(
        source.stream,
        const Duration(milliseconds: 40),
      ).listen(events.add);
      source.add(1);
      await t.pump();
      unawaited(sub.cancel());
      await t.pump();
      expect(source.hasListener, isFalse);
      await t.pump(const Duration(milliseconds: 100));
      expect(events, isEmpty);
      unawaited(source.close());
    });

    testWidgets('kinds are OR-ed across the window', (t) async {
      final source = StreamController<int>();
      final events = <int>[];
      final sub = debouncedFold<int, int>(
        source.stream,
        const Duration(milliseconds: 40),
        (e) => e,
        (a, b) => a | b,
      ).listen(events.add);
      source.add(1);
      await t.pump(const Duration(milliseconds: 30));
      source.add(2);
      await t.pump(const Duration(milliseconds: 100));
      expect(events, [3]);
      source.add(1);
      await t.pump(const Duration(milliseconds: 100));
      expect(events, [3, 1]);
      unawaited(sub.cancel());
      unawaited(source.close());
      await t.pump();
    });
  });

  group('database notifications', () {
    late AppDatabase db;
    late HistoryRepository repo;
    late int track;

    setUp(() async {
      db = openTestDb();
      repo = HistoryRepository(db);
      track = (await addTracks(db, 1)).single;
    });
    tearDown(() => db.close());

    /// Everything [stream] emits while [act] runs and a window well past its
    /// debounce goes by.
    Future<List<T>> collect<T>(
      Stream<T> stream,
      Future<void> Function() act, {
      int waitMs = 1500,
    }) async {
      final got = <T>[];
      final sub = stream.listen(got.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await act();
      await Future<void>.delayed(Duration(milliseconds: waitMs));
      await sub.cancel();
      return got;
    }

    Future<bool> emits(
      Stream<void> stream,
      Future<void> Function() act, {
      int waitMs = 1500,
    }) async => (await collect(stream, act, waitMs: waitMs)).isNotEmpty;

    test('an inserted play reports an insert only', () async {
      final got = await collect(
        repo.watchPlays(),
        () => addPlay(db, track, playedAt: 5),
      );
      expect(got, isNotEmpty);
      expect(got.last, const HistoryChange(inserted: true));
    });

    test('a removal reports a removal only', () async {
      await addPlay(db, track, playedAt: 5, uid: 'x');
      final got = await collect(
        repo.watchPlays(),
        () => repo.removePlays(['x']),
      );
      expect(got, [const HistoryChange(removed: true)]);
    });

    test('an undo reports both kinds', () async {
      await addPlay(db, track, playedAt: 5, uid: 'x');
      final batch = (await repo.removePlays(['x']))!;
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final got = await collect(
        repo.watchPlays(),
        () => repo.undoBatches([batch]),
      );
      expect(got, [const HistoryChange(inserted: true, removed: true)]);
    });

    test('an insert and a removal in one window are folded', () async {
      await addPlay(db, track, playedAt: 5, uid: 'x');
      final got = await collect(repo.watchPlays(), () async {
        await addPlay(db, track, playedAt: 6, uid: 'y');
        await repo.removePlays(['x']);
      });
      expect(got, [const HistoryChange(inserted: true, removed: true)]);
    });

    test('a listened-time checkpoint does not', () async {
      await addPlay(db, track, playedAt: 5, uid: 'x');
      expect(
        await emits(repo.watchPlays(), () async {
          await db.customUpdate('UPDATE play_log SET listened_ms = 9');
          db.notifyUpdates({
            const TableUpdate('play_log', kind: UpdateKind.update),
          });
        }),
        isFalse,
      );
    });

    test(
      'a track change wakes the tracks stream, not the plays stream',
      () async {
        final plays = emits(repo.watchPlays(), () async {});
        expect(
          await emits(repo.watchTracks(), () async {
            await db.customUpdate("UPDATE tracks SET title = 'N'");
            db.notifyUpdates({const TableUpdate('tracks')});
          }, waitMs: 2500),
          isTrue,
        );
        expect(await plays, isFalse);
      },
    );
  });
}
