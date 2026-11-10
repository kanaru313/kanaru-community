import 'dart:math';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/data/queue_repository.dart';
import 'package:kanaru/src/playback/domain/queue_logic.dart';

import '../../database/support/test_db.dart';
import '../support/queue_fixtures.dart';

void main() {
  late AppDatabase db;
  late QueueRepository repo;
  late List<TrackId> pool;
  const keys = KeyGen();

  setUp(() async {
    db = openTestDb();
    repo = QueueRepository(db);
    final src = await addSource(db);
    pool = [
      for (var i = 0; i < 40; i++)
        TrackId(await addTrack(db, src, locator: 't$i.mp3')),
    ];
  });
  tearDown(() => db.close());

  group('replace', () {
    test(
      'returns the new ids mapped to the right tracks (1 200, chunked)',
      () async {
        final ids = [for (var i = 0; i < 1200; i++) pool[i % pool.length]];
        final items = await repo.replace(ids, 10);
        expect(items.map((i) => i.trackId), ids);
        expect(items.map((i) => i.entryId).toSet(), hasLength(1200));
        final stored = await repo.load(shuffled: false);
        expect(stored, items);
        expect(stored.every((i) => i.shuffleKey == null), isTrue);
      },
    );

    test('shuffle order: result and stored shuffled order follow it', () async {
      final ids = pool.sublist(0, 5);
      final items = await repo.replace(ids, 1, shuffleOrder: [3, 0, 4, 1, 2]);
      expect(items.map((i) => i.trackId), [
        ids[3],
        ids[0],
        ids[4],
        ids[1],
        ids[2],
      ]);
      final shuffled = await repo.load(shuffled: true);
      expect(shuffled, items);
      final plain = await repo.load(shuffled: false);
      expect(plain.map((i) => i.trackId), ids);
    });

    test(
      '20 000 ids are written in one transaction within the debug bound',
      () async {
        final ids = List.filled(20000, pool.first);
        final sw = Stopwatch()..start();
        final items = await repo.replace(ids, 1);
        // Alone it takes well under a second; the bound only has to catch a
        // regression of an order of magnitude on a loaded machine.
        expect(sw.elapsedMilliseconds, lessThan(15000));
        expect(items, hasLength(20000));
        expect(items.map((i) => i.entryId).toSet(), hasLength(20000));
      },
    );

    test('a bad permutation throws before any write', () async {
      await repo.replace(pool.sublist(0, 2), 1);
      expect(
        () => repo.replace(pool.sublist(0, 3), 2, shuffleOrder: [0, 0, 1]),
        throwsArgumentError,
      );
      expect(await repo.load(shuffled: false), hasLength(2));
    });

    test('an unknown track rolls back and keeps the old queue', () async {
      await repo.replace(pool.sublist(0, 2), 1);
      await expectLater(
        repo.replace([pool[0], const TrackId(99999)], 2),
        throwsA(anything),
      );
      expect(await repo.load(shuffled: false), hasLength(2));
    });

    test('empty clears', () async {
      await repo.replace(pool.sublist(0, 2), 1);
      expect(await repo.replace(const [], 2), isEmpty);
      expect(await repo.load(shuffled: false), isEmpty);
    });

    test('notifies queue_entries', () async {
      final updates = db.tableUpdates(
        TableUpdateQuery.onTableName('queue_entries'),
      );
      final seen = expectLater(updates, emits(anything));
      await repo.replace(pool.sublist(0, 2), 1);
      await seen;
    });
  });

  group('apply', () {
    test('play next and enqueue persist and return real ids', () async {
      final items = await repo.replace(pool.sublist(0, 3), 1);
      var s = QueueState(items: items, current: 0);
      final e = insertPlayNext(s, pool.sublist(10, 12), keys);
      final applied = await repo.apply(e, 2);
      expect(applied.inserted.every((i) => i.entryId > 0), isTrue);
      expect(await repo.load(shuffled: false), applied.next.items);
      s = applied.next;
      final q = await repo.apply(enqueue(s, [pool[20]], keys), 3);
      expect(await repo.load(shuffled: false), q.next.items);
    });

    test('1 200 inserts and deletes cross chunk boundaries', () async {
      final items = await repo.replace(pool.sublist(0, 2), 1);
      var s = QueueState(items: items, current: 0);
      final big = [for (var i = 0; i < 1200; i++) pool[i % pool.length]];
      final added = await repo.apply(enqueue(s, big, keys), 2);
      expect((await repo.load(shuffled: false)), added.next.items);
      expect(added.next.length, 1202);
      final ids = {for (final i in added.next.items.skip(1)) i.entryId};
      final removed = await repo.apply(remove(added.next, ids), 3);
      expect(await repo.load(shuffled: false), removed.next.items);
      expect(removed.next.length, 1);
    });

    test(
      'shuffleUpcoming rewrites 1 200 keys and touches only upcoming rows',
      () async {
        final ids = [for (var i = 0; i < 1200; i++) pool[i % pool.length]];
        final items = await repo.replace(
          ids,
          1,
          shuffleOrder: [for (var i = 1199; i >= 0; i--) i],
        );
        final s = QueueState(items: items, current: 100, shuffled: true);
        final e = shuffleUpcoming(s, Random(5), keys);
        expect(e.rekeyed.length, 1099);
        final before = await repo.load(shuffled: true);
        await repo.apply(e, 2);
        final after = await repo.load(shuffled: true);
        expect(after, e.next.items);
        expect(after.sublist(0, 101), before.sublist(0, 101));
        // Sort keys never change.
        final sorts = {for (final i in before) i.entryId: i.sortKey};
        expect(after.every((i) => sorts[i.entryId] == i.sortKey), isTrue);
      },
    );

    test('shuffle on a never shuffled queue gives every row a key', () async {
      final items = await repo.replace(pool.sublist(0, 6), 1);
      final e = shuffleUpcoming(
        QueueState(items: items, current: 2),
        Random(1),
        keys,
      );
      await repo.apply(e, 2);
      final stored = await repo.load(shuffled: true);
      expect(stored, e.next.items);
      expect(stored.every((i) => i.shuffleKey != null), isTrue);
      final off = unshuffle(e.next);
      await repo.apply(off, 3);
      final plain = await repo.load(shuffled: false);
      expect(plain, off.next.items);
      expect(plain.every((i) => i.shuffleKey == null), isTrue);
    });

    test('remove then undo restores the same rows and ids', () async {
      final items = await repo.replace(pool.sublist(0, 5), 1);
      final s = QueueState(items: items, current: 2);
      final removed = await repo.apply(
        remove(s, {items[1].entryId, items[2].entryId}),
        2,
      );
      expect((await repo.load(shuffled: false)).length, 3);
      final back = await repo.apply(undo(removed.next, removed.undo!, keys), 3);
      expect(await repo.load(shuffled: false), back.next.items);
      expect(
        back.next.items.map((i) => i.entryId),
        items.map((i) => i.entryId),
      );
    });

    test('an unknown track rolls back the whole edit', () async {
      final items = await repo.replace(pool.sublist(0, 3), 1);
      final s = QueueState(items: items, current: 0);
      final bad = enqueue(s, [pool[5], const TrackId(99999)], keys);
      final mixed = QueueEdit(
        next: bad.next,
        inserted: bad.inserted,
        removedIds: [items[2].entryId],
        rekeyed: bad.rekeyed,
      );
      await expectLater(repo.apply(mixed, 2), throwsA(anything));
      expect(await repo.load(shuffled: false), items);
    });

    test('a no-op edit writes and notifies nothing', () async {
      final items = await repo.replace(pool.sublist(0, 2), 1);
      final e = QueueEdit.none(QueueState(items: items, current: 0));
      expect(await repo.apply(e, 2), same(e));
    });
  });

  group('random operations', () {
    for (final seed in [11, 12]) {
      test(
        '500 operations incl. undo: the table equals the model (seed $seed)',
        () async {
          final r = Random(seed);
          final items = await repo.replace(pool.sublist(0, 8), 1);
          var s = QueueState(items: items, current: 3);
          UndoToken? token;
          Future<void> write(QueueEdit e) async {
            final applied = await repo.apply(e, 2);
            s = applied.next;
          }

          for (var step = 0; step < 500; step++) {
            final hadToken = token != null;
            switch (r.nextInt(9)) {
              case 0:
              case 1:
                await write(
                  insertPlayNext(s, [
                    pool[r.nextInt(40)],
                    pool[r.nextInt(40)],
                  ], keys),
                );
              case 2:
                await write(enqueue(s, [pool[r.nextInt(40)]], keys));
              case 3:
                if (s.length > 2) {
                  final e = remove(s, {s.items[r.nextInt(s.length)].entryId});
                  token = e.undo;
                  await write(e);
                }
              case 4:
              case 5:
                if (s.length > 1) {
                  await write(
                    move(
                      s,
                      s.items[r.nextInt(s.length)].entryId,
                      r.nextInt(s.length),
                      keys,
                    ),
                  );
                }
              case 6:
                await write(shuffleUpcoming(s, r, keys));
              case 7:
                await write(unshuffle(s));
              default:
                if (token != null) {
                  await write(undo(s, token, keys));
                  token = null;
                } else if (s.length > 1) {
                  s = s.withCurrent(r.nextInt(s.length), s.playNextRunIds);
                }
            }
            if (hadToken && r.nextInt(3) == 0) token = null;
            if (s.length > 30) {
              await write(
                remove(s, {for (var i = 0; i < 15; i++) s.items[i].entryId}),
              );
              token = null;
            }
            expectHealthy(s);
            expect(
              await repo.load(shuffled: s.shuffled),
              s.items,
              reason: 'step $step',
            );
            final byKey = [...s.items]
              ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
            expect(
              await repo.load(shuffled: false),
              byKey,
              reason: 'sort order, step $step',
            );
            if (s.shuffled) {
              expect({
                for (final i in s.items) i.shuffleKey,
              }, hasLength(s.length));
            }
          }
        },
      );
    }
  });
}
