import 'package:drift/drift.dart' show TableUpdateQuery, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late int src;
  late List<int> t; // t[0..29], local, present
  setUp(() async {
    db = openTestDb();
    src = await addSource(db);
    t = [for (var i = 0; i < 30; i++) await addTrack(db, src, locator: 't$i')];
  });
  tearDown(() => db.close());

  Future<SavedQueueOutcome> save(
    List<int> ids, {
    int now = 1000,
    List<int>? userOrder,
  }) => recordSavedQueue(db, trackIds: ids, userOrderIds: userOrder, now: now);

  Future<int> count(String sql) async =>
      (await db.customSelect(sql).getSingle()).read<int>('c');

  /// Saved queues newest first: (id, saved_at).
  Future<List<({int id, int savedAt})>> queues() async => [
    for (final r
        in await db
            .customSelect(
              "SELECT id, saved_at FROM playlists WHERE kind = 'queue' "
              'ORDER BY saved_at DESC, id DESC',
            )
            .get())
      (id: r.read<int>('id'), savedAt: r.read<int>('saved_at')),
  ];

  Future<String> uidOf(int id) async =>
      (await db
              .customSelect(
                'SELECT uid FROM playlists WHERE id = ?',
                variables: [Variable.withInt(id)],
              )
              .getSingle())
          .read<String>('uid');

  Future<List<int>> tracksOf(int playlistId) async => [
    for (final r
        in await db
            .customSelect(
              'SELECT track_id FROM playlist_entries WHERE playlist_id = ? '
              'ORDER BY sort_key, uid',
              variables: [Variable.withInt(playlistId)],
            )
            .get())
      r.read<int>('track_id'),
  ];

  test(
    'fewer than two local tracks: nothing written, no notification',
    () async {
      final seen = <Object>[];
      final sub = db
          .tableUpdates(
            TableUpdateQuery.onAllTables([db.playlists, db.playlistEntries]),
          )
          .listen(seen.add);
      expect(await save([t[0]]), SavedQueueOutcome.tooShort);
      expect(await save(const []), SavedQueueOutcome.tooShort);
      final plugin = await addSource(db, kind: SourceKind.plugin, name: 'p');
      final remote = await addTrack(
        db,
        plugin,
        locator: 'r',
        status: TrackStatus.remote,
      );
      expect(await save([t[0], remote]), SavedQueueOutcome.tooShort);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(await count('SELECT COUNT(*) AS c FROM playlists'), 0);
      expect(seen, isEmpty);
    },
  );

  test('keeps local present/missing in order, drops the rest', () async {
    final plugin = await addSource(db, kind: SourceKind.plugin, name: 'p');
    final remote = await addTrack(
      db,
      plugin,
      locator: 'r',
      status: TrackStatus.remote,
    );
    final hidden = await addTrack(
      db,
      src,
      locator: 'h',
      status: TrackStatus.hidden,
    );
    final missing = await addTrack(
      db,
      src,
      locator: 'm',
      status: TrackStatus.missing,
    );
    final out = await save([t[1], remote, hidden, missing, 99999, t[1], t[0]]);
    expect(out, SavedQueueOutcome.saved);
    final q = await queues();
    expect(await tracksOf(q.single.id), [t[1], missing, t[1], t[0]]);
  });

  test('a saved row has kind, name, context and entries', () async {
    await recordSavedQueue(
      db,
      trackIds: [t[0], t[1]],
      contextKind: 'album',
      contextRef: 'ref-1',
      contextLabel: 'Some album',
      now: 4242,
    );
    final r = (await db
        .customSelect(
          "SELECT name, saved_at, created_at, context_kind, context_ref, "
          "context_label FROM playlists WHERE kind = 'queue'",
        )
        .getSingle());
    expect(r.read<String>('name'), 'Queue');
    expect(r.read<int>('saved_at'), 4242);
    expect(r.read<int>('created_at'), 4242);
    expect(r.read<String>('context_kind'), 'album');
    expect(r.read<String>('context_ref'), 'ref-1');
    expect(r.read<String>('context_label'), 'Some album');
  });

  test('repeats keep their count', () async {
    await save([t[0], t[0], t[1], t[0]]);
    expect(await tracksOf((await queues()).single.id), [
      t[0],
      t[0],
      t[1],
      t[0],
    ]);
  });

  test(
    'same as the newest: touched, saved_at strictly up, no new entries',
    () async {
      await save([t[0], t[1]], now: 1000);
      final first = (await queues()).single;
      expect(first.savedAt, 1000);
      expect(await save([t[0], t[1]], now: 1000), SavedQueueOutcome.touched);
      expect(await save([t[0], t[1]], now: 500), SavedQueueOutcome.touched);
      final after = (await queues()).single;
      expect(after.id, first.id);
      expect(after.savedAt, 1002);
      expect(await count('SELECT COUNT(*) AS c FROM playlist_entries'), 2);
    },
  );

  test('touch updates the context only when the new source has one', () async {
    await recordSavedQueue(
      db,
      trackIds: [t[0], t[1]],
      contextKind: 'album',
      contextRef: 'a',
      contextLabel: 'A',
      now: 1,
    );
    await recordSavedQueue(db, trackIds: [t[0], t[1]], now: 2);
    Future<String?> label() async =>
        (await db
                .customSelect(
                  "SELECT context_label AS l FROM playlists WHERE kind='queue'",
                )
                .getSingle())
            .readNullable<String>('l');
    expect(await label(), 'A');
    await recordSavedQueue(
      db,
      trackIds: [t[0], t[1]],
      contextKind: 'artist',
      contextRef: 'b',
      contextLabel: 'B',
      now: 3,
    );
    expect(await label(), 'B');
  });

  test('prefix, longer and reordered queues are new saves', () async {
    expect(await save([t[0], t[1]], now: 1), SavedQueueOutcome.saved);
    expect(await save([t[0], t[1], t[2]], now: 2), SavedQueueOutcome.saved);
    expect(await save([t[0], t[1]], now: 3), SavedQueueOutcome.touched);
    expect(await save([t[1], t[0]], now: 4), SavedQueueOutcome.saved);
    expect(await save([t[1], t[0]], now: 5), SavedQueueOutcome.touched);
    expect(await queues(), hasLength(3));
  });

  test('replaying an older saved queue after another save moves it, not '
      'copies it', () async {
    await save([t[1], t[2]], now: 1); // X
    final x = (await queues()).single.id;
    await save([t[3], t[4]], now: 2);
    expect(await touchSavedQueue(db, await uidOf(x), now: 10), isTrue);
    expect(await save([t[5], t[6]], now: 11), SavedQueueOutcome.saved);
    expect(await save([t[1], t[2]], now: 20), SavedQueueOutcome.touched);
    final q = await queues();
    expect(q, hasLength(3));
    expect(q.first.id, x);
    expect(await tracksOf(x), [t[1], t[2]]);
  });

  test('several equal queues: the newest one is moved', () async {
    await save([t[0], t[1]], now: 1);
    await db.customStatement(
      "INSERT INTO playlists (uid, name, name_key, created_at, updated_at, "
      "kind, saved_at) VALUES ('dup', 'Queue', 'queue', 1, 1, 'queue', 5)",
    );
    final dup =
        (await db
                .customSelect("SELECT id FROM playlists WHERE uid = 'dup'")
                .getSingle())
            .read<int>('id');
    await db.customStatement(
      'INSERT INTO playlist_entries (uid, playlist_id, track_id, sort_key, '
      "added_at, updated_at) VALUES ('d1', $dup, ${t[0]}, 'a', 1, 1), "
      "('d2', $dup, ${t[1]}, 'b', 1, 1)",
    );
    expect(await save([t[0], t[1]], now: 50), SavedQueueOutcome.touched);
    expect((await queues()).first.id, dup);
    expect(await queues(), hasLength(2));
  });

  test(
    'user order match: a shuffled replay touches the stored queue',
    () async {
      await save([t[1], t[2], t[3]], now: 1);
      final id = (await queues()).single.id;
      expect(
        await save([t[3], t[1], t[2]], userOrder: [t[1], t[2], t[3]], now: 2),
        SavedQueueOutcome.touched,
      );
      expect(await queues(), hasLength(1));
      expect(await tracksOf(id), [t[1], t[2], t[3]]);
    },
  );

  test('user order that matches nothing is saved in play order', () async {
    await save([t[1], t[2], t[3]], now: 1);
    expect(
      await save([t[3], t[1], t[2]], userOrder: [t[2], t[3], t[1]], now: 2),
      SavedQueueOutcome.saved,
    );
    final q = await queues();
    expect(q, hasLength(2));
    expect(await tracksOf(q.first.id), [t[3], t[1], t[2]]);
  });

  test('a user order that filters to a different length is ignored', () async {
    await save([t[1], t[2]], now: 1);
    final hidden = await addTrack(
      db,
      src,
      locator: 'h',
      status: TrackStatus.hidden,
    );
    await db.customStatement(
      "INSERT INTO playlists (uid, name, name_key, created_at, updated_at, "
      "kind, saved_at) VALUES ('empty', 'Queue', 'queue', 1, 1, 'queue', 9)",
    );
    expect(
      await save([t[3], t[4]], userOrder: const [], now: 20),
      SavedQueueOutcome.saved,
    );
    expect(
      await save([t[5], t[6]], userOrder: [hidden, hidden], now: 30),
      SavedQueueOutcome.saved,
    );
    expect(
      await save([t[7], t[8]], userOrder: [t[7]], now: 40),
      SavedQueueOutcome.saved,
    );
    expect(await queues(), hasLength(5));
  });

  test('null user order keeps the play order comparison only', () async {
    await save([t[1], t[2], t[3]], now: 1);
    expect(await save([t[3], t[1], t[2]], now: 2), SavedQueueOutcome.saved);
  });

  test('touching a uid that is not a saved queue notifies nothing', () async {
    final seen = <Object>[];
    final sub = db
        .tableUpdates(TableUpdateQuery.onAllTables([db.playlists]))
        .listen(seen.add);
    expect(await touchSavedQueue(db, 'nope', now: 5), isFalse);
    await pumpEventQueue();
    await sub.cancel();
    expect(seen, isEmpty);
  });

  test('21 different saves keep 20, drop the oldest and its entries', () async {
    for (var i = 1; i <= 21; i++) {
      expect(await save([t[0], t[i]], now: 1000 + i), SavedQueueOutcome.saved);
    }
    final q = await queues();
    expect(q, hasLength(20));
    expect(q.map((e) => e.savedAt), [for (var i = 21; i >= 2; i--) 1000 + i]);
    expect(await count('SELECT COUNT(*) AS c FROM playlist_entries'), 40);
    expect(
      await count(
        'SELECT COUNT(*) AS c FROM playlist_entries WHERE playlist_id NOT IN (SELECT id FROM playlists)',
      ),
      0,
    );
  });

  test(
    'a clock that stepped back keeps the new save newest and unpruned',
    () async {
      for (var i = 1; i <= 20; i++) {
        await save([t[0], t[i]], now: 5000 + i);
      }
      expect(await save([t[0], t[21]], now: 100), SavedQueueOutcome.saved);
      final q = await queues();
      expect(q, hasLength(20));
      expect(q.first.savedAt, 5021);
      expect(await tracksOf(q.first.id), [t[0], t[21]]);
      // The oldest of the 20 went, not the new one.
      expect(q.last.savedAt, 5002);
    },
  );

  test('other playlists and Favorites are untouched', () async {
    final normal = await addPlaylist(db, name: 'Mine', now: 7);
    await addEntry(db, normal, t[0], sortKey: 'a0');
    final fav = await addPlaylist(
      db,
      kind: PlaylistKind.favorites,
      uid: 'favorites',
      now: 8,
    );
    await addEntry(db, fav, t[1], sortKey: 'a0');
    Future<List<String>> snapshot() async => [
      for (final r
          in await db
              .customSelect(
                "SELECT id, uid, updated_at, saved_at, "
                '(SELECT COUNT(*) FROM playlist_entries e WHERE e.playlist_id = p.id) AS n '
                "FROM playlists p WHERE kind IS NOT 'queue' ORDER BY id",
              )
              .get())
        '${r.read<int>('id')}|${r.read<String>('uid')}|${r.read<int>('updated_at')}|${r.readNullable<int>('saved_at')}|${r.read<int>('n')}',
    ];
    final before = await snapshot();
    for (var i = 1; i <= 22; i++) {
      await save([t[2], t[2 + i]], now: 100 + i);
    }
    expect(await snapshot(), before);
    expect(before, hasLength(2));
  });

  test('a failing insert rolls everything back, prune included', () async {
    for (var i = 1; i <= 20; i++) {
      await save([t[0], t[i]], now: 1000 + i);
    }
    final before = await queues();
    await db.customStatement(
      'CREATE TRIGGER boom BEFORE INSERT ON playlist_entries '
      "BEGIN SELECT RAISE(ABORT, 'boom'); END",
    );
    await expectLater(
      save([t[25], t[26]], now: 9000),
      throwsConstraint('boom'),
    );
    expect(await queues(), before);
    expect(await count('SELECT COUNT(*) AS c FROM playlist_entries'), 40);
  });

  test(
    'touchSavedQueue moves it to the front; other uids are ignored',
    () async {
      await save([t[0], t[1]], now: 10);
      await save([t[0], t[2]], now: 20);
      final oldest = (await queues()).last;
      final uid =
          (await db
                  .customSelect(
                    'SELECT uid FROM playlists WHERE id = ?',
                    variables: [Variable.withInt(oldest.id)],
                  )
                  .getSingle())
              .read<String>('uid');
      expect(await touchSavedQueue(db, uid, now: 15), isTrue);
      final q = await queues();
      expect(q.first.id, oldest.id);
      expect(q.first.savedAt, 21);
      final normal = await addPlaylist(db, uid: 'normal-1');
      expect(await touchSavedQueue(db, 'normal-1', now: 99), isFalse);
      expect(await touchSavedQueue(db, 'nope', now: 99), isFalse);
      expect(
        (await db
                .customSelect(
                  'SELECT saved_at FROM playlists WHERE id = ?',
                  variables: [Variable.withInt(normal)],
                )
                .getSingle())
            .readNullable<int>('saved_at'),
        isNull,
      );
    },
  );

  test('a track hidden after the save still lets the queue match', () async {
    expect(await save([t[0], t[1], t[2]], now: 10), SavedQueueOutcome.saved);
    expect(await save([t[5], t[6]], now: 20), SavedQueueOutcome.saved);
    final first = (await queues()).last.id;
    await db.customStatement(
      "UPDATE tracks SET status = 'hidden' WHERE id = ?",
      [t[2]],
    );
    expect(await save([t[0], t[1]], now: 30), SavedQueueOutcome.touched);
    final q = await queues();
    expect(q, hasLength(2));
    expect(q.first.id, first);
    expect(await tracksOf(first), [t[0], t[1], t[2]]);
  });

  test('a queue with a missing track matches its present ids', () async {
    final m = await addTrack(
      db,
      src,
      locator: 'm',
      status: TrackStatus.missing,
    );
    expect(await save([t[0], m, t[1]], now: 10), SavedQueueOutcome.saved);
    expect(await save([t[5], t[6]], now: 20), SavedQueueOutcome.saved);
    final first = (await queues()).last.id;
    expect(await save([t[0], t[1]], now: 30), SavedQueueOutcome.touched);
    final q = await queues();
    expect(q, hasLength(2));
    expect(q.first.id, first);
    expect(await tracksOf(first), [t[0], m, t[1]]);
  });

  test('a queue with one present track and a missing one is touched', () async {
    final m = await addTrack(
      db,
      src,
      locator: 'm',
      status: TrackStatus.missing,
    );
    expect(await save([t[0], m], now: 10), SavedQueueOutcome.saved);
    expect(await save([t[0], m], now: 20), SavedQueueOutcome.touched);
    expect(await queues(), hasLength(1));
  });

  test('a saved queue pins its missing track from the orphan GC', () async {
    const grace = missingGraceMs;
    final m = await addAgedTrack(
      db,
      src,
      'gone',
      TrackStatus.missing,
      at: 1000,
    );
    expect(await save([t[0], m], now: 10), SavedQueueOutcome.saved);
    final now = 1000 + grace + 1;
    expect(await collectOrphanTracks(db, now: now), 0);
    expect(await count('SELECT COUNT(*) AS c FROM tracks WHERE id = $m'), 1);
    await db.customStatement("DELETE FROM playlists WHERE kind = 'queue'");
    expect(await collectOrphanTracks(db, now: now), 1);
    expect(await count('SELECT COUNT(*) AS c FROM tracks WHERE id = $m'), 0);
  });

  test('10 000 tracks save in one statement', () async {
    final ids = [for (var i = 0; i < 10000; i++) t[i % 30]];
    final sw = Stopwatch()..start();
    expect(await save(ids), SavedQueueOutcome.saved);
    sw.stop();
    printOnFailure('saved 10000 tracks in ${sw.elapsedMilliseconds} ms');
    expect(await count('SELECT COUNT(*) AS c FROM playlist_entries'), 10000);
    final sw2 = Stopwatch()..start();
    expect(await save(ids, now: 5), SavedQueueOutcome.touched);
    printOnFailure('touched 10000 tracks in ${sw2.elapsedMilliseconds} ms');
  });
}
