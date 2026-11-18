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
