import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';

import '../../database/support/test_db.dart';
import 'support/playlist_fixtures.dart';

void main() {
  late PlaylistFixture f;
  setUp(() async => f = await PlaylistFixture.open());

  Future<int> idOf(String uid) async =>
      (await f.db
              .customSelect(
                'SELECT id FROM playlists WHERE uid = ?',
                variables: [Variable.withString(uid)],
              )
              .getSingle())
          .read<int>('id');

  test('resolves a normal playlist', () async {
    final uid = await f.repo.createPlaylist(name: 'A');
    final id = await idOf(uid);
    expect(await f.repo.resolvePlaylistIds([id, 9999]), {id: uid});
    expect((await f.repo.loadPlaylist(uid))!.summary.id, id);
  });

  test('resolves Favorites before any favorite exists', () async {
    expect(await f.repo.resolvePlaylistIds([0]), {0: PlaylistUids.favorites});
    final writable = await f.repo.listWritable();
    expect(writable.single.id, favoritesPlaylistId);
    expect(writable.single.uid, PlaylistUids.favorites);
  });

  test(
    'Favorites row resolves only as 0, never under its database id',
    () async {
      final t = await f.track('a');
      await f.repo.addToPlaylists(
        tracks: [t],
        playlistUids: [PlaylistUids.favorites],
      );
      final rowId = await idOf(PlaylistUids.favorites);
      expect(rowId, isNot(0));
      expect(await f.repo.resolvePlaylistIds([rowId]), isEmpty);
      expect(await f.repo.resolvePlaylistIds([0, rowId]), {
        0: PlaylistUids.favorites,
      });
      final s = await f.repo.watchSummaries().first;
      expect(s.favorites.id, 0);
      expect((await f.repo.listWritable()).map((p) => p.id), [0]);
    },
  );

  test('listWritable lists Favorites then user playlists in order', () async {
    f.clock = 1;
    final a = await f.repo.createPlaylist(name: 'A');
    f.clock = 2;
    final b = await f.repo.createPlaylist(name: 'B');
    final list = await f.repo.listWritable();
    expect(list.map((p) => p.uid), [PlaylistUids.favorites, a, b]);
    expect(list.map((p) => p.name), ['Favorites', 'A', 'B']);
    expect(list[1].id, await idOf(a));
  });

  test('skips a saved queue', () async {
    final id = await addPlaylist(f.db, kind: PlaylistKind.queue, uid: 'q1');
    expect(await f.repo.resolvePlaylistIds([id]), isEmpty);
    expect((await f.repo.listWritable()).map((p) => p.uid), ['favorites']);
  });

  test('skips a mood playlist', () async {
    final id = await addPlaylist(
      f.db,
      kind: PlaylistKind.mood,
      nameKey: 'calm',
      uid: 'm1',
    );
    expect(await f.repo.resolvePlaylistIds([id]), isEmpty);
    expect((await f.repo.listWritable()).map((p) => p.uid), ['favorites']);
  });

  test('skips a deleted playlist', () async {
    final uid = await f.repo.createPlaylist(name: 'Gone');
    final id = await idOf(uid);
    await f.db.customStatement(
      'UPDATE playlists SET deleted_at = 5 WHERE id = ?',
      [id],
    );
    expect(await f.repo.resolvePlaylistIds([id]), isEmpty);
    expect((await f.repo.listWritable()).map((p) => p.uid), ['favorites']);
  });

  test('entry ids resolve inside their own playlist only', () async {
    final tracks = await f.tracks(2);
    final a = await f.repo.createPlaylist(name: 'A', tracks: tracks);
    final b = await f.repo.createPlaylist(name: 'B', tracks: tracks);
    final aEntries = (await f.repo.loadPlaylist(a))!.entries;
    final bEntries = (await f.repo.loadPlaylist(b))!.entries;
    final ids = [for (final e in aEntries) e.id];
    expect(await f.repo.resolveEntryIds(a, ids), {
      for (final e in aEntries) e.id: e.uid,
    });
    expect(await f.repo.resolveEntryIds(a, [bEntries.first.id]), isEmpty);
    expect(await f.repo.resolveEntryIds('nope', ids), isEmpty);
    expect(await f.repo.resolveEntryIds(a, []), isEmpty);
  });

  test('entry of a missing Favorites row is not resolved', () async {
    expect(await f.repo.resolveEntryIds(PlaylistUids.favorites, [1]), isEmpty);
  });

  test('tombstoned entry pending undo is not resolved', () async {
    final tracks = await f.tracks(2);
    final p = await f.repo.createPlaylist(name: 'P', tracks: tracks);
    final entries = (await f.repo.loadPlaylist(p))!.entries;
    final removal = (await f.repo.removeEntries(p, [entries[0].uid]))!;
    expect(await f.repo.resolveEntryIds(p, [entries[0].id, entries[1].id]), {
      entries[1].id: entries[1].uid,
    });
    await f.repo.undoRemoval(removal);
    expect(await f.repo.resolveEntryIds(p, [entries[0].id]), {
      entries[0].id: entries[0].uid,
    });
  });
}
