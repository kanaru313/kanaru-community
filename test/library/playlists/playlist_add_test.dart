import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import 'support/playlist_fixtures.dart';

void main() {
  late PlaylistFixture f;
  late List<TrackId> t;
  setUp(() async {
    f = await PlaylistFixture.open();
    t = await f.tracks(4);
  });

  List<int> v(List<TrackId> ids) => [for (final i in ids) i.value];

  test(
    'no overlap: every track as given, policy ignored, repeats kept',
    () async {
      final p = await f.repo.createPlaylist(name: 'P', tracks: [t[3]]);
      for (final policy in DuplicatePolicy.values) {
        final q = await f.repo.createPlaylist(name: 'Q');
        final r = await f.repo.addToPlaylists(
          tracks: [t[0], t[1], t[0]],
          playlistUids: [q],
          policy: policy,
        );
        expect(await f.liveTracks(q), v([t[0], t[1], t[0]]));
        expect(r.outcomes.single.added, 2);
      }
      expect(await f.liveTracks(p), [t[3].value]);
    },
  );

  test(
    'skipExisting: dedupes batch, drops live tracks, keeps repeats',
    () async {
      final p = await f.repo.createPlaylist(name: 'P', tracks: [t[0], t[0]]);
      final r = await f.repo.addToPlaylists(
        tracks: [t[0], t[1], t[1]],
        playlistUids: [p],
      );
      expect(await f.liveTracks(p), v([t[0], t[0], t[1]]));
      expect(r.outcomes.single.skipped, 1);
      expect(r.skippedTrackCount, 1);
      expect(r.addedTrackCount, 1);
    },
  );

  test(
    'moveToEnd: moves live tracks to the end, appends batch as given',
    () async {
      final p = await f.repo.createPlaylist(
        name: 'P',
        tracks: [t[0], t[1], t[2]],
      );
      final r = await f.repo.addToPlaylists(
        tracks: [t[0], t[3], t[3]],
        playlistUids: [p],
        policy: DuplicatePolicy.moveToEnd,
      );
      expect(await f.liveTracks(p), v([t[1], t[2], t[0], t[3], t[3]]));
      expect(r.outcomes.single.movedToEnd, 1);
      expect(r.outcomes.single.added, 1);
    },
  );

  test('addAll appends the batch as given', () async {
    final p = await f.repo.createPlaylist(name: 'P', tracks: [t[0]]);
    await f.repo.addToPlaylists(
      tracks: [t[0], t[0]],
      playlistUids: [p],
      policy: DuplicatePolicy.addAll,
    );
    expect(await f.liveTracks(p), v([t[0], t[0], t[0]]));
  });

  test('new playlists get every track; counts are distinct tracks', () async {
    final a = await f.repo.createPlaylist(name: 'A', tracks: [t[0]]);
    final b = await f.repo.createPlaylist(name: 'B', tracks: [t[0]]);
    final r = await f.repo.addToPlaylists(
      tracks: [t[0], t[1], t[2]],
      playlistUids: [a, b],
      newPlaylistNames: [' New '],
    );
    expect(r.addedTrackCount, 3);
    expect(r.skippedTrackCount, 1);
    final created = r.outcomes.firstWhere((o) => o.created);
    expect(await f.liveTracks(created.uid), v([t[0], t[1], t[2]]));
    expect(r.outcomes, hasLength(3));
  });

  test('Favorites skips existing whatever the policy', () async {
    await f.repo.addToPlaylists(tracks: [t[0]], playlistUids: ['favorites']);
    final r = await f.repo.addToPlaylists(
      tracks: [t[0], t[1]],
      playlistUids: ['favorites'],
      policy: DuplicatePolicy.addAll,
    );
    expect(await f.liveTracks('favorites'), v([t[0], t[1]]));
    expect(r.outcomes.single.skipped, 1);
  });

  test('gone target is reported, the rest still written', () async {
    final p = await f.repo.createPlaylist(name: 'P');
    final r = await f.repo.addToPlaylists(
      tracks: [t[0]],
      playlistUids: ['ghost', p],
    );
    expect(r.goneUids, ['ghost']);
    expect(await f.liveTracks(p), [t[0].value]);
  });

  test('unknown id or bad new name writes nothing at all', () async {
    final p = await f.repo.createPlaylist(name: 'P');
    await expectLater(
      f.repo.addToPlaylists(
        tracks: [t[0], const TrackId(9999)],
        playlistUids: [p],
        newPlaylistNames: ['N'],
      ),
      throwsArgumentError,
    );
    await expectLater(
      f.repo.addToPlaylists(
        tracks: [t[0]],
        playlistUids: [p],
        newPlaylistNames: [' '],
      ),
      throwsArgumentError,
    );
    expect(await f.liveTracks(p), isEmpty);
    expect(await f.db.select(f.db.playlists).get(), hasLength(1));
  });

  test('missing and hidden tracks are accepted', () async {
    final m = await f.track('m', status: TrackStatus.missing);
    final h = await f.track('h', status: TrackStatus.hidden);
    final p = await f.repo.createPlaylist(name: 'P');
    await f.repo.addToPlaylists(tracks: [m, h], playlistUids: [p]);
    expect(await f.liveTracks(p), v([m, h]));
  });

  test('adding bumps updated_at only when something was written', () async {
    final p = await f.repo.createPlaylist(name: 'P', tracks: [t[0]]);
    f.clock = 50000;
    await f.repo.addToPlaylists(tracks: [t[0]], playlistUids: [p]);
    expect(await f.updatedAt(p), 10000);
    await f.repo.addToPlaylists(tracks: [t[1]], playlistUids: [p]);
    expect(await f.updatedAt(p), 50000);
  });

  test('50 000 ids go through one parameter', () async {
    final big = <TrackId>[];
    await f.db.batch((b) {
      for (var i = 0; i < 50000; i++) {
        b.insert(
          f.db.tracks,
          TracksCompanion.insert(
            uid: 'u$i',
            sourceId: f.source,
            locator: 'l$i',
            relPath: 'l$i',
            title: 't',
            addedAt: 1,
            updatedAt: 1,
          ),
        );
      }
    });
    final rows = await f.db.customSelect('SELECT id FROM tracks').get();
    for (final r in rows) {
      big.add(TrackId(r.read<int>('id')));
    }
    final p = await f.repo.createPlaylist(name: 'Big', tracks: big);
    expect((await f.liveTracks(p)).length, big.length);
    final r = await f.repo.addToPlaylists(
      tracks: big,
      playlistUids: [p],
      newPlaylistNames: ['Copy'],
    );
    expect(r.skippedTrackCount, big.length);
    expect((await f.repo.countExisting(big))[p], big.length);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('appends sort after tombstones', () async {
    final p = await f.repo.createPlaylist(name: 'P', tracks: [t[0], t[1]]);
    final e = await f.live(p);
    await f.repo.removeEntries(p, [e[1].uid]);
    await f.repo.addToPlaylists(tracks: [t[2]], playlistUids: [p]);
    f.expectUniqueKeys(await f.allKeys(p));
    final keys = await f.allKeys(p);
    expect(keys.toSet().length, 3);
  });
}
