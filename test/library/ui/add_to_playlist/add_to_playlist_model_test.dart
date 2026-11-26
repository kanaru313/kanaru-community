import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/ui/add_to_playlist/add_to_playlist_model.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

PlaylistSummary _pl(String uid, {String? name, int updatedAt = 0}) =>
    PlaylistSummary(
      id: 0,
      uid: uid,
      name: name ?? uid,
      description: '',
      isFavorites: uid == PlaylistUids.favorites,
      trackCount: 0,
      durationMs: 0,
      createdAt: 0,
      updatedAt: updatedAt,
      autoCoverKeys: const [],
    );

PlaylistAddOutcome _o(
  String uid, {
  int added = 0,
  int skipped = 0,
  int moved = 0,
  bool created = false,
}) => PlaylistAddOutcome(
  uid: uid,
  created: created,
  added: added,
  skipped: skipped,
  movedToEnd: moved,
);

AddToPlaylistsResult _r(
  List<PlaylistAddOutcome> outcomes, {
  int songs = 0,
  int skipped = 0,
  List<String> gone = const [],
}) => AddToPlaylistsResult(
  outcomes: outcomes,
  goneUids: gone,
  addedTrackCount: songs,
  skippedTrackCount: skipped,
);

AddSummary _sum(
  AddToPlaylistsResult r, {
  int dropped = 0,
  Map<String, String> names = const {},
  List<String> newNames = const [],
}) => summarize(r, dropped: dropped, namesByUid: names, newNames: newNames);

void main() {
  final fav = _pl(PlaylistUids.favorites);

  group('buildPickerRows', () {
    final a = _pl('a', updatedAt: 10);
    final b = _pl('b', updatedAt: 30);
    final c = _pl('c', updatedAt: 20);

    test('Favorites is pinned and never in rows; rows newest first', () {
      final r = buildPickerRows(
        playlists: [a, b, c],
        favorites: fav,
        counts: const {'c': 2},
      );
      expect(r.pinned!.favorites, isTrue);
      expect(r.pinned!.summary.uid, PlaylistUids.favorites);
      expect([for (final x in r.rows) x.summary.uid], ['b', 'c', 'a']);
      expect(r.rows.every((x) => !x.favorites), isTrue);
      expect([for (final x in r.rows) x.has], [0, 2, 0]);
    });

    test('the source playlist is hidden', () {
      final r = buildPickerRows(
        playlists: [a, b],
        favorites: fav,
        counts: const {},
        excludeUid: 'b',
      );
      expect([for (final x in r.rows) x.summary.uid], ['a']);
      expect(r.pinned, isNotNull);
    });

    test('Favorites as the source: nothing pinned', () {
      final r = buildPickerRows(
        playlists: [a],
        favorites: fav,
        counts: const {},
        excludeUid: PlaylistUids.favorites,
      );
      expect(r.pinned, isNull);
      expect(r.rows, hasLength(1));
    });

    test('the filter shows above 10 playlists, not at 10', () {
      expect(showFilter(10), isFalse);
      expect(showFilter(11), isTrue);
      expect(showFilter(0), isFalse);
    });
  });

  group('rowHint', () {
    PlaylistRow row(int has) =>
        PlaylistRow(summary: fav, has: has, favorites: false);

    test('holds none: no hint', () {
      expect(rowHint(row(0), 3), isA<NoHint>());
    });
    test('one-song batch it holds: has this', () {
      expect(rowHint(row(1), 1), isA<HasThisHint>());
    });
    test('3 songs, holds 2: has some (2 of 3)', () {
      expect(rowHint(row(2), 3), const HasSomeHint(2, 3));
    });
  });

  group('distinctCount', () {
    test('queue repeats count once', () {
      expect(
        distinctCount(const [TrackId(1), TrackId(2), TrackId(1), TrackId(1)]),
        2,
      );
      expect(distinctCount(const []), 0);
    });
  });

  group('pending keys', () {
    test('round trip', () {
      expect(pendingKey(3), 'new:3');
      expect(isPendingKey(pendingKey(3)), isTrue);
      expect(isPendingKey('abc'), isFalse);
    });
  });

  group('liveTicked', () {
    test('Favorites in liveUids stays once', () {
      expect(liveTicked({PlaylistUids.favorites}, [PlaylistUids.favorites]), {
        PlaylistUids.favorites,
      });
    });

    test('drops pending keys and deleted playlists, keeps Favorites', () {
      expect(
        liveTicked(
          {'a', 'gone', pendingKey(1), PlaylistUids.favorites},
          ['a', 'b'],
        ),
        {'a', PlaylistUids.favorites},
      );
    });
  });

  group('affected', () {
    test('lists ticked playlists holding songs; Favorites never', () {
      final list = affected(
        {PlaylistUids.favorites, 'a', 'b', 'c'},
        {PlaylistUids.favorites: 5, 'a': 2, 'c': 1},
        {'a': 'A', 'b': 'B', 'c': 'C'},
      );
      expect([for (final x in list) x.uid], ['a', 'c']);
      expect(list.first.name, 'A');
      expect(heldTotal(list), 3);
    });
    test('an unticked playlist that holds songs is not affected', () {
      expect(affected({'b'}, {'a': 2}, {'a': 'A'}), isEmpty);
    });
    test('heldTotal of none is 0', () => expect(heldTotal(const []), 0));
  });

  group('buildPlan', () {
    test('null when nothing live and nothing pending is ticked', () {
      expect(
        buildPlan(selected: {'gone'}, liveUids: ['a'], pendingNames: const {}),
        isNull,
      );
    });

    test('live uids, typed-order pending names, default policy', () {
      final p = buildPlan(
        selected: {'a', pendingKey(2), pendingKey(1), 'gone'},
        liveUids: ['a'],
        pendingNames: {pendingKey(1): 'One', pendingKey(2): 'Two'},
      )!;
      expect(p.playlistUids, ['a']);
      expect(p.newNames, ['One', 'Two']);
      expect(p.policy, DuplicatePolicy.skipExisting);
    });

    test('an unticked pending name is left out; policy is the answer', () {
      final p = buildPlan(
        selected: {pendingKey(2)},
        liveUids: const [],
        pendingNames: {pendingKey(1): 'One', pendingKey(2): 'Two'},
        policy: DuplicatePolicy.moveToEnd,
      )!;
      expect(p.newNames, ['Two']);
      expect(p.playlistUids, isEmpty);
      expect(p.policy, DuplicatePolicy.moveToEnd);
    });

    test('pending names are cleaned', () {
      final p = buildPlan(
        selected: {pendingKey(1)},
        liveUids: const [],
        pendingNames: {pendingKey(1): '  Mix\u0007 '},
      )!;
      expect(p.newNames, ['Mix']);
    });

    test('Favorites ticked and live is listed once', () {
      final p = buildPlan(
        selected: {PlaylistUids.favorites},
        liveUids: [PlaylistUids.favorites, 'a'],
        pendingNames: const {},
      )!;
      expect(p.playlistUids, [PlaylistUids.favorites]);
    });

    test('Favorites alone is a plan', () {
      final p = buildPlan(
        selected: {PlaylistUids.favorites},
        liveUids: const [],
        pendingNames: const {},
      )!;
      expect(p.playlistUids, [PlaylistUids.favorites]);
    });
  });

  group('nextDefaultName', () {
    String numbered(int i) => 'Playlist mới $i';
    test('free: the base', () {
      expect(
        nextDefaultName('Playlist mới', numbered, ['Other']),
        'Playlist mới',
      );
    });
    test('taken: 2, then 3', () {
      expect(
        nextDefaultName('Playlist mới', numbered, ['Playlist mới']),
        'Playlist mới 2',
      );
      expect(
        nextDefaultName('Playlist mới', numbered, [
          'Playlist mới',
          'Playlist mới 2',
        ]),
        'Playlist mới 3',
      );
    });
    test('existing and pending names both count, cleaned and trimmed', () {
      expect(
        nextDefaultName('Playlist mới', numbered, [
          '  Playlist mới ',
          'Playlist mới\u0007 2',
        ]),
        'Playlist mới 3',
      );
    });
  });

  group('summarize', () {
    test('several targets: totals, created, skipped (distinct songs)', () {
      final s = _sum(
        _r(
          [
            _o('a', added: 2, skipped: 1),
            _o('b', added: 2),
            _o('n', added: 2, created: true),
          ],
          songs: 2,
          skipped: 1,
        ),
        names: {'a': 'A', 'b': 'B'},
        newNames: ['Fresh'],
      );
      expect(s.failed, isFalse);
      expect(s.songs, 2);
      expect(s.playlists, 3);
      expect(s.created, 1);
      expect(s.skipped, 1);
      expect(s.singleName, isNull);
      expect(s.nothingNew, isFalse);
    });

    test('3 songs into 2 playlists count 3 songs', () {
      final s = _sum(_r([_o('a', added: 3), _o('b', added: 3)], songs: 3));
      expect(s.songs, 3);
      expect(s.playlists, 2);
    });

    test('nothing added to several: nothing new', () {
      final s = _sum(
        _r([_o('a', skipped: 2), _o('b', skipped: 2)], skipped: 2),
      );
      expect(s.nothingNew, isTrue);
      expect(s.failed, isFalse);
      expect(s.playlists, 2);
    });

    test('one target left after a gone one: single wording, gone counted', () {
      final s = _sum(
        _r([_o('b', added: 2)], songs: 2, gone: ['a']),
        names: {'a': 'A', 'b': 'B'},
      );
      expect(s.singleName, 'B');
      expect(s.singleAdded, 2);
      expect(s.gone, 1);
    });

    test('gone with nothing added still names no gone playlist', () {
      final s = _sum(
        _r([_o('b', skipped: 2), _o('c', skipped: 2)], skipped: 2, gone: ['a']),
        names: {'b': 'B', 'c': 'C'},
      );
      expect(s.nothingNew, isTrue);
      expect(s.gone, 1);
      expect(s.singleName, isNull);
    });

    test('every target gone and nothing created: failed', () {
      final s = _sum(_r(const [], gone: ['a']));
      expect(s.failed, isTrue);
      expect(s.gone, 1);
      expect(s.nothingNew, isFalse);
    });

    test('a single new playlist uses its typed name', () {
      final s = _sum(
        _r([_o('n', added: 2, created: true)], songs: 2),
        newNames: ['Fresh'],
      );
      expect(s.singleName, 'Fresh');
      expect(s.created, 1);
    });

    test('single target keeps its own added and skipped', () {
      final s = _sum(
        _r([_o('a', added: 1, skipped: 2)], songs: 1, skipped: 2),
        names: {'a': 'A'},
      );
      expect(s.singleAdded, 1);
      expect(s.singleSkipped, 2);
      expect(s.nothingNew, isFalse);
    });

    test('an existing single target is never named by a new name', () {
      final s = _sum(
        _r([_o('a', added: 1)], songs: 1),
        names: {'a': 'A'},
        newNames: ['Fresh'],
      );
      expect(s.singleName, 'A');
    });

    test('moveToEnd over songs all present is not nothing new', () {
      final s = _sum(_r([_o('a', moved: 3)]), names: {'a': 'A'});
      expect(s.nothingNew, isFalse);
      expect(s.moved, 3);
    });

    test('moved songs count as added, one target', () {
      final s = _sum(_r([_o('a', moved: 3)]), names: {'a': 'A'});
      expect(s.singleAdded, 3);
      expect(s.songs, 3);
    });

    test('moved songs count as added, several targets', () {
      final s = _sum(
        _r([_o('a', moved: 3), _o('b', added: 1, moved: 2)], songs: 1),
      );
      expect(s.songs, 3);
    });

    test('moved sums entries removed; dropped is passed through', () {
      final s = _sum(
        _r([
          _o('a', added: 2, moved: 3),
          _o('b', added: 1, moved: 1),
        ], songs: 2),
        dropped: 4,
      );
      expect(s.moved, 4);
      expect(s.dropped, 4);
    });
  });
}
