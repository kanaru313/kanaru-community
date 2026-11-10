import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late int src;
  setUp(() async {
    db = openTestDb();
    src = await addSource(db);
  });
  tearDown(() => db.close());

  test('replaceQueue keeps order and allows repeats', () async {
    final a = await addTrack(db, src, locator: 'a');
    final b = await addTrack(db, src, locator: 'b');
    await replaceQueue(db, [b, a, b], 10);
    final q = await readQueue(db, shuffled: false);
    expect(q.map((e) => e.trackId), [b, a, b]);
    expect(q.every((e) => e.shuffleKey == null && e.addedAt == 10), isTrue);
  });

  test('replacing drops the old queue; empty clears', () async {
    final a = await addTrack(db, src, locator: 'a');
    await replaceQueue(db, [a, a], 1);
    await replaceQueue(db, [a], 2);
    expect(await readQueue(db, shuffled: false), hasLength(1));
    await replaceQueue(db, const [], 3);
    expect(await readQueue(db, shuffled: false), isEmpty);
  });

  test('1 200 entries keep their order across chunk boundaries', () async {
    final a = await addTrack(db, src, locator: 'a');
    await replaceQueue(db, List.filled(1200, a), 1);
    final q = await readQueue(db, shuffled: false);
    expect(q, hasLength(1200));
    final keys = q.map((e) => e.sortKey).toList();
    expect(keys.toSet(), hasLength(1200));
    expect([...keys]..sort(), keys);
  });

  test(
    'shuffled read without a shuffle order returns every row in user order',
    () async {
      final a = await addTrack(db, src, locator: 'a');
      final b = await addTrack(db, src, locator: 'b');
      await replaceQueue(db, [a, b, a], 1);
      final s = await readQueue(db, shuffled: true);
      expect(s.map((e) => e.trackId), [a, b, a]);
    },
  );

  test('shuffleOrder writes shuffle keys in that order', () async {
    final a = await addTrack(db, src, locator: 'a');
    final b = await addTrack(db, src, locator: 'b');
    final c = await addTrack(db, src, locator: 'c');
    await replaceQueue(db, [a, b, c], 1, shuffleOrder: [2, 0, 1]);
    expect((await readQueue(db, shuffled: false)).map((e) => e.trackId), [
      a,
      b,
      c,
    ]);
    expect((await readQueue(db, shuffled: true)).map((e) => e.trackId), [
      c,
      a,
      b,
    ]);
  });

  test('rows without a shuffle key sort after those with one', () async {
    final a = await addTrack(db, src, locator: 'a');
    final b = await addTrack(db, src, locator: 'b');
    final c = await addTrack(db, src, locator: 'c');
    await replaceQueue(db, [a, b, c], 1);
    final q = await readQueue(db, shuffled: false);
    await db.customStatement(
      "UPDATE queue_entries SET shuffle_key = 'a0' WHERE id = ?",
      [q[2].id],
    );
    final s = await readQueue(db, shuffled: true);
    expect(s.map((e) => e.trackId), [c, a, b]);
  });

  test('a bad shuffleOrder throws before any write', () async {
    final a = await addTrack(db, src, locator: 'a');
    final b = await addTrack(db, src, locator: 'b');
    await replaceQueue(db, [a], 1);
    for (final bad in [
      [0],
      [0, 0],
      [0, 2],
      [-1, 0],
    ]) {
      await expectLater(
        replaceQueue(db, [a, b], 2, shuffleOrder: bad),
        throwsArgumentError,
      );
    }
    expect(await readQueue(db, shuffled: false), hasLength(1));
  });

  test('1 200 entries with a reversed shuffleOrder keep both orders', () async {
    final a = await addTrack(db, src, locator: 'a');
    final ids = [
      for (var i = 0; i < 1200; i++) await addTrack(db, src, locator: 'l$i'),
    ];
    final order = [for (var i = 1199; i >= 0; i--) i];
    await replaceQueue(db, ids, 1, shuffleOrder: order);
    final user = await readQueue(db, shuffled: false);
    final shuffled = await readQueue(db, shuffled: true);
    expect(user.map((e) => e.trackId), ids);
    expect(shuffled.map((e) => e.trackId), ids.reversed);
    final keys = shuffled.map((e) => e.shuffleKey!).toList();
    expect(keys.toSet(), hasLength(1200));
    expect([...keys]..sort(), keys);
    expect(a, isNonZero);
  });

  test('an unknown track fails and leaves the old queue', () async {
    final a = await addTrack(db, src, locator: 'a');
    await replaceQueue(db, [a], 1);
    await expectLater(
      replaceQueue(db, [a, 9999], 2),
      throwsConstraint('FOREIGN KEY'),
    );
    expect(await readQueue(db, shuffled: false), hasLength(1));
  });

  test('a queued missing track survives the GC', () async {
    final a = await addAgedTrack(db, src, 'a', TrackStatus.missing, at: 1);
    await replaceQueue(db, [a], 1);
    expect(await collectOrphanTracks(db, now: 1 + missingGraceMs * 2), 0);
    await replaceQueue(db, const [], 2);
    expect(await collectOrphanTracks(db, now: 1 + missingGraceMs * 2), 1);
  });

  test('a stream on queue_entries re-emits', () async {
    final a = await addTrack(db, src, locator: 'a');
    final sizes = <int>[];
    final sub = db
        .select(db.queueEntries)
        .watch()
        .listen((r) => sizes.add(r.length));
    addTearDown(sub.cancel);
    await pumpEventQueue();
    await replaceQueue(db, [a, a], 1);
    await pumpEventQueue();
    expect(sizes.last, 2);
  });
}
