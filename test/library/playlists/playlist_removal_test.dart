import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import 'support/playlist_fixtures.dart';

void main() {
  late PlaylistFixture f;
  late String p;
  late List<String> e;
  late List<int> t;

  setUp(() async {
    f = await PlaylistFixture.open();
    final tracks = await f.tracks(3);
    t = [for (final x in tracks) x.value];
    p = await f.repo.createPlaylist(name: 'P', tracks: tracks);
    e = [for (final x in await f.live(p)) x.uid];
  });

  test('remove then undo restores the entry in place', () async {
    f.clock = 20000;
    final r = (await f.repo.removeEntries(p, [e[1]]))!;
    expect(r.removedAt, 20000);
    expect(await f.liveTracks(p), [t[0], t[2]]);
    expect(await f.updatedAt(p), 20000);
    expect(await f.repo.undoRemoval(r), 1);
    expect(await f.liveTracks(p), t);
    expect(await f.repo.undoRemoval(r), 0, reason: 'double undo');
  });

  test('nothing live to remove returns null', () async {
    expect(await f.repo.removeEntries(p, ['x']), isNull);
    expect(await f.repo.removeEntries(p, []), isNull);
    expect(await f.repo.removeEntries('nope', [e[0]]), isNull);
    final r = (await f.repo.removeEntries(p, [e[0]]))!;
    expect(await f.repo.removeEntries(p, [e[0]]), isNull);
    expect(r.entryUids, [e[0]]);
  });

  test('remove last, add, undo, move between the two', () async {
    final r = (await f.repo.removeEntries(p, [e[2]]))!;
    final extra = await f.track('extra');
    await f.repo.addToPlaylists(tracks: [extra], playlistUids: [p]);
    await f.repo.undoRemoval(r);
    f.expectUniqueKeys(await f.allKeys(p));
    final live = await f.live(p);
    expect(live.map((x) => x.track), [t[0], t[1], t[2], extra.value]);
    expect(
      await f.repo.moveEntry(p, live[0].uid, afterEntryUid: live[2].uid),
      PlaylistMove.moved,
    );
    expect((await f.liveTracks(p)), [t[1], t[2], t[0], extra.value]);
    f.expectUniqueKeys(await f.allKeys(p));
  });

  test('remove middle, move another into the gap, undo', () async {
    final x = await f.track('x');
    await f.repo.addToPlaylists(tracks: [x], playlistUids: [p]);
    final all = [for (final r in await f.live(p)) r.uid];
    final r = (await f.repo.removeEntries(p, [all[1]]))!;
    await f.repo.moveEntry(p, all[3], afterEntryUid: all[0]);
    await f.repo.undoRemoval(r);
    f.expectUniqueKeys(await f.allKeys(p));
    expect(await f.liveTracks(p), [t[0], x.value, t[1], t[2]]);
  });

  test('undo after another removal only revives its own entries', () async {
    f.clock = 20000;
    final r1 = (await f.repo.removeEntries(p, [e[0]]))!;
    f.clock = 21000;
    final r2 = (await f.repo.removeEntries(p, [e[1]]))!;
    expect(await f.repo.undoRemoval(r1), 1);
    expect(await f.liveTracks(p), [t[0], t[2]]);
    expect(await f.repo.undoRemoval(r2), 1);
    expect(await f.liveTracks(p), t);
  });

  test('commit deletes the rows; undo afterwards revives nothing', () async {
    final r = (await f.repo.removeEntries(p, [e[0]]))!;
    await f.repo.commitRemoval(r);
    expect(await f.allKeys(p), hasLength(2));
    expect(await f.repo.undoRemoval(r), 0);
    final r2 = (await f.repo.removeEntries(p, [e[1]]))!;
    await f.repo.undoRemoval(r2);
    await f.repo.commitRemoval(r2);
    expect(await f.liveTracks(p), [t[1], t[2]]);
  });

  test(
    'Favorites: remove turns the heart off, re-favorite adds it again',
    () async {
      final a = await f.track('a');
      await f.repo.addToPlaylists(tracks: [a], playlistUids: ['favorites']);
      final entry = (await f.live('favorites')).single.uid;
      final r = (await f.repo.removeEntries('favorites', [entry]))!;
      expect(await f.liveTracks('favorites'), isEmpty);
      await f.repo.addToPlaylists(tracks: [a], playlistUids: ['favorites']);
      expect(await f.liveTracks('favorites'), [a.value]);
      expect(await f.repo.undoRemoval(r), 0);
      expect(await f.liveTracks('favorites'), [a.value]);
    },
  );

  test(
    'Favorites: remove last, favorite another, undo keeps keys unique',
    () async {
      final x = [
        for (final n in ['fa', 'fb', 'fc']) await f.track(n),
      ];
      await f.repo.addToPlaylists(
        tracks: [x[0], x[1]],
        playlistUids: ['favorites'],
      );
      final entries = await f.live('favorites');
      final r = (await f.repo.removeEntries('favorites', [entries[1].uid]))!;
      await f.repo.addToPlaylists(tracks: [x[2]], playlistUids: ['favorites']);
      await f.repo.undoRemoval(r);
      f.expectUniqueKeys(await f.allKeys('favorites'));
      expect(await f.liveTracks('favorites'), [
        x[0].value,
        x[1].value,
        x[2].value,
      ]);
    },
  );

  test(
    'remove first, move last to the start, undo keeps keys unique',
    () async {
      final r = (await f.repo.removeEntries(p, [e[0]]))!;
      expect(
        await f.repo.moveEntry(p, e[2], afterEntryUid: null),
        PlaylistMove.moved,
      );
      await f.repo.undoRemoval(r);
      f.expectUniqueKeys(await f.allKeys(p));
      expect(await f.liveTracks(p), [t[2], t[0], t[1]]);
    },
  );

  test('commit with nothing left sends no table update', () async {
    final r = (await f.repo.removeEntries(p, [e[0]]))!;
    await f.repo.undoRemoval(r);
    final seen = <Object>[];
    final sub = f.db
        .tableUpdates(TableUpdateQuery.onTable(f.db.playlistEntries))
        .listen(seen.add);
    addTearDown(sub.cancel);
    await f.repo.commitRemoval(r);
    await pumpEventQueue();
    expect(seen, isEmpty);
  });

  test('removeDuplicates keeps the first of each track', () async {
    final q = await f.repo.createPlaylist(
      name: 'Q',
      tracks: [
        for (final i in [0, 1, 0, 2, 1, 0]) TrackId(t[i]),
      ],
    );
    final before = await f.live(q);
    final r = (await f.repo.removeDuplicates(q))!;
    expect(r.entryUids, [before[2].uid, before[4].uid, before[5].uid]);
    expect(await f.liveTracks(q), [t[0], t[1], t[2]]);
    expect(await f.repo.removeDuplicates(q), isNull);
    expect(await f.repo.removeDuplicates('nope'), isNull);
    await f.repo.undoRemoval(r);
    expect((await f.liveTracks(q)).length, 6);
  });
}
