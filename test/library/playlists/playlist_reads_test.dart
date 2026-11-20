import 'package:drift/drift.dart' show TableUpdate;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/playlists/playlist_reads.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import '../../database/support/test_db.dart';
import 'support/playlist_fixtures.dart';

void main() {
  late PlaylistFixture f;
  setUp(() async => f = await PlaylistFixture.open());

  Future<TrackId> withAlbum(
    String name,
    String album,
    int ms, {
    String? cover,
  }) async {
    final id = await f.track(name);
    await f.db.customStatement(
      'UPDATE tracks SET duration_ms = ?, cover_key = ?, album = ?, '
      'album_title_key = ?, album_artist_key = ? WHERE id = ?',
      [ms, cover, album, album, 'artist', id.value],
    );
    return id;
  }

  test(
    'summaries: counts distinct songs, durations, covers, Favorites',
    () async {
      final a = await withAlbum('a', 'X', 1000, cover: 'ca');
      final b = await withAlbum('b', 'X', 2000, cover: 'cb');
      final c = await withAlbum('c', 'Y', 4000, cover: 'cc');
      final p = await f.repo.createPlaylist(name: 'P', tracks: [a, b, a, c]);
      await f.repo.addToPlaylists(tracks: [a], playlistUids: ['favorites']);
      final s = await f.repo.watchSummaries().first;
      final sp = s.playlists.single;
      expect(sp.uid, p);
      expect(sp.trackCount, 3);
      expect(sp.durationMs, 7000);
      expect(sp.autoCoverKeys, ['ca', 'cc']);
      expect(s.favorites.isFavorites, isTrue);
      expect(s.favorites.trackCount, 1);
    },
  );

  test(
    'Favorites cover keys: newest added first, distinct, capped at 4',
    () async {
      final t = [
        for (var i = 0; i < 6; i++)
          await withAlbum('t$i', 'Album${i == 5 ? 4 : i}', 1000, cover: 'c$i'),
      ];
      await f.repo.addToPlaylists(tracks: t, playlistUids: ['favorites']);
      // Stamp the add times: t0 oldest ... t5 newest; moving an entry in the
      // list (sort_key) must not change the order.
      for (var i = 0; i < 6; i++) {
        await f.db.customStatement(
          'UPDATE playlist_entries SET added_at = ? WHERE track_id = ?',
          [1000 + i, t[i].value],
        );
      }
      f.db.notifyUpdates({const TableUpdate('playlist_entries')});
      final s = await f.repo.watchSummaries().first;
      // t5 shares Album4 with t4: the newer cover (c5) wins, c4 is skipped.
      expect(s.favorites.autoCoverKeys, ['c5', 'c3', 'c2', 'c1']);
      final detail = await f.repo.loadPlaylist('favorites');
      expect(detail!.summary.autoCoverKeys, s.favorites.autoCoverKeys);
    },
  );

  Future<List<TrackId>> favoritesWithAddTimes(List<int> times) async {
    final t = [
      for (var i = 0; i < times.length; i++)
        await withAlbum('f$i', 'Alb$i', 1000, cover: 'c$i'),
    ];
    await f.repo.addToPlaylists(tracks: t, playlistUids: ['favorites']);
    for (var i = 0; i < t.length; i++) {
      await f.db.customStatement(
        'UPDATE playlist_entries SET added_at = ? WHERE track_id = ?',
        [times[i], t[i].value],
      );
    }
    return t;
  }

  test(
    'Favorites cover keys do not change when the list is reordered',
    () async {
      await favoritesWithAddTimes([10, 20, 30, 40, 50]);
      final before =
          (await f.repo.watchSummaries().first).favorites.autoCoverKeys;
      expect(before, ['c4', 'c3', 'c2', 'c1']);
      // Move the last entry of the list (the newest favourite) to the front.
      final live = await f.live('favorites');
      expect(
        await f.repo.moveEntry('favorites', live.last.uid, afterEntryUid: null),
        PlaylistMove.moved,
      );
      expect((await f.live('favorites')).first.uid, live.last.uid);
      final after =
          (await f.repo.watchSummaries().first).favorites.autoCoverKeys;
      expect(after, before);
      expect(
        (await f.repo.loadPlaylist('favorites'))!.summary.autoCoverKeys,
        before,
      );
    },
  );

  test('Favorites cover keys: equal add times keep list order', () async {
    await favoritesWithAddTimes([5, 5, 5, 5]);
    final s = await f.repo.watchSummaries().first;
    expect(s.favorites.autoCoverKeys, ['c0', 'c1', 'c2', 'c3']);
    expect(
      (await f.repo.loadPlaylist('favorites'))!.summary.autoCoverKeys,
      s.favorites.autoCoverKeys,
    );
  });

  test('Favorites summary stays fast with 10000 favourites', () async {
    await f.db.customStatement(
      "INSERT INTO playlists (uid, name, name_key, description, kind, "
      "created_at, updated_at) VALUES ('favorites', 'Favorites', 'favorites', "
      "'', 'favorites', 1, 1)",
    );
    final t = await withAlbum('seed', 'S', 1000, cover: 'cs');
    await f.db.customStatement(
      'INSERT INTO playlist_entries (uid, playlist_id, track_id, sort_key, '
      'added_at, updated_at) '
      'WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n '
      'WHERE i < 10000) '
      "SELECT 'e' || i, (SELECT id FROM playlists WHERE uid = 'favorites'), "
      "?, printf('%06d', i), i, i FROM n",
      [t.value],
    );
    final sw = Stopwatch()..start();
    final s = await f.repo.watchSummaries().first;
    sw.stop();
    expect(s.favorites.autoCoverKeys, ['cs']);
    expect(sw.elapsedMilliseconds, lessThan(2000));
  });

  test(
    'summaries: Favorites absent is an empty summary; moods excluded',
    () async {
      await addPlaylist(
        f.db,
        kind: PlaylistKind.mood,
        nameKey: 'calm',
        uid: 'm1',
      );
      final s = await f.repo.watchSummaries().first;
      expect(s.playlists, isEmpty);
      expect(s.favorites.trackCount, 0);
      expect(s.favorites.uid, 'favorites');
    },
  );

  test(
    'summaries drop removed entries and re-emit after the removal',
    () async {
      final a = await f.track('a');
      final p = await f.repo.createPlaylist(name: 'P', tracks: [a]);
      final seen = <PlaylistSummaries>[];
      final sub = f.repo.watchSummaries().listen(seen.add);
      addTearDown(sub.cancel);
      await pumpUntil(() => seen.isNotEmpty);
      await f.repo.removeEntries(p, [(await f.live(p)).single.uid]);
      await pumpUntil(() => seen.length == 2);
      expect(seen.last.playlists.single.trackCount, 0);
    },
  );

  test('a cover change on a playlist track re-emits the summary', () async {
    final a = await withAlbum('a', 'X', 1000, cover: 'old');
    await f.repo.createPlaylist(name: 'P', tracks: [a]);
    final seen = <PlaylistSummaries>[];
    final sub = f.repo.watchSummaries().listen(seen.add);
    addTearDown(sub.cancel);
    await pumpUntil(() => seen.length == 1);
    expect(seen.single.playlists.single.autoCoverKeys, ['old']);
    await f.db.customStatement(
      "UPDATE tracks SET cover_key = 'new' WHERE id = ?",
      [a.value],
    );
    f.db.notifyUpdates({const TableUpdate('tracks')});
    await pumpUntil(() => seen.length == 2);
    expect(seen.last.playlists.single.autoCoverKeys, ['new']);
  });

  test('a track write outside every playlist emits nothing new', () async {
    final a = await f.track('a');
    final other = await f.track('other');
    await f.repo.createPlaylist(name: 'P', tracks: [a]);
    final seen = <PlaylistSummaries>[];
    final sub = f.repo.watchSummaries().listen(seen.add);
    addTearDown(sub.cancel);
    await pumpUntil(() => seen.length == 1);
    await f.db.customStatement(
      "UPDATE tracks SET cover_key = 'x' WHERE id = ?",
      [other.value],
    );
    f.db.notifyUpdates({const TableUpdate('tracks')});
    // Wait past one refresh interval so a reload had the chance to emit.
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(seen, hasLength(1));
  });

  test('summary query walks the order index', () async {
    final plan = await f.db
        .customSelect('EXPLAIN QUERY PLAN $summarySql')
        .get();
    final text = plan.map((r) => r.read<String>('detail')).join('\n');
    expect(text, contains('playlist_entries_order'));
    expect(text, isNot(contains('SCAN e')));
    expect(text, isNot(contains('SCAN playlist_entries')));
  });

  test(
    'detail: unknown null, Favorites empty, entries in order with repeats',
    () async {
      expect(await f.repo.loadPlaylist('nope'), isNull);
      expect((await f.repo.loadPlaylist('favorites'))!.entries, isEmpty);
      final a = await f.track('a');
      final m = await f.track('m', status: TrackStatus.missing);
      final p = await f.repo.createPlaylist(name: 'P', tracks: [a, m, a]);
      final d = (await f.repo.loadPlaylist(p))!;
      expect(d.entries.map((e) => e.info.id), [a, m, a]);
      expect(d.unavailableCount, 1);
      expect(d.duplicateCount, 1);
      expect(d.summary.trackCount, 2);
      await f.repo.deletePlaylist(p);
      expect(await f.repo.loadPlaylist(p), isNull);
    },
  );

  test('countExisting counts distinct tracks per live playlist', () async {
    final t = await f.tracks(3);
    final p = await f.repo.createPlaylist(
      name: 'P',
      tracks: [t[0], t[0], t[1]],
    );
    final q = await f.repo.createPlaylist(name: 'Q', tracks: [t[2]]);
    await f.repo.addToPlaylists(tracks: [t[0]], playlistUids: ['favorites']);
    final r = await f.repo.countExisting([t[0], t[1]]);
    expect(r, {p: 2, 'favorites': 1});
    expect(r.containsKey(q), isFalse);
    expect(await f.repo.countExisting(const []), isEmpty);
    await f.repo.removeEntries(p, [for (final e in await f.live(p)) e.uid]);
    expect((await f.repo.countExisting([t[0]])).containsKey(p), isFalse);
  });

  test('a detail load and a removal never mix their moments', () async {
    final t = await f.tracks(620);
    final p = await f.repo.createPlaylist(name: 'P', tracks: t);
    f.clock = 20000;
    final all = [for (final x in await f.live(p)) x.uid];
    final load = f.repo.loadPlaylist(p);
    final removal = f.repo.removeEntries(p, all);
    final d = (await load)!;
    await removal;
    final before = d.summary.updatedAt == 10000 && d.entries.length == 620;
    final after = d.summary.updatedAt == 20000 && d.entries.isEmpty;
    expect(
      before || after,
      isTrue,
      reason: '${d.summary.updatedAt} ${d.entries.length}',
    );
  });

  test('a detail load during a move returns one whole order', () async {
    final t = await f.tracks(620);
    final p = await f.repo.createPlaylist(name: 'P', tracks: t);
    final e = [for (final x in await f.live(p)) x.uid];
    final oldOrder = [for (final x in t) x.value];
    final newOrder = [oldOrder.last, ...oldOrder.take(oldOrder.length - 1)];
    final load = f.repo.loadPlaylist(p);
    final move = f.repo.moveEntry(p, e.last, afterEntryUid: null);
    final d = (await load)!;
    await move;
    final got = [for (final x in d.entries) x.info.id.value];
    expect(got, anyOf(equals(oldOrder), equals(newOrder)));
    expect(await f.liveTracks(p), newOrder);
  });

  test('a play-count change re-emits the detail', () async {
    final a = await f.track('a');
    final p = await f.repo.createPlaylist(name: 'P', tracks: [a]);
    final seen = <PlaylistDetail?>[];
    final sub = f.repo.watchPlaylist(p).listen(seen.add);
    addTearDown(sub.cancel);
    await pumpUntil(() => seen.length == 1);
    expect(seen.single!.entries.single.info.playCount, 0);
    await addPlay(f.db, a.value, playedAt: 5);
    await pumpUntil(() => seen.length == 2);
    expect(seen.last!.entries.single.info.playCount, 1);
  });
}

Future<void> pumpUntil(bool Function() done) async {
  final end = DateTime.now().add(const Duration(seconds: 10));
  while (!done()) {
    if (DateTime.now().isAfter(end)) fail('condition not reached');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
