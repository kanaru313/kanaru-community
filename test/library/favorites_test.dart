import 'package:drift/drift.dart' show Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/state/favorites_providers.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import '../database/support/test_db.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer c;
  late int source;

  setUp(() async {
    db = openTestDb();
    // Registered first, so it runs after the container is disposed.
    addTearDown(db.close);
    source = await addSource(db);
    c = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(c.dispose);
  });

  Future<TrackId> track(String name) async =>
      TrackId(await addTrack(db, source, locator: '$name.flac', title: name));

  FavoritesController controller() => c.read(favoritesControllerProvider);

  Future<List<int>> entryTracks() async => [
    for (final r
        in await db
            .customSelect(
              'SELECT track_id FROM playlist_entries WHERE deleted_at IS NULL '
              'ORDER BY sort_key, uid',
            )
            .get())
      r.read<int>('track_id'),
  ];

  test('first favorite creates the Favorites playlist and entry', () async {
    final a = await track('a');
    await controller().setFavorite([a], true);
    final playlists = await db.select(db.playlists).get();
    expect(playlists.single.uid, favoritesPlaylistUid);
    expect(playlists.single.kind, PlaylistKind.favorites);
    final entry = await db.select(db.playlistEntries).getSingle();
    final uid = (await db.select(db.tracks).getSingle()).uid;
    expect(entry.uid, favoriteEntryUid(favoritesPlaylistUid, uid));
  });

  test('favorites are idempotent and keep their order at the end', () async {
    final a = await track('a'), b = await track('b'), d = await track('d');
    await controller().setFavorite([b, a], true);
    await controller().setFavorite([a, d], true);
    await controller().setFavorite([a], true);
    expect(await entryTracks(), [b.value, a.value, d.value]);
    expect(await db.select(db.playlistEntries).get(), hasLength(3));
  });

  test(
    'unfavorite hard-deletes and a later favorite goes to the end',
    () async {
      final a = await track('a'), b = await track('b');
      await controller().setFavorite([a, b], true);
      await controller().setFavorite([a], false);
      await controller().setFavorite([a], false); // already gone: no-op
      expect(await entryTracks(), [b.value]);
      await controller().toggle(a);
      expect(await entryTracks(), [b.value, a.value]);
      await controller().toggle(b);
      expect(await entryTracks(), [a.value]);
    },
  );

  test('an unknown track changes nothing', () async {
    final a = await track('a');
    await expectLater(
      controller().setFavorite([a, TrackId(9999)], true),
      throwsArgumentError,
    );
    expect(await db.select(db.playlists).get(), isEmpty);
    expect(await db.select(db.playlistEntries).get(), isEmpty);
    await controller().setFavorite(const [], true); // nothing to do
  });

  test('more tracks than one chunk go in one transaction', () async {
    await db.batch((b) {
      for (var i = 0; i < 1100; i++) {
        b.insert(
          db.tracks,
          TracksCompanion.insert(
            uid: 'trk-$i',
            sourceId: source,
            locator: 'f$i.mp3',
            relPath: 'f$i.mp3',
            title: 'T$i',
            addedAt: 1,
            updatedAt: 1,
          ),
        );
      }
    });
    final ids = [
      for (final r in await db.select(db.tracks).get()) TrackId(r.id),
    ];
    await controller().setFavorite(ids, true);
    expect((await entryTracks()), ids.map((i) => i.value).toList());
    await controller().setFavorite(ids, false);
    expect(await entryTracks(), isEmpty);
  });

  test('one set stream; toggling a track notifies only its tile', () async {
    final a = await track('a'), b = await track('b');
    final seenA = <bool>[], seenB = <bool>[];
    c.listen(
      isFavoriteProvider(a),
      (_, n) => seenA.add(n),
      fireImmediately: true,
    );
    c.listen(
      isFavoriteProvider(b),
      (_, n) => seenB.add(n),
      fireImmediately: true,
    );
    await pumpEventQueue();
    await controller().toggle(a);
    await pumpEventQueue();
    await controller().toggle(a);
    await pumpEventQueue();
    await controller().toggle(b);
    await pumpEventQueue();
    expect(seenA, [false, true, false]);
    expect(seenB, [false, true]);
    expect(c.read(favoriteTrackIdsProvider).value, {b});
  });

  test('tile providers are disposed after the last listener', () async {
    final a = await track('a');
    final sub = c.listen(isFavoriteProvider(a), (_, _) {});
    expect(c.read(isFavoriteProvider(a).exists), isTrue);
    sub.close();
    await pumpEventQueue();
    expect(c.read(isFavoriteProvider(a).exists), isFalse);
  });

  test('two un-awaited toggles end as add then remove', () async {
    final a = await track('a');
    final first = controller().toggle(a);
    final second = controller().toggle(a);
    await Future.wait([first, second]);
    expect(await entryTracks(), isEmpty);
  });

  test('a tombstoned Favorites playlist comes back empty', () async {
    final a = await track('a'), b = await track('b');
    await controller().setFavorite([a], true);
    await db.customUpdate(
      'UPDATE playlists SET deleted_at = 5 WHERE uid = ?',
      variables: [Variable.withString(favoritesPlaylistUid)],
      updates: {db.playlists},
    );
    // Tombstoned: nothing is a favorite, unfavorite does not touch it.
    c.listen(favoriteTrackIdsProvider, (_, _) {});
    expect(await c.read(favoriteTrackIdsProvider.future), isEmpty);
    await controller().setFavorite([a], false);
    await controller().setFavorite([b], true);
    expect(await entryTracks(), [b.value]);
    expect(await db.select(db.playlists).get(), hasLength(1));
  });
}
