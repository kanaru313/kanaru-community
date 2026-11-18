import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter_test/flutter_test.dart';

import 'package:kanaru/src/library/data/favorites_repository.dart';

import '../../database/support/test_db.dart';

import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_text_rules.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import 'support/playlist_fixtures.dart';

void main() {
  late PlaylistFixture f;
  setUp(() async => f = await PlaylistFixture.open());

  group('createPlaylist', () {
    test('keeps order and repeats, accepts every track status', () async {
      final a = await f.track('a');
      final m = await f.track('m', status: TrackStatus.missing);
      final h = await f.track('h', status: TrackStatus.hidden);
      final uid = await f.repo.createPlaylist(
        name: '  Mix\u0000 ',
        description: 'd',
        tracks: [a, m, a, h],
      );
      expect(await f.liveTracks(uid), [a.value, m.value, a.value, h.value]);
      final row = await (f.db.select(
        f.db.playlists,
      )..where((p) => p.uid.equals(uid))).getSingle();
      expect(row.name, 'Mix');
      expect(row.kind, isNull);
      f.expectUniqueKeys(await f.allKeys(uid));
    });

    test(
      'invalid name, long description, unknown track write nothing',
      () async {
        await expectLater(
          f.repo.createPlaylist(name: '  '),
          throwsArgumentError,
        );
        await expectLater(
          f.repo.createPlaylist(name: 'x' * 201),
          throwsArgumentError,
        );
        await expectLater(
          f.repo.createPlaylist(name: 'x', description: 'd' * 2001),
          throwsArgumentError,
        );
        await expectLater(
          f.repo.createPlaylist(name: 'x', tracks: [const TrackId(999)]),
          throwsArgumentError,
        );
        expect(await f.db.select(f.db.playlists).get(), isEmpty);
      },
    );
  });

  group('updatePlaylist', () {
    test('saved, unchanged (no table update), gone', () async {
      final uid = await f.repo.createPlaylist(name: 'A', description: 'x');
      f.clock = 20000;
      expect(
        await f.repo.updatePlaylist(uid, name: ' B '),
        PlaylistUpdate.saved,
      );
      expect(await f.updatedAt(uid), 20000);
      f.clock = 30000;
      final updates = <Object>[];
      final sub = f.db
          .tableUpdates(TableUpdateQuery.onTable(f.db.playlists))
          .listen(updates.add);
      addTearDown(sub.cancel);
      expect(
        await f.repo.updatePlaylist(uid, name: 'B', description: 'x'),
        PlaylistUpdate.unchanged,
      );
      await pumpEventQueue();
      expect(updates, isEmpty);
      expect(await f.updatedAt(uid), 20000);
      expect(
        await f.repo.updatePlaylist('nope', name: 'Z'),
        PlaylistUpdate.gone,
      );
    });

    test('rejects bad text and renaming Favorites', () async {
      final uid = await f.repo.createPlaylist(name: 'A');
      await expectLater(
        f.repo.updatePlaylist(uid, name: ''),
        throwsArgumentError,
      );
      await expectLater(
        f.repo.updatePlaylist('favorites', name: 'F'),
        throwsArgumentError,
      );
    });
  });

  group('deletePlaylist', () {
    test('deletes playlist, entries and cover row; false when gone', () async {
      final a = await f.track('a');
      final uid = await f.repo.createPlaylist(name: 'A', tracks: [a]);
      await setCustomCover(f.db, 'playlist', uid, 'key1', now: 1);
      expect(await f.repo.deletePlaylist(uid), isTrue);
      expect(await f.db.select(f.db.playlistEntries).get(), isEmpty);
      expect(await customCoverKey(f.db, 'playlist', uid), isNull);
      expect(await f.repo.deletePlaylist(uid), isFalse);
    });

    test('Favorites cannot be deleted', () async {
      final a = await f.track('a');
      await f.repo.addToPlaylists(tracks: [a], playlistUids: ['favorites']);
      await expectLater(
        f.repo.deletePlaylist('favorites'),
        throwsArgumentError,
      );
      expect(await f.liveTracks('favorites'), [a.value]);
    });
  });

  group('duplicatePlaylist', () {
    Future<String> withCover() async {
      final t = await f.tracks(2);
      final uid = await f.repo.createPlaylist(
        name: 'Src',
        description: 'desc',
        tracks: [t[0], t[1], t[0]],
      );
      await setCustomCover(f.db, 'playlist', uid, 'cover-key', now: 1);
      return uid;
    }

    test('keeps order, repeats and description; no cover by default', () async {
      final src = await withCover();
      final copy = await f.repo.duplicatePlaylist(src, name: 'Copy');
      expect(await f.liveTracks(copy!), await f.liveTracks(src));
      expect((await f.repo.loadPlaylist(copy))!.summary.description, 'desc');
      expect(await customCoverKey(f.db, 'playlist', copy), isNull);
    });

    test('copyCover shares the key and survives deleting the source', () async {
      final src = await withCover();
      final copy = (await f.repo.duplicatePlaylist(
        src,
        name: 'Copy',
        copyCover: true,
      ))!;
      expect(await customCoverKey(f.db, 'playlist', copy), 'cover-key');
      await f.repo.deletePlaylist(src);
      expect(await customCoverKey(f.db, 'playlist', copy), 'cover-key');
      expect(await isCustomCoverKeyReferenced(f.db, 'cover-key'), isTrue);
    });

    test('copyCover without a source cover copies nothing', () async {
      final src = await f.repo.createPlaylist(name: 'S');
      final copy = (await f.repo.duplicatePlaylist(
        src,
        name: 'C',
        copyCover: true,
      ))!;
      expect(await customCoverKey(f.db, 'playlist', copy), isNull);
    });

    test('gone returns null and writes nothing; bad name throws', () async {
      expect(await f.repo.duplicatePlaylist('nope', name: 'C'), isNull);
      expect(await f.db.select(f.db.playlists).get(), isEmpty);
      final src = await f.repo.createPlaylist(name: 'S');
      await expectLater(
        f.repo.duplicatePlaylist(src, name: ' '),
        throwsArgumentError,
      );
    });

    test('long generated name is cut keeping the copy suffix', () async {
      final src = await f.repo.createPlaylist(name: 'n' * 195);
      final copy = (await f.repo.duplicatePlaylist(
        src,
        name: '${'n' * 195} (bản sao)',
      ))!;
      final name = (await f.repo.loadPlaylist(copy))!.summary.name;
      expect(graphemeLength(name), lessThanOrEqualTo(playlistNameMaxLength));
      expect(name, endsWith(' (bản sao)'));
    });

    test('Favorites duplicates into a normal playlist', () async {
      final a = await f.track('a');
      await f.repo.addToPlaylists(tracks: [a], playlistUids: ['favorites']);
      final copy = (await f.repo.duplicatePlaylist('favorites', name: 'F2'))!;
      final d = (await f.repo.loadPlaylist(copy))!;
      expect(d.summary.isFavorites, isFalse);
      expect(d.entries.map((e) => e.info.id), [a]);
    });
  });

  test('deleting a gone playlist sends no table update', () async {
    final seen = <Object>[];
    final sub = f.db
        .tableUpdates(TableUpdateQuery.onTable(f.db.playlists))
        .listen(seen.add);
    addTearDown(sub.cancel);
    expect(await f.repo.deletePlaylist('nope'), isFalse);
    await pumpEventQueue();
    expect(seen, isEmpty);
    final uid = await f.repo.createPlaylist(name: 'A');
    seen.clear();
    expect(await f.repo.deletePlaylist(uid), isTrue);
    await pumpEventQueue();
    expect(seen, isNotEmpty);
  });

  test('other playlist kinds are gone for every write', () async {
    final a = await f.track('a');
    await addPlaylist(
      f.db,
      kind: PlaylistKind.mood,
      nameKey: 'calm',
      uid: 'mood1',
    );
    await addPlaylist(f.db, kind: 'queue', uid: 'queue1');
    for (final uid in ['mood1', 'queue1']) {
      expect(await f.repo.updatePlaylist(uid, name: 'x'), PlaylistUpdate.gone);
      expect(await f.repo.deletePlaylist(uid), isFalse);
      expect(await f.repo.duplicatePlaylist(uid, name: 'c'), isNull);
      expect(await f.repo.removeEntries(uid, ['e']), isNull);
      expect(await f.repo.removeDuplicates(uid), isNull);
      expect(
        await f.repo.moveEntry(uid, 'e', afterEntryUid: null),
        PlaylistMove.gone,
      );
      final r = await f.repo.addToPlaylists(tracks: [a], playlistUids: [uid]);
      expect(r.goneUids, [uid]);
      expect((await f.repo.addAllToFavorites(uid)).goneUids, [uid]);
    }
    expect(await f.db.select(f.db.playlistEntries).get(), isEmpty);
  });

  test(
    'updated_at strictly increases across writes at a fixed clock',
    () async {
      final t = await f.tracks(2);
      final p = await f.repo.createPlaylist(name: 'P', tracks: [t[0]]);
      final seen = [await f.updatedAt(p)];
      await f.repo.addToPlaylists(tracks: [t[1]], playlistUids: [p]);
      seen.add(await f.updatedAt(p));
      await f.repo.updatePlaylist(p, name: 'Q');
      seen.add(await f.updatedAt(p));
      final e = (await f.live(p)).first.uid;
      await f.repo.removeEntries(p, [e]);
      seen.add(await f.updatedAt(p));
      f.clock = 5; // clock stepped back
      await f.repo.updatePlaylist(p, description: 'd');
      seen.add(await f.updatedAt(p));
      for (var i = 1; i < seen.length; i++) {
        expect(seen[i], greaterThan(seen[i - 1]), reason: '$seen');
      }
      await f.repo.addToPlaylists(tracks: [t[0]], playlistUids: ['favorites']);
      final fav = await f.updatedAt('favorites');
      await f.repo.addToPlaylists(tracks: [t[1]], playlistUids: ['favorites']);
      expect(await f.updatedAt('favorites'), greaterThan(fav));
      // Fixed clock far ahead of both: still strictly increasing.
      f.clock = 90000;
      final favSeen = <int>[];
      for (final track in [t[0], t[1]]) {
        await f.repo.removeEntries('favorites', [
          for (final e in await f.live('favorites'))
            if (e.track == track.value) e.uid,
        ]);
        await f.repo.addToPlaylists(
          tracks: [track],
          playlistUids: ['favorites'],
        );
        favSeen.add(await f.updatedAt('favorites'));
      }
      expect(favSeen[1], greaterThan(favSeen[0]));
      // Heart off through the favorites controller bumps it too.
      final before = await f.updatedAt('favorites');
      await FavoritesRepository(
        f.db,
        now: () => 90000,
      ).setFavorite([t[0]], false);
      expect(await f.updatedAt('favorites'), greaterThan(before));
    },
  );

  test('addAllToFavorites adds available tracks in playlist order', () async {
    final t = await f.tracks(3);
    final m = await f.track('m', status: TrackStatus.missing);
    final uid = await f.repo.createPlaylist(
      name: 'P',
      tracks: [t[2], m, t[0], t[2], t[1]],
    );
    final r = await f.repo.addAllToFavorites(uid);
    expect(r.addedTrackCount, 3);
    expect(await f.liveTracks('favorites'), [
      t[2].value,
      t[0].value,
      t[1].value,
    ]);
    expect((await f.repo.addAllToFavorites(uid)).skippedTrackCount, 3);
  });

  test('addAllToFavorites reports a gone source', () async {
    final r = await f.repo.addAllToFavorites('nope');
    expect(r.goneUids, ['nope']);
    expect(r.outcomes, isEmpty);
    expect(await f.db.select(f.db.playlists).get(), isEmpty);
  });
}
