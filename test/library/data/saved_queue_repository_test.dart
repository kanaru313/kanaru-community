import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/playlists/playlist_sql.dart';
import 'package:kanaru/src/library/data/saved_queues/saved_queue_repository.dart';

import '../playlists/support/playlist_fixtures.dart';

void main() {
  late PlaylistFixture f;
  late SavedQueueRepository repo;
  int clock = 100;
  setUp(() async {
    f = await PlaylistFixture.open();
    clock = 100;
    repo = SavedQueueRepository(f.db, now: () => clock);
  });

  Future<void> save(List<int> ids, {required int at, String? label}) =>
      recordSavedQueue(
        f.db,
        trackIds: ids,
        contextKind: label == null ? null : 'album',
        contextRef: label == null ? null : 'ref-$label',
        contextLabel: label,
        now: at,
      );

  Future<String> uidAt(int savedAt) async =>
      (await f.db
              .customSelect(
                'SELECT uid FROM playlists WHERE saved_at = ?',
                variables: [Variable.withInt(savedAt)],
              )
              .getSingle())
          .read<String>('uid');

  test(
    'list: newest first, only queues, distinct count, missing count',
    () async {
      final a = (await f.track('a')).value;
      final b = (await f.track('b')).value;
      final c = (await f.track('c', status: TrackStatus.missing)).value;
      await f.repo.createPlaylist(name: 'Mine', tracks: [await f.track('x')]);
      await save([a, b, a], at: 10);
      await save([a, c, c, b], at: 20, label: 'Alb');

      final rows = await repo.watchSavedQueues().first;
      expect(rows.map((r) => r.summary.savedQueue!.savedAt), [20, 10]);
      expect(rows[0].summary.trackCount, 3);
      expect(rows[0].missingCount, 1);
      expect(rows[0].summary.savedQueue!.contextKind, 'album');
      expect(rows[0].summary.savedQueue!.contextLabel, 'Alb');
      expect(rows[1].summary.trackCount, 2);
      expect(rows[1].missingCount, 0);
      expect(rows[1].summary.savedQueue!.contextKind, isNull);
    },
  );

  test('queue rows never reach the playlist reads', () async {
    final a = await f.track('a');
    final b = await f.track('b');
    await save([a.value, b.value], at: 10);
    final uid = await uidAt(10);
    final s = await f.repo.watchSummaries().first;
    expect(s.playlists, isEmpty);
    expect(await f.repo.countExisting([a, b]), isEmpty);
    expect(await livePlaylistId(f.db, uid), isNull);
  });

  test('detail: only a saved queue, entries in played order', () async {
    final a = (await f.track('a')).value;
    final b = (await f.track('b')).value;
    await save([b, a, b], at: 10);
    final normal = await f.repo.createPlaylist(
      name: 'Mine',
      tracks: [await f.track('x')],
    );
    final d = await repo.watchSavedQueue(await uidAt(10)).first;
    expect(d!.entries.map((e) => e.info.id.value), [b, a, b]);
    expect(d.summary.savedQueue!.savedAt, 10);
    expect(await repo.watchSavedQueue(normal).first, isNull);
    expect(await repo.watchSavedQueue('nope').first, isNull);
    // Export reads a queue through the playlist store.
    expect((await f.repo.loadPlaylist(await uidAt(10)))!.entries, hasLength(3));
  });

  test('a watched queue sees a new saved_at after touch', () async {
    final a = (await f.track('a')).value;
    final b = (await f.track('b')).value;
    await save([a, b], at: 10);
    final uid = await uidAt(10);
    final seen = <int>[];
    final sub = repo
        .watchSavedQueue(uid)
        .listen((d) => seen.add(d!.summary.savedQueue!.savedAt));
    await pumpUntil(() => seen.isNotEmpty);
    clock = 50;
    expect(await repo.touch(uid), isTrue);
    await pumpUntil(() => seen.length >= 2);
    await sub.cancel();
    expect(seen, [10, 50]);
  });

  test(
    'delete removes a queue and its entries, never a normal playlist',
    () async {
      final a = (await f.track('a')).value;
      final b = (await f.track('b')).value;
      await save([a, b], at: 10);
      final normal = await f.repo.createPlaylist(
        name: 'Mine',
        tracks: [await f.track('x')],
      );
      expect(await repo.deleteSavedQueue(normal), isFalse);
      expect(await f.repo.loadPlaylist(normal), isNotNull);
      final uid = await uidAt(10);
      expect(await repo.deleteSavedQueue(uid), isTrue);
      expect(await repo.deleteSavedQueue(uid), isFalse);
      final left = await f.db
          .customSelect(
            'SELECT COUNT(*) AS c FROM playlist_entries WHERE playlist_id NOT IN (SELECT id FROM playlists)',
          )
          .getSingle();
      expect(left.read<int>('c'), 0);
      expect(await repo.watchSavedQueues().first, isEmpty);
    },
  );

  test('remove missing reads the statuses at call time', () async {
    final a = (await f.track('a')).value;
    final b = (await f.track('b', status: TrackStatus.missing)).value;
    final c = (await f.track('c')).value;
    await save([a, b, c, b], at: 10);
    final uid = await uidAt(10);
    expect((await repo.watchSavedQueues().first).single.missingCount, 1);
    // `c` goes missing after the list was read: it is removed too.
    await f.db.customStatement(
      "UPDATE tracks SET status = 'missing', missing_since = 5 WHERE id = ?",
      [c],
    );
    expect(await repo.removeMissingFromSavedQueue(uid), 3);
    final d = await repo.watchSavedQueue(uid).first;
    expect(d!.entries.map((e) => e.info.id.value), [a]);
    expect(d.summary.savedQueue!.savedAt, 10);
    expect(await repo.removeMissingFromSavedQueue(uid), 0);
  });

  test('hidden tracks count as missing and are removed', () async {
    final a = (await f.track('a')).value;
    final b = (await f.track('b')).value;
    await save([a, b, b], at: 10);
    final uid = await uidAt(10);
    await f.db.customStatement(
      "UPDATE tracks SET status = 'hidden' WHERE id = ?",
      [b],
    );
    expect((await repo.watchSavedQueues().first).single.missingCount, 1);
    expect(await repo.removeMissingFromSavedQueue(uid), 2);
    final d = await repo.watchSavedQueue(uid).first;
    expect(d!.entries.map((e) => e.info.id.value), [a]);
  });

  test('remove missing leaves a normal playlist alone', () async {
    final m = await f.track('m', status: TrackStatus.missing);
    final normal = await f.repo.createPlaylist(name: 'Mine', tracks: [m]);
    expect(await repo.removeMissingFromSavedQueue(normal), 0);
    expect((await f.repo.loadPlaylist(normal))!.entries, hasLength(1));
  });
}

/// Waits (real time, short) until [done].
Future<void> pumpUntil(bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}
